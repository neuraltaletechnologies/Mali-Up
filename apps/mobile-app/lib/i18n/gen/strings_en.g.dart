///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	dynamic operator[](String key) => _meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$app$en app = Translations$app$en.internal(_root);
	late final Translations$pinResetCode$en pinResetCode = Translations$pinResetCode$en.internal(_root);
	late final Translations$trial$en trial = Translations$trial$en.internal(_root);
	late final Translations$receiptPrinter$en receiptPrinter = Translations$receiptPrinter$en.internal(_root);
}

// Path: app
class Translations$app$en {
	Translations$app$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Mali Up'
	String get name => 'Mali Up';
}

// Path: pinResetCode
class Translations$pinResetCode$en {
	Translations$pinResetCode$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Reset your PIN'
	String get title => 'Reset your PIN';

	/// en: 'Enter the 6-digit code we sent by SMS to $phone.'
	String sentTo({required Object phone}) => 'Enter the 6-digit code we sent by SMS to ${phone}.';

	/// en: 'Enter the 6-digit code we sent by SMS to $phone and by email to $email.'
	String sentToBoth({required Object phone, required Object email}) => 'Enter the 6-digit code we sent by SMS to ${phone} and by email to ${email}.';

	/// en: 'Enter the 6-digit reset code we sent you by SMS.'
	String get sentGeneric => 'Enter the 6-digit reset code we sent you by SMS.';

	/// en: 'Reset code'
	String get codeLabel => 'Reset code';

	/// en: 'Enter the 6-digit code.'
	String get codeError => 'Enter the 6-digit code.';

	/// en: 'New PIN'
	String get newPinLabel => 'New PIN';

	/// en: 'Confirm new PIN'
	String get confirmPinLabel => 'Confirm new PIN';

	/// en: 'The PINs don't match.'
	String get pinMismatch => 'The PINs don\'t match.';

	/// en: 'Reset PIN'
	String get submit => 'Reset PIN';

	/// en: 'Didn't get it? Send a new code'
	String get resend => 'Didn\'t get it? Send a new code';

	/// en: 'Send a new code in ${seconds}s'
	String resendIn({required Object seconds}) => 'Send a new code in ${seconds}s';

	/// en: 'A new code is on its way.'
	String get resent => 'A new code is on its way.';

	/// en: 'That code is incorrect. $count attempts left.'
	String wrongCode({required Object count}) => 'That code is incorrect. ${count} attempts left.';

	/// en: 'That code is incorrect.'
	String get wrongCodeNoCount => 'That code is incorrect.';

	/// en: 'This code has expired. Send a new code.'
	String get expired => 'This code has expired. Send a new code.';

	/// en: 'Too many wrong codes. Send a new code.'
	String get tooManyAttempts => 'Too many wrong codes. Send a new code.';

	/// en: 'Could not reset your PIN. Check your connection and try again.'
	String get failed => 'Could not reset your PIN. Check your connection and try again.';

	/// en: 'Could not send a new code. Try again in a few minutes.'
	String get sendFailed => 'Could not send a new code. Try again in a few minutes.';

	/// en: 'Back to login'
	String get backToLogin => 'Back to login';
}

// Path: trial
class Translations$trial$en {
	Translations$trial$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Start using it'
	String get giftCta => 'Start using it';

	/// en: 'See plans'
	String get giftSeePlans => 'See plans';

	/// en: 'Ends on $date'
	String endsOn({required Object date}) => 'Ends on ${date}';

	/// en: '$days days left'
	String daysLeftChip({required Object days}) => '${days} days left';

	/// en: 'Last day'
	String get lastDayChip => 'Last day';

	/// en: 'Free $tier: $days days left'
	String bannerTitle({required Object tier, required Object days}) => 'Free ${tier}: ${days} days left';

	/// en: 'Free $tier ends today'
	String bannerTitleLastDay({required Object tier}) => 'Free ${tier} ends today';

	/// en: 'Ends on $date. Pay now to keep every feature.'
	String bannerBody({required Object date}) => 'Ends on ${date}. Pay now to keep every feature.';

	/// en: 'Pay'
	String get bannerCta => 'Pay';
}

// Path: receiptPrinter
class Translations$receiptPrinter$en {
	Translations$receiptPrinter$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Print receipt'
	String get printAction => 'Print receipt';

	/// en: 'Print'
	String get printShort => 'Print';

	/// en: 'Open PDF'
	String get openPdf => 'Open PDF';

	/// en: 'Sending to $name…'
	String sending({required Object name}) => 'Sending to ${name}…';

	/// en: 'Receipt printed.'
	String get printed => 'Receipt printed.';

	/// en: 'Could not open the print dialog. Please try again.'
	String get systemFailed => 'Could not open the print dialog. Please try again.';

