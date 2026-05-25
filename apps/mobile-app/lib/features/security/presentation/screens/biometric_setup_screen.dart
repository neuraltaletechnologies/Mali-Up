import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../../core/theme/app_colors.dart';

/// Biometric App Lock Setup Screen
/// Allows fingerprint and face recognition unlock
/// Part of Phase 1 security implementation

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
      final canUseDeviceCredential = await auth.deviceSupportsBiometrics;

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
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Security Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('App Security'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Biometric Section
              Text(
                'Biometric Lock',
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Biometric lock not available on this device',
                          style: TextStyle(color: Colors.orange[900]),
                        ),
                      ),
                    ],
                  ),
                ),

              if (biometricAvailable) ...[
                Text(
                  'Available: ${_getBiometricName()}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Enable ${_getBiometricName()} Lock'),
                  subtitle: const Text('Unlock app with fingerprint or face'),
                  value: biometricEnabled,
                  onChanged: (val) => _setBiometric(val),
                ),
              ],

              const SizedBox(height: 32),

              // PIN Section
              Text(
                'PIN Lock',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Optional 4-6 digit PIN code',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/security/pin-setup'),
                  icon: const Icon(Icons.vpn_key),
                  label: const Text('Set PIN Code'),
                ),
              ),

              const SizedBox(height: 32),

              // Info
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
                      'App Security Features',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '✓ Biometric fingerprint or face unlock\n'
                      '✓ Optional PIN code lock\n'
                      '✓ Device-level encryption\n'
                      '✓ Secure credential storage\n'
                      '✓ Session timeout after inactivity',
                      style: TextStyle(height: 1.8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getBiometricName() {
    if (availableBiometrics.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    }
    return 'Biometric';
  }

  Future<void> _setBiometric(bool enabled) async {
    try {
      // Verify with biometric
      final authenticated = await auth.authenticate(
        localizedReason: 'Verify your identity to change security settings',
        options: const AuthenticationOptions(
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        // Save preference
        // await ref.read(securityProvider.notifier).enableBiometric(enabled);

        setState(() => biometricEnabled = enabled);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? '${_getBiometricName()} lock enabled'
                  : '${_getBiometricName()} lock disabled',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

