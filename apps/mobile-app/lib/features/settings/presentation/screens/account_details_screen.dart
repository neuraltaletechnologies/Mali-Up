import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/localization_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_sheet.dart';
import '../../../../shared/widgets/mali_components.dart';
import '../../../auth/presentation/utils/pin_auth_password.dart';

/// Account Details — lets the signed-in user view and edit their personal
/// information (name, email) and authentication credential (login PIN).
///
/// Name/email are the source of truth in Firestore `users/{uid}` — the
/// Firebase Auth account itself uses a derived `phone@mali.up` email and a
/// PIN-derived password (see [buildAuthPasswordFromPin]), so a "real" email
/// update also nudges Firebase Auth via `verifyBeforeUpdateEmail` so password
/// reset links land in an inbox the user can access.
class AccountDetailsScreen extends ConsumerStatefulWidget {
  const AccountDetailsScreen({super.key});

  @override
  ConsumerState<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends ConsumerState<AccountDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String _phone = '';
  String _originalEmail = '';

  String _tr(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data();
      if (!mounted) return;
      setState(() {
        _firstNameCtrl.text = (data?['firstName'] as String?) ?? '';
        _lastNameCtrl.text = (data?['lastName'] as String?) ?? '';
        _originalEmail = (data?['email'] as String?) ?? '';
        _emailCtrl.text = _originalEmail;
        _phone = (data?['phone'] as String?) ?? FirebaseAuth.instance.currentUser?.phoneNumber ?? '';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnackBar(_tr('Could not load your details.', 'Imeshindikana kupakia maelezo yako.'));
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppColors.error : null,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final fullName = [firstName, lastName].where((s) => s.isNotEmpty).join(' ');

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'firstName': firstName,
        'lastName': lastName,
        'name': fullName,
        'email': email,
      });

      var emailNoticeSent = false;
      if (email.isNotEmpty && email != _originalEmail) {
        try {
          await FirebaseAuth.instance.currentUser?.verifyBeforeUpdateEmail(email);
          emailNoticeSent = true;
        } catch (_) {
          // Non-fatal — the Firestore email is already saved; Auth email sync
          // can retry later (e.g. re-authentication required).
        }
      }

      if (!mounted) return;
      setState(() {
        _originalEmail = email;
        _saving = false;
      });
      _showSnackBar(emailNoticeSent
          ? _tr(
              'Saved. Check your inbox to confirm the new email.',
              'Imehifadhiwa. Angalia barua pepe yako kuthibitisha anwani mpya.',
            )
          : _tr('Account details saved.', 'Maelezo ya akaunti yamehifadhiwa.'));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showSnackBar(
        _tr('Could not save your details. Try again.', 'Imeshindikana kuhifadhi maelezo. Jaribu tena.'),
        isError: true,
      );
    }
  }

  Future<void> _openChangePinSheet() async {
    await showAppSheet<void>(
      context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ChangePinSheet(tr: _tr, phone: _phone),
    );
  }

  InputDecoration _fieldDecoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.navyPrimary.withValues(alpha: 0.5), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          color: AppColors.navyPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _tr('Account Details', 'Maelezo ya Akaunti'),
          style: GoogleFonts.dmSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.navyPrimary,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.navyPrimary))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  Text(
                    _tr('Personal information', 'Taarifa Binafsi'),
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _firstNameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: _fieldDecoration(_tr('First name', 'Jina la Kwanza'), Icons.person_outline_rounded),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? _tr('First name is required', 'Jina linahitajika') : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _lastNameCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: _fieldDecoration(_tr('Last name', 'Jina la Mwisho'), Icons.person_outline_rounded),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    _tr('Authentication', 'Uthibitishaji'),
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _fieldDecoration(_tr('Email', 'Barua Pepe'), Icons.mail_outline_rounded),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return null;
                      final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
                      return valid ? null : _tr('Enter a valid email', 'Weka barua pepe sahihi');
                    },
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      _tr(
                        'Used for password reset and important notices.',
                        'Inatumika kwa kuweka upya nenosiri na taarifa muhimu.',
                      ),
                      style: GoogleFonts.dmSans(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.phone_outlined, size: 18, color: AppColors.textMuted),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _tr('Phone number', 'Namba ya Simu'),
                                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _phone.isEmpty ? '—' : _phone,
                                style: GoogleFonts.dmSans(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.textDisabled),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _openChangePinSheet,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.07),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.password_rounded, size: 18, color: AppColors.secondary),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _tr('Change login PIN', 'Badili PIN ya Kuingia'),
                                  style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14.5,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _tr('Your password to sign in to Mali Up', 'Nenosiri lako la kuingia Mali Up'),
                                  style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navyPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _tr('Save Changes', 'Hifadhi Mabadiliko'),
                              style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ── Change PIN bottom sheet ────────────────────────────────────────────────