	late final Translations$receiptPrinter$errors$en errors = Translations$receiptPrinter$errors$en.internal(_root);
	late final Translations$receiptPrinter$settings$en settings = Translations$receiptPrinter$settings$en.internal(_root);
}

// Path: receiptPrinter.errors
class Translations$receiptPrinter$errors$en {
	Translations$receiptPrinter$errors$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Bluetooth is off. Turn it on and try again.'
	String get off => 'Bluetooth is off. Turn it on and try again.';

	/// en: 'Allow Mali Up to use Nearby devices (Bluetooth) in your phone settings to print.'
	String get permission => 'Allow Mali Up to use Nearby devices (Bluetooth) in your phone settings to print.';

	/// en: 'This device can't print over Bluetooth. Choose System printer instead.'
	String get unsupported => 'This device can\'t print over Bluetooth. Choose System printer instead.';

	/// en: 'The saved printer is no longer paired. Choose it again in Settings → Receipt printer.'
	String get notFound => 'The saved printer is no longer paired. Choose it again in Settings → Receipt printer.';

	/// en: 'Couldn't reach the printer. Check that it's on, nearby and has paper.'
	String get connectFailed => 'Couldn\'t reach the printer. Check that it\'s on, nearby and has paper.';
}

// Path: receiptPrinter.settings
class Translations$receiptPrinter$settings$en {
	Translations$receiptPrinter$settings$en.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: 'Printing'
	String get sectionTitle => 'Printing';

	/// en: 'Receipt printer'
	String get tileTitle => 'Receipt printer';

	/// en: '$width · System printer'
	String tileSubtitleSystem({required Object width}) => '${width} · System printer';

	/// en: '$width · $name'
	String tileSubtitleBluetooth({required Object width, required Object name}) => '${width} · ${name}';

	/// en: 'Receipt printer'
	String get screenTitle => 'Receipt printer';

	/// en: 'Paper roll width'
	String get paperWidth => 'Paper roll width';

	/// en: 'Check the label on the paper roll or the printer.'
	String get paperWidthHint => 'Check the label on the paper roll or the printer.';

	/// en: 'Small handheld / Bluetooth printers'
	String get mm58Hint => 'Small handheld / Bluetooth printers';

	/// en: 'Counter / desktop printers'
	String get mm80Hint => 'Counter / desktop printers';

	/// en: 'Printer type'
	String get connection => 'Printer type';

	/// en: 'System printer'
	String get system => 'System printer';

	/// en: 'USB, Wi-Fi or Windows printer. Opens the print dialog.'
	String get systemHint => 'USB, Wi-Fi or Windows printer. Opens the print dialog.';

	/// en: 'Bluetooth receipt printer'
	String get bluetooth => 'Bluetooth receipt printer';

	/// en: 'Prints straight away, no dialog.'
	String get bluetoothHint => 'Prints straight away, no dialog.';

	/// en: 'Bluetooth printing works on Android phones and POS devices. On this device, use a printer with a driver (USB or Wi-Fi).'
	String get bluetoothAndroidOnly => 'Bluetooth printing works on Android phones and POS devices. On this device, use a printer with a driver (USB or Wi-Fi).';

	/// en: 'Choose printer'
	String get choosePrinter => 'Choose printer';

	/// en: 'Pair the printer first in your phone's Bluetooth settings (the PIN is usually 0000 or 1234), then tap Refresh.'
	String get pairFirst => 'Pair the printer first in your phone\'s Bluetooth settings (the PIN is usually 0000 or 1234), then tap Refresh.';

	/// en: 'Refresh'
	String get refresh => 'Refresh';

	/// en: 'No paired Bluetooth devices found.'
	String get noDevices => 'No paired Bluetooth devices found.';

	/// en: 'Printer'
	String get likelyPrinter => 'Printer';

	/// en: 'Print test page'
	String get testPrint => 'Print test page';

	/// en: 'Test page sent.'
	String get testSent => 'Test page sent.';

