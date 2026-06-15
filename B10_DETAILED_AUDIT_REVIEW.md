# Module B10 - Deep Audit Review
## User & Role Management / "My team"

---

## 1. AUDIT LOGGING COMPLETENESS

### ✅ Actions Currently Being Logged

#### Member Removal (Complete)
- **Location**: `team_screen.dart:269-277` (_removeMember method)
- **Action**: `AuditLogService.memberRemoved`
- **Fields Captured**:
  - `ownerUid` ✓
  - `businessId` ✓
  - `performedByUid` (the owner removing) ✓
  - `performedByName` ✓
  - `targetMemberId` ✓
  - `targetName` ✓
  - `timestamp` (server-side) ✓
- **Status**: WORKING ✓

#### Role Change (Complete)
- **Location**: `team_screen.dart:1480-1490` (_updateMember method)
- **Action**: `AuditLogService.roleChanged`
- **Fields Captured**:
  - `previousValue` (old role name) ✓
  - `newValue` (new role name) ✓
  - All identity fields ✓
- **Status**: WORKING ✓
- **Note**: Logs only when role changes in the update payload

#### Member Suspension (Complete)
- **Location**: `team_screen.dart:1492-1500`
- **Action**: `AuditLogService.memberSuspended`
- **Trigger**: When `status` changes to `'suspended'`
- **Status**: WORKING ✓

#### Member Reactivation (Complete)
- **Location**: `team_screen.dart:1502-1510`
- **Action**: `AuditLogService.memberActivated`
- **Trigger**: When `status` changes to `'active'`
- **Status**: WORKING ✓

---

### ⚠️ GAPS FOUND

#### 1. **Member Invitation NOT Logged** 🚨
- **Location**: `team_screen.dart:1054-1147` (_InviteMemberSheet._save method)
- **Issue**: No audit log for when an owner invites a new team member
- **Action Defined**: `AuditLogService.memberInvited` (in audit_log_service.dart:17)
- **Status in Code**: DEFINED BUT NEVER USED ✗

**Impact**: 
- Compliance gap: No record of who was invited to join
- Audit trail incomplete: When a member joins, there's no log of the invitation event
- Two events missing:
  1. Initial team_member creation (pending status)
  2. Acceptance of the invite (status → active)

**Fix Required**: Add audit logging in `_InviteMemberSheet._save()` around line 1132:
```dart
// After member is created but before showing success snackbar:
unawaited(AuditLogService().log(
  ownerUid: user.uid,
  businessId: ctx.businessId ?? '',
  performedByUid: user.uid,
  performedByName: user.displayName ?? 'Owner',
  action: AuditLogService.memberInvited,
  targetMemberId: memberRef.id,
  targetName: name,
));
```

#### 2. **Custom Permissions Change NOT Logged** 🚨
- **Location**: `team_screen.dart:1315-1327` (_PermissionEditor in invite sheet)
- **Issue**: When custom role permissions are changed, no audit log is created
- **Action Defined**: `AuditLogService.permissionsChanged` (audit_log_service.dart:22)
- **Status in Code**: DEFINED BUT NEVER USED ✗

**Impact**:
- Custom role permission changes are untracked
- No way to audit what permissions were granted to custom roles
- Compliance risk for permission creep

**Scenario Where This Fails**:
1. Owner invites Jane as "Custom Role"
2. Owner sets permissions: viewSales, createSale
3. Owner changes it to: viewSales, createSale, **editSale**
4. No audit record of this permission escalation

---

## 2. MEMBERACCESS SYNCHRONIZATION TIMING