class _ChangePinSheet extends StatefulWidget {
  final String Function(String en, String sw) tr;
  final String phone;
  const _ChangePinSheet({required this.tr, required this.phone});

  @override
  State<_ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends State<_ChangePinSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentPinCtrl = TextEditingController();
  final _newPinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();
  bool _submitting = false;
  String? _errorText;

  String _tr(String en, String sw) => widget.tr(en, sw);

  @override
  void dispose() {
    _currentPinCtrl.dispose();
    _newPinCtrl.dispose();
    _confirmPinCtrl.dispose();
    super.dispose();
  }

  InputDecoration _pinDecoration(String label) => InputDecoration(
        labelText: label,
        counterText: '',
        filled: true,
        fillColor: AppColors.surface,
        labelStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.navyPrimary.withValues(alpha: 0.5), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  Future<void> _submit() async {
    setState(() => _errorText = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final currentPin = _currentPinCtrl.text.trim();
    final newPin = _newPinCtrl.text.trim();
    final confirmPin = _confirmPinCtrl.text.trim();

    if (newPin != confirmPin) {
      setState(() => _errorText = _tr('New PINs do not match.', 'PIN mpya hazifanani.'));
      return;
    }
    if (newPin == currentPin) {
      setState(() => _errorText = _tr(
            'New PIN must be different from the current one.',
            'PIN mpya lazima iwe tofauti na ya sasa.',
          ));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      setState(() => _errorText = _tr('No signed-in account found.', 'Hakuna akaunti iliyoingia.'));
      return;
    }

    setState(() => _submitting = true);
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: buildAuthPasswordFromPin(phone: widget.phone, pin: currentPin),
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(
        buildAuthPasswordFromPin(phone: widget.phone, pin: newPin),
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_tr('Login PIN updated.', 'PIN ya kuingia imesasishwa.')),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } on FirebaseAuthException catch (e) {
      final message = (e.code == 'wrong-password' || e.code == 'invalid-credential')
          ? _tr('Current PIN is incorrect.', 'PIN ya sasa si sahihi.')
          : _tr('Could not update PIN. Try again.', 'Imeshindikana kusasisha PIN. Jaribu tena.');
      setState(() => _errorText = message);
    } catch (_) {
      setState(() => _errorText = _tr('Could not update PIN. Try again.', 'Imeshindikana kusasisha PIN. Jaribu tena.'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            const SizedBox(height: 12),
            Text(
              _tr('Change Login PIN', 'Badili PIN ya Kuingia'),
              style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.navyPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              _tr(
                'Enter your current PIN, then choose a new one.',
                'Weka PIN yako ya sasa, kisha chagua mpya.',
              ),
              style: GoogleFonts.dmSans(fontSize: 12.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _currentPinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _pinDecoration(_tr('Current PIN', 'PIN ya Sasa')),
              validator: (v) => (v == null || v.length < 4)
                  ? _tr('Enter your current PIN', 'Weka PIN yako ya sasa')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _newPinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _pinDecoration(_tr('New PIN (4–6 digits)', 'PIN Mpya (tarakimu 4–6)')),
              validator: (v) => (v == null || v.length < 4)
                  ? _tr('PIN must be at least 4 digits', 'PIN lazima iwe angalau tarakimu 4')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _pinDecoration(_tr('Confirm New PIN', 'Thibitisha PIN Mpya')),
              validator: (v) => (v == null || v.length < 4)
                  ? _tr('Confirm your new PIN', 'Thibitisha PIN yako mpya')
                  : null,
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorText!,
                style: GoogleFonts.dmSans(fontSize: 12.5, color: AppColors.error, fontWeight: FontWeight.w600),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        _tr('Update PIN', 'Sasisha PIN'),
                        style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