	/// en: 'Choose a printer first.'
	String get selectPrinterFirst => 'Choose a printer first.';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.name' => 'Mali Up',
			'pinResetCode.title' => 'Reset your PIN',
			'pinResetCode.sentTo' => ({required Object phone}) => 'Enter the 6-digit code we sent by SMS to ${phone}.',
			'pinResetCode.sentToBoth' => ({required Object phone, required Object email}) => 'Enter the 6-digit code we sent by SMS to ${phone} and by email to ${email}.',
			'pinResetCode.sentGeneric' => 'Enter the 6-digit reset code we sent you by SMS.',
			'pinResetCode.codeLabel' => 'Reset code',
			'pinResetCode.codeError' => 'Enter the 6-digit code.',
			'pinResetCode.newPinLabel' => 'New PIN',
			'pinResetCode.confirmPinLabel' => 'Confirm new PIN',
			'pinResetCode.pinMismatch' => 'The PINs don\'t match.',
			'pinResetCode.submit' => 'Reset PIN',
			'pinResetCode.resend' => 'Didn\'t get it? Send a new code',
			'pinResetCode.resendIn' => ({required Object seconds}) => 'Send a new code in ${seconds}s',
			'pinResetCode.resent' => 'A new code is on its way.',
			'pinResetCode.wrongCode' => ({required Object count}) => 'That code is incorrect. ${count} attempts left.',
			'pinResetCode.wrongCodeNoCount' => 'That code is incorrect.',
			'pinResetCode.expired' => 'This code has expired. Send a new code.',
			'pinResetCode.tooManyAttempts' => 'Too many wrong codes. Send a new code.',
			'pinResetCode.failed' => 'Could not reset your PIN. Check your connection and try again.',
			'pinResetCode.sendFailed' => 'Could not send a new code. Try again in a few minutes.',
			'pinResetCode.backToLogin' => 'Back to login',
			'trial.giftCta' => 'Start using it',
			'trial.giftSeePlans' => 'See plans',
			'trial.endsOn' => ({required Object date}) => 'Ends on ${date}',
			'trial.daysLeftChip' => ({required Object days}) => '${days} days left',
			'trial.lastDayChip' => 'Last day',
			'trial.bannerTitle' => ({required Object tier, required Object days}) => 'Free ${tier}: ${days} days left',
			'trial.bannerTitleLastDay' => ({required Object tier}) => 'Free ${tier} ends today',
			'trial.bannerBody' => ({required Object date}) => 'Ends on ${date}. Pay now to keep every feature.',
			'trial.bannerCta' => 'Pay',
			'receiptPrinter.printAction' => 'Print receipt',
			'receiptPrinter.printShort' => 'Print',
			'receiptPrinter.openPdf' => 'Open PDF',
			'receiptPrinter.sending' => ({required Object name}) => 'Sending to ${name}…',
			'receiptPrinter.printed' => 'Receipt printed.',
			'receiptPrinter.systemFailed' => 'Could not open the print dialog. Please try again.',
			'receiptPrinter.errors.off' => 'Bluetooth is off. Turn it on and try again.',
			'receiptPrinter.errors.permission' => 'Allow Mali Up to use Nearby devices (Bluetooth) in your phone settings to print.',
			'receiptPrinter.errors.unsupported' => 'This device can\'t print over Bluetooth. Choose System printer instead.',
			'receiptPrinter.errors.notFound' => 'The saved printer is no longer paired. Choose it again in Settings → Receipt printer.',
			'receiptPrinter.errors.connectFailed' => 'Couldn\'t reach the printer. Check that it\'s on, nearby and has paper.',
			'receiptPrinter.settings.sectionTitle' => 'Printing',
			'receiptPrinter.settings.tileTitle' => 'Receipt printer',
			'receiptPrinter.settings.tileSubtitleSystem' => ({required Object width}) => '${width} · System printer',
			'receiptPrinter.settings.tileSubtitleBluetooth' => ({required Object width, required Object name}) => '${width} · ${name}',
			'receiptPrinter.settings.screenTitle' => 'Receipt printer',
			'receiptPrinter.settings.paperWidth' => 'Paper roll width',
			'receiptPrinter.settings.paperWidthHint' => 'Check the label on the paper roll or the printer.',
			'receiptPrinter.settings.mm58Hint' => 'Small handheld / Bluetooth printers',
			'receiptPrinter.settings.mm80Hint' => 'Counter / desktop printers',
			'receiptPrinter.settings.connection' => 'Printer type',
			'receiptPrinter.settings.system' => 'System printer',
			'receiptPrinter.settings.systemHint' => 'USB, Wi-Fi or Windows printer. Opens the print dialog.',
			'receiptPrinter.settings.bluetooth' => 'Bluetooth receipt printer',
			'receiptPrinter.settings.bluetoothHint' => 'Prints straight away, no dialog.',
			'receiptPrinter.settings.bluetoothAndroidOnly' => 'Bluetooth printing works on Android phones and POS devices. On this device, use a printer with a driver (USB or Wi-Fi).',
			'receiptPrinter.settings.choosePrinter' => 'Choose printer',
			'receiptPrinter.settings.pairFirst' => 'Pair the printer first in your phone\'s Bluetooth settings (the PIN is usually 0000 or 1234), then tap Refresh.',
			'receiptPrinter.settings.refresh' => 'Refresh',
			'receiptPrinter.settings.noDevices' => 'No paired Bluetooth devices found.',
			'receiptPrinter.settings.likelyPrinter' => 'Printer',
			'receiptPrinter.settings.testPrint' => 'Print test page',
			'receiptPrinter.settings.testSent' => 'Test page sent.',
			'receiptPrinter.settings.selectPrinterFirst' => 'Choose a printer first.',
			_ => null,
		};
	}
}
