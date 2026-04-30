String buildAuthPasswordFromPin(String pin) {
  // Firebase email/password requires a stronger password than a 4-digit PIN.
  // We derive a compliant auth password while the user still enters only a PIN.
  return 'MaliUp#$pin@2026';
}
