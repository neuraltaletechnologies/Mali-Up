import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {enforceRateLimit} from "./rate_limit";

interface RemoveTeamMemberData {
  businessId?: string;
  memberId?: string;
}

interface RemoveTeamMemberResponse {
  removed: boolean;
  /** True when the member had already activated a login. */
  hadAccount: boolean;
  /**
   * True when the member also owns their own business, so their Mali Up
   * account was kept and only the link to this business was severed.
   */
  accountKept: boolean;
}

/**
 * Removes a team member from a business — called by the business OWNER from
 * the Team screen.
 *
 * Unlike the plain Firestore batch it replaces, this also erases the member's
 * own login so a removed member cannot sign back in: re-entering their phone
 * number starts a brand-new signup.
 *
 * DELETED:
 *  - businesses/{businessId}/staff/{memberId}      (owner-controlled record)
 *  - businesses/{businessId}/staff/{workerUid}     (UID-keyed pointer doc)
 *  - the matching pendingInvites doc(s)
 *  - users/{workerUid} + workers/{workerUid} + their `users/{uid}/` Storage
 *  - the Firebase Auth user
 *  - businesses/{businessId}.staffCount is decremented
 *
 * KEPT (belongs to the business, for bookkeeping / legal retention):
 *  - every sale, invoice, expense, customer, debt and audit-log entry the
 *    member created. These live under businesses/{businessId}/… keyed by the
 *    business, not the user, so none of the deletes above reach them.
 *
 * If the member ALSO owns their own business, their account is left intact and
 * only the staff records + this business's link fields on users/{uid} are
 * removed (`accountKept: true`).
 *
 * Idempotent: safe to retry after a partial failure — missing docs are skipped.
 */
export const removeTeamMember = onCall<RemoveTeamMemberData>(
  {region: "us-central1", timeoutSeconds: 120},
  async (request): Promise<RemoveTeamMemberResponse> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const callerUid = request.auth.uid;

    const businessId = request.data?.businessId;
    const memberId = request.data?.memberId;
    if (!businessId || typeof businessId !== "string") {
      throw new HttpsError("invalid-argument", "businessId is required.");
    }
    if (!memberId || typeof memberId !== "string") {
      throw new HttpsError("invalid-argument", "memberId is required.");
    }

    // Deletion itself is idempotent, but each retry still walks several
    // collections and (in the worst case) an Auth delete.
    await enforceRateLimit({
      collection: "remove_team_member_rate_limits",
      key: callerUid,
      windowMs: 60 * 60 * 1000,
      max: 40,
    });

    const db = admin.firestore();
    const bizRef = db.collection("businesses").doc(businessId);
    const staffRef = bizRef.collection("staff");

    const bizSnap = await bizRef.get();
    if (!bizSnap.exists || bizSnap.data()?.ownerUid !== callerUid) {
      // Same message whether the business is missing or owned by someone
      // else — never confirm existence to a non-owner.
      throw new HttpsError(
        "permission-denied",
        "Only the business owner can remove a team member.",
      );
    }

    const memberSnap = await staffRef.doc(memberId).get();
    const workerUid =
      (memberSnap.data()?.workerUid as string | undefined)?.trim() || "";

    if (workerUid && workerUid === callerUid) {
      throw new HttpsError(
        "failed-precondition",
        "You cannot remove yourself from your own business.",
      );
    }

    // Does this person run their own business too? If so we must not delete
    // their Auth account or their whole users/{uid} doc — only sever the link.
    let ownsOtherBusiness = false;
    if (workerUid) {
      const owned = await db
        .collection("businesses")
        .where("ownerUid", "==", workerUid)
        .limit(1)
        .get();
      ownsOtherBusiness = !owned.empty;
    }

    // 1. Staff records + staffCount, atomically.
    const batch = db.batch();
    batch.delete(staffRef.doc(memberId));
    if (workerUid) batch.delete(staffRef.doc(workerUid));
    if (memberSnap.exists) {
      batch.set(
        bizRef,
        {staffCount: admin.firestore.FieldValue.increment(-1)},
        {merge: true},
      );
    }
    await batch.commit();

    // 2. Pending invite(s) for this member (normally exactly one). Queried by
    //    memberId alone — a single-field index — then ownership re-checked.
    const invites = await db
      .collection("pendingInvites")
      .where("memberId", "==", memberId)
      .get();
    await Promise.all(
      invites.docs
        .filter((d) => d.data()?.ownerUid === callerUid)
        .map((d) => d.ref.delete()),
    );

    // 3. The member's own login + personal data.
    if (workerUid && !ownsOtherBusiness) {
      await Promise.all([
        db.recursiveDelete(db.collection("users").doc(workerUid)),
        db.recursiveDelete(db.collection("workers").doc(workerUid)),
        admin
          .storage()
          .bucket()
          .deleteFiles({prefix: `users/${workerUid}/`})
          .catch((err) => {
            console.error("[removeTeamMember] storage cleanup", workerUid, err);
          }),
      ]);

      try {
        await admin.auth().deleteUser(workerUid);
      } catch (err: unknown) {
        const code = (err as {code?: string})?.code;
        if (code !== "auth/user-not-found") {
          console.error("[removeTeamMember] deleteUser failed", workerUid, err);
          throw new HttpsError(
            "internal",
            "The member's records were removed but their login could not be " +
              "fully deleted. Please try again.",
          );
        }
      }
    } else if (workerUid && ownsOtherBusiness) {
      // Keep the account; just detach it from this business so the app stops
      // resolving them into it on next launch.
      await db
        .collection("users")
        .doc(workerUid)
        .set(
          {
            isTeamMember: false,
            ownerUid: admin.firestore.FieldValue.delete(),
            businessId: admin.firestore.FieldValue.delete(),
            memberId: admin.firestore.FieldValue.delete(),
          },
          {merge: true},
        )
        .catch((err) => {
          console.error("[removeTeamMember] link severance", workerUid, err);
        });
    }

    return {
      removed: true,
      hadAccount: workerUid.length > 0,
      accountKept: workerUid.length > 0 && ownsOtherBusiness,
    };
  },
);
