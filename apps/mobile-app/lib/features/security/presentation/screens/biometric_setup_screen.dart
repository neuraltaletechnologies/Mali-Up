import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/localization_service.dart';
import '../../../../shared/widgets/skeleton_widgets.dart';
import '../../../../shared/widgets/smart_skeleton.dart';

/// Biometric App Lock Setup Screen
/// Allows fingerprint and face recognition unlock
/// Part of Phase 1 security implementation

String _t(String en, String sw) => LocalizationService.tr(en: en, sw: sw);

class BiometricSetupScreen extends ConsumerStatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  ConsumerState<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends ConsumerState<BiometricSetupScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool biometricAvailable = false;
  bool biometricEnabled = false;
  List<BiometricType> availableBiometrics = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final isDeviceSupported = await auth.canCheckBiometrics;
      final canUseDeviceCredential = await auth.isDeviceSupported();

      if (isDeviceSupported || canUseDeviceCredential) {
        final biometrics = await auth.getAvailableBiometrics();
        setState(() {
          biometricAvailable = true;
          availableBiometrics = biometrics;
        });
      }
    } catch (e) {
      print('Error checking biometric availability: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(title: Text(_t('App Security', 'Usalama wa Programu')));

    return Scaffold(
      appBar: appBar,
      body: SingleChildScrollView(
        child: SmartSkeleton(
          isLoading: isLoading,
          skeleton: const SkeletonBiometricContent(),
          child: isLoading
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('Biometric Lock', 'Kufuli ya Alama za Kibiolojia'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),

              if (!biometricAvailable)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    border: Border.all(color: Colors.orange[200]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange[700]),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _t('Biometric lock not available on this device',
                              'Kufuli ya alama za kibiolojia haipatikani kwenye kifaa hiki'),
                          style: GoogleFonts.dmSans(color: Colors.orange[900]),
                        ),
                      ),
                    ],
                  ),
                ),

              if (biometricAvailable) ...[
                Text(
                  '${_t("Available", "Inapatikana")}: ${_getBiometricName()}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(
                      '${_t("Enable", "Washa")} ${_getBiometricName()} ${_t("Lock", "Kufuli")}'),
                  subtitle: Text(_t('Unlock app with fingerprint or face',
                      'Fungua programu kwa alama ya kidole au uso')),
                  value: biometricEnabled,
                  onChanged: (val) => _setBiometric(val),
                ),
              ],

              const SizedBox(height: 32),

              Text(
                _t('PIN Lock', 'Kufuli ya PIN'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _t('Optional 4-6 digit PIN code',
                    'PIN ya tarakimu 4-6 (hiari)'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/security/pin-setup'),
                  icon: const Icon(Icons.vpn_key),
                  label: Text(_t('Set PIN Code', 'Weka Namba ya PIN')),
                ),
              ),

              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('App Security Features', 'Vipengele vya Usalama'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _t(
                        '✓ Biometric fingerprint or face unlock\n'
                        '✓ Optional PIN code lock\n'
                        '✓ Device-level encryption\n'
                        '✓ Secure credential storage\n'
                        '✓ Session timeout after inactivity',
                        '✓ Kufungua kwa alama ya kidole au uso\n'
                        '✓ Kufuli ya PIN (hiari)\n'
                        '✓ Usimbaji fiche kwenye kifaa\n'
                        '✓ Uhifadhi salama wa taarifa za kuingia\n'
                        '✓ Kufunga kikao baada ya muda wa ukimya',
                      ),
                      style: GoogleFonts.dmSans(height: 1.8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  String _getBiometricName() {
    if (availableBiometrics.contains(BiometricType.face)) {
      return _t('Face ID', 'Utambuzi wa Uso');
    } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return _t('Fingerprint', 'Alama ya Kidole');
    }
    return _t('Biometric', 'Alama za Kibiolojia');
  }

  Future<void> _setBiometric(bool enabled) async {
    try {
      // Verify with biometric
      final authenticated = await auth.authenticate(
        localizedReason: _t('Verify your identity to change security settings',
            'Thibitisha utambulisho wako ili kubadilisha mipangilio ya usalama'),
        options: const AuthenticationOptions(
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        // Save preference
        // await ref.read(securityProvider.notifier).enableBiometric(enabled);

        setState(() => biometricEnabled = enabled);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? '${_getBiometricName()} ${_t("lock enabled", "kufuli imewashwa")}'
                  : '${_getBiometricName()} ${_t("lock disabled", "kufuli imezimwa")}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_t("Error", "Hitilafu")}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