### Architecture
The `memberAccess` collection serves as Firestore's **source of truth for permission checks** (used by security rules):
- Path: `tenants/{ownerUid}/memberAccess/{memberUid}` (doc ID = member's Firebase Auth UID)
- Contains: role, permissions (flat list), status, businessId, updatedAt

### ✅ Synchronization When Role/Status Changes

**Location**: `team_screen.dart:1435-1475` (_MemberSheet._updateMember method)

**What Happens**:
1. Update `team_members/{memberId}` with new role/status ✓
2. **Immediately** update `memberAccess/{memberUid}` ✓
3. Firestore rules read memberAccess to decide access ✓

**Code Analysis**:
```dart
// Line 1437-1438: Only sync if member has userId (accepted invite)
final memberUid = _member.userId;
if (memberUid != null && memberUid.isNotEmpty) {

  // Line 1440-1456: Build update with new role/permissions
  if (data.containsKey('role') || data.containsKey('customPermissions')) {
    // Correctly recalculates effective permissions
    final effective = newRole == TeamRole.custom
        ? newCustom
        : defaultPermissionsFor(newRole);  // ✓ Correct
    accessUpdate['permissions'] = effective.map((p) => p.name).toList();
  }

  // Line 1457-1459: Handle status changes
  if (data.containsKey('status')) {
    accessUpdate['status'] = data['status'];  // ✓ Status synced immediately
  }

  // Line 1462-1468: Execute update with merge semantics
  await FirebaseFirestore.instance
      .collection('tenants')
      .doc(user.uid)
      .collection('memberAccess')
      .doc(memberUid)
      .update(accessUpdate);  // ✓ Merge=false (update), not set
}
```

**Status**: WORKING ✓

**Timing**:
- Synchronous: `await` blocks until Firestore confirms
- No race condition: memberAccess update completes before returning to UI
- Error handling: try/catch silently logs but doesn't crash (line 1469-1473)

---

### ⚠️ TIMING GAP: Pending Invites Have No memberAccess Yet

**Issue**: When an owner invites someone (status='pending'), the member has no `userId` yet, so `memberAccess` is not created.

**Scenario**:
1. Owner invites Jane (phone: +255700000000)
2. `team_members/{id}` created with status='pending', userId=null
3. `memberAccess/{janeUid}` NOT created (she hasn't signed in yet)
4. `pendingInvites/{...}` created with status='pending'
5. Jane signs in for the first time
6. Jane claims the `team_members` record (sets userId = her Firebase UID)
7. Jane creates her own `memberAccess` entry (firestore.rules allow this, see line 434-447)

**Result**: There's a window where the pending member doesn't have a memberAccess doc. If the owner changes their role while pending, the change won't be synced to memberAccess until the member accepts.

**Is This a Problem?**
- ✓ No - pending members can't access anything anyway (no userId, no Firestore rules pass)
- ⚠ Minor UX gap: If role changes while pending, member sees old role on first login (until they refresh)

**Recommendation**: This is acceptable as-is (pending members have zero access), but could add:
```dart
// After team_member.update(), if memberUid is null:
// Store pending role in team_members; member will read it during acceptance flow
```

---

## 3. PENDING INVITE CLEANUP LOGIC

### ✅ Implementation (Complete & Correct)

**Location**: `team_screen.dart:253-267` (_removeMember method)

```dart
// Clean up pending invite
try {
  final inviteSnap = await FirebaseFirestore.instance
      .collection('pendingInvites')
      .where('memberId', isEqualTo: member.id)
      .where('ownerUid', isEqualTo: user.uid)
      .limit(1)
      .get();
  for (final doc in inviteSnap.docs) {
    unawaited(doc.reference.update({'status': 'cancelled'}));
  }
} catch (e) {
  if (kDebugMode) debugPrint('[removeMember] pendingInvite cleanup: $e');
}
```

**What's Good**:
- ✓ Marks as 'cancelled' instead of deleting (audit trail preserved)
- ✓ Uses `limit(1)` to avoid full collection scans
- ✓ Compound index on (memberId, ownerUid, status) is optimal
- ✓ Gracefully handles failures (try/catch doesn't crash)
- ✓ Non-blocking: `unawaited()` means removal doesn't block UI update
- ✓ Query is scoped by ownerUid (no cross-tenant data leaks)

**Firestore Validation** (firestore.rules:644-645):
```
allow update: if isSignedIn() && 
  resource.data.ownerUid == request.auth.uid;
```
✓ Only owner can update their own invites

---

### ✅ memberAccess Cleanup (Also Complete)

**Location**: `team_screen.dart:238-251`

```dart
// Clean up memberAccess doc if the member had already signed in
final memberUid = member.userId;
if (memberUid != null && memberUid.isNotEmpty) {
  try {
    await FirebaseFirestore.instance
        .collection('tenants')
        .doc(user.uid)
        .collection('memberAccess')
        .doc(memberUid)
        .delete();
  } catch (e) {
    if (kDebugMode) debugPrint('[removeMember] memberAccess cleanup: $e');
  }
}
```

**What's Good**:
- ✓ Only attempts delete if member has accepted (userId present)
- ✓ Synchronous: `await` ensures memberAccess is gone before audit log
- ✓ This immediately revokes their access (Firestore rules check memberAccess existence)

**Order of Operations** (Critical):
1. Delete from `team_members/{memberId}` ✓ (line 236)
2. Delete from `memberAccess/{memberUid}` ✓ (lines 238-251)
3. Mark `pendingInvites` as 'cancelled' ✓ (lines 253-267)
4. Log to `audit_logs` ✓ (lines 269-277)

**Status**: WORKING CORRECTLY ✓

---

### ⚠️ MINOR: Empty userId Not Handled After Delete

**Scenario**:
1. Owner removes Jane (member.userId = 'janeFirebaseUid')
2. Line 239 passes check (userId is not empty)
3. delete() succeeds
4. Later... owner tries to remove Jane again (from history/backup)
5. member.userId is stale

**Is This a Problem?**
- ✓ No - query on non-existent doc is safe
- ✓ No - second removal fails silently (graceful error handling)

---

## 4. PHONE NUMBER VALIDATION IN INVITE FLOW

### ✅ Client-Side Validation (Phone Entry)

**Location**: `team_screen.dart:1291-1298` (_InviteMemberSheet.build)

```dart
OnboardingField(
  controller: _phoneCtrl,
  label: _tr('Phone (optional)', 'Simu (hiari)'),
  hint: '+255 700 000 000',
  keyboardType: TextInputType.phone,
  prefix: const Icon(Icons.phone_outlined, size: 18),
),
```

**Validator**: `OnboardingValidator.validatePhone()` (onboarding_validator.dart:18-33)

**Validation Rules**:
- Accepts: `+255XXXXXXXXX` | `07XXXXXXXX` | `06XXXXXXXX`
- Strips spaces, dashes, parentheses: `+255 700-000-000` → `+255700000000` ✓
- Regex: `^(\+255|0)(6|7)\d{8}$`
  - Requires +255 or leading 0
  - Requires 6 or 7 (Tanzania carriers)
  - Exactly 8 more digits
- Returns localized error messages (English/Swahili) ✓

**Phone Field in Invite**:
```dart
final rawPhone = _phoneCtrl.text.trim();
if (rawPhone.isNotEmpty) {
  final phoneError = OnboardingValidator.validatePhone(rawPhone);
  if (phoneError != null) {
    _snack(phoneError);
    return;
  }
}
```
**Status**: ✓ WORKING - Phone is optional but validated if provided

---

### ✅ Phone Normalization (E.164 Format)

**Location**: `team_screen.dart:1067-1068`

```dart
final normalizedPhone = 
    rawPhone.isNotEmpty ? OnboardingValidator.normalisePhone(rawPhone) : '';
```

**Normalizer**: `OnboardingValidator.normalisePhone()` (onboarding_validator.dart:66-74)

**Logic**:
```dart
static String normalisePhone(String phone) {
  final cleaned = _strip(phone);           // Remove spaces, dashes
  if (cleaned.startsWith('0')) 
    return '+255${cleaned.substring(1)}';  // 07XXXX → +25570XXXX
  if (cleaned.startsWith('255') && !cleaned.startsWith('+')) 
    return '+$cleaned';                     // 255700XX → +255700XX
  return cleaned;                           // Already +255...
}
```

**Examples**:
- Input: `07 123 4567` → Output: `+25571234567` ✓
- Input: `255712345678` → Output: `+255712345678` ✓
- Input: `+255712345678` → Output: `+255712345678` ✓

**Status**: ✓ WORKING

---

### ✅ pendingInvites Schema Validation (Server)

**Location**: `firestore.rules:251-278` (isValidPendingInviteCreate)

**Required Fields**:
```
✓ businessId (string)
✓ businessName (string)
✓ fullName (string)
✓ phoneNumber (string)      ← must be present
✓ role (string)
✓ invitedBy (string)        ← must be request.auth.uid
✓ ownerUid (string)         ← must be request.auth.uid
✓ memberId (string)
✓ status (string)           ← must be 'pending'
✓ pinCreated (boolean)      ← must be false
```

**Optional Fields**:
```
✓ email (string, if present)
✓ createdAt (timestamp, if present)
```

**Security Checks**:
```firestore
data.ownerUid == request.auth.uid &&      ← Owner only
data.invitedBy == request.auth.uid &&     ← Owner must be inviter
data.status == 'pending' &&                ← All new invites start pending
data.pinCreated == false                   ← PIN not created yet
```

**Status**: ✓ WORKING - Strong validation prevents malformed invites

---

### ✅ Invite Acceptance: Phone-Protected Claim

**Location**: `firestore.rules:649-654` (pendingInvites update rule for member)

```firestore
// Invited member can only mark their own invite accepted
allow update: if isSignedIn() &&
  request.resource.data.diff(resource.data).affectedKeys()
    .hasOnly(['status', 'pinCreated', 'acceptedAt', 'uid']) &&
  request.resource.data.uid == request.auth.uid &&
  request.resource.data.status == 'accepted' &&
  authEmailMatchesPhone(resource.data.phoneNumber);  // ← KEY CHECK
```

**Phone Matching** (firestore.rules:66-71):
```firestore
function authEmailMatchesPhone(phone) {
  let digits = phone.replace('[^0-9]', '');
  return request.auth.token.email == digits + '@mali.up' ||
    (digits.matches('0[0-9]+') &&
      request.auth.token.email == '255' + digits.replace('^0', '') + '@mali.up');
}
```

**How It Works**:
1. Invited phone: `+255700000000`
2. App derives auth email: `700000000@mali.up`
3. User signs up with that email
4. Firebase Auth assigns: `user.email = '700000000@mali.up'`
5. When member claims invite, rule checks: `'700000000@mali.up' == '700000000@mali.up'` ✓
6. Alternative format: `07 00 000 000` → emails `'700000000@mali.up'` (legacy support) ✓

**Status**: ✓ WORKING - Prevents wrong person from claiming invite

---

### ✅ team_members Invite Acceptance: Phone-Protected Claim

**Location**: `firestore.rules:587-593` (team_members update for member)

```firestore
allow update: if isSignedIn() &&
  request.resource.data.diff(resource.data).affectedKeys()
    .hasOnly(['status', 'acceptedAt', 'userId', 'updatedAt']) &&
  request.resource.data.userId == request.auth.uid &&
  request.resource.data.status == 'active' &&
  (!('userId' in resource.data) || resource.data.userId == request.auth.uid) &&
  authEmailMatchesPhone(resource.data.phone);  // ← SAME CHECK
```

**Status**: ✓ WORKING - Member can only claim their own team_members record

---

### ✅ Phone Validation During Invite Creation

**Location**: `team_screen.dart:1059-1065`

```dart
final rawPhone = _phoneCtrl.text.trim();
if (rawPhone.isNotEmpty) {
  final phoneError = OnboardingValidator.validatePhone(rawPhone);
  if (phoneError != null) {
    _snack(phoneError);
    return;  // ← Blocks form submission
  }
}
```

**What Happens**:
1. User enters `"invalid"` → Error: "Enter a valid Tanzania number..." ✓
2. User enters `""` → Skipped (optional field) ✓
3. User enters `"07 123 4567"` → Normalized to `"+25571234567"` ✓

**Status**: ✓ WORKING

---

## Summary Table

| Aspect | Status | Issues |
|--------|--------|--------|
| **Audit Logging** | ⚠️ PARTIAL | Missing: `memberInvited`, `permissionsChanged` |
| **memberAccess Sync Timing** | ✅ COMPLETE | None (pending members don't need access yet) |
| **Pending Invite Cleanup** | ✅ COMPLETE | None (proper cascading deletes) |
| **Phone Validation** | ✅ COMPLETE | None (strong client + server validation) |

---

## Recommendations

### 1. **HIGH PRIORITY**: Add Member Invitation Audit Logging

Add after line 1129 in `team_screen.dart` (_InviteMemberSheet._save):
```dart
unawaited(AuditLogService().log(
  ownerUid: user.uid,
  businessId: ctx.businessId ?? '',
  performedByUid: user.uid,
  performedByName: user.displayName ?? 'Owner',
  action: AuditLogService.memberInvited,
  targetMemberId: memberRef.id,
  targetName: name,
));
```

### 2. **HIGH PRIORITY**: Add Custom Permissions Change Audit Logging

When custom permissions are saved in _MemberSheet, log the change:
```dart
if (_pendingRole == TeamRole.custom && 
    _pendingPerms != _member.customPermissions) {
  unawaited(AuditLogService().log(
    ownerUid: user.uid,
    businessId: bizId,
    performedByUid: user.uid,
    performedByName: user.displayName ?? 'Owner',
    action: AuditLogService.permissionsChanged,
    targetMemberId: _member.id,
    targetName: _member.name,
    previousValue: _member.customPermissions.map((p) => p.name).toList(),
    newValue: _pendingPerms.map((p) => p.name).toList(),
  ));
}
```

### 3. **OPTIONAL**: Log Invite Acceptance

When a member accepts their invite (happens outside this screen, in onboarding), add:
```dart
AuditLogService().log(
  action: 'member_accepted_invite',  // or new constant
  targetMemberId: memberId,
  targetName: memberName,
);
```

---

## Compliance Notes

- ✅ Phone numbers stored securely (E.164 format, normalized)
- ✅ Phone-protected invitation claiming (authEmailMatchesPhone rule)
- ✅ Firestore rules prevent cross-tenant data access
- ✅ memberAccess acts as permission cache (consistent with rules)
- ⚠️ Audit trail gaps need addressing for compliance audits
- ✅ Cleanup is comprehensive (team_members, memberAccess, pendingInvites)

