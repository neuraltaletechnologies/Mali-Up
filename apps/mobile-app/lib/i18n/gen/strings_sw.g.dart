///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'strings.g.dart';

// Path: <root>
class TranslationsSw extends Translations with BaseTranslations<AppLocale, Translations> {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsSw({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.sw,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ),
		  super(cardinalResolver: cardinalResolver, ordinalResolver: ordinalResolver) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <sw>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	@override dynamic operator[](String key) => _meta.getTranslation(key) ?? super[key];

	late final TranslationsSw _root = this; // ignore: unused_field

	@override 
	TranslationsSw $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsSw(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$sw app = _Translations$app$sw._(_root);
	@override late final _Translations$pinResetCode$sw pinResetCode = _Translations$pinResetCode$sw._(_root);
	@override late final _Translations$trial$sw trial = _Translations$trial$sw._(_root);
	@override late final _Translations$receiptPrinter$sw receiptPrinter = _Translations$receiptPrinter$sw._(_root);
}

// Path: app
class _Translations$app$sw extends Translations$app$en {
	_Translations$app$sw._(TranslationsSw root) : this._root = root, super.internal(root);

	final TranslationsSw _root; // ignore: unused_field

	// Translations
	@override String get name => 'Mali Up';
}

// Path: pinResetCode
class _Translations$pinResetCode$sw extends Translations$pinResetCode$en {
	_Translations$pinResetCode$sw._(TranslationsSw root) : this._root = root, super.internal(root);

	final TranslationsSw _root; // ignore: unused_field

	// Translations
	@override String get title => 'Weka upya PIN yako';
	@override String sentTo({required Object phone}) => 'Weka namba ya siri ya tarakimu 6 tuliyotuma kwa SMS kwenda ${phone}.';
	@override String sentToBoth({required Object phone, required Object email}) => 'Weka namba ya siri ya tarakimu 6 tuliyotuma kwa SMS kwenda ${phone} na kwa barua pepe kwenda ${email}.';
	@override String get sentGeneric => 'Weka namba ya siri ya kuweka upya PIN tuliyokutumia kwa SMS.';
	@override String get codeLabel => 'Namba ya siri';
	@override String get codeError => 'Weka namba ya siri ya tarakimu 6.';
	@override String get newPinLabel => 'PIN mpya';
	@override String get confirmPinLabel => 'Thibitisha PIN mpya';
	@override String get pinMismatch => 'PIN hazifanani.';
	@override String get submit => 'Weka upya PIN';
	@override String get resend => 'Hukuipata? Tuma namba mpya';
	@override String resendIn({required Object seconds}) => 'Tuma namba mpya baada ya sekunde ${seconds}';
	@override String get resent => 'Namba mpya inatumwa.';
	@override String wrongCode({required Object count}) => 'Namba si sahihi. Umebakiza majaribio ${count}.';
	@override String get wrongCodeNoCount => 'Namba si sahihi.';
	@override String get expired => 'Namba hii imekwisha muda. Tuma namba mpya.';
	@override String get tooManyAttempts => 'Umekosea mara nyingi sana. Tuma namba mpya.';
	@override String get failed => 'Imeshindikana kuweka upya PIN. Angalia mtandao na ujaribu tena.';
	@override String get sendFailed => 'Imeshindikana kutuma namba mpya. Jaribu tena baada ya dakika chache.';
	@override String get backToLogin => 'Rudi kuingia';
}

// Path: trial
class _Translations$trial$sw extends Translations$trial$en {
	_Translations$trial$sw._(TranslationsSw root) : this._root = root, super.internal(root);

	final TranslationsSw _root; // ignore: unused_field

	// Translations
	@override String get giftCta => 'Anza kutumia';
	@override String get giftSeePlans => 'Angalia mipango';
	@override String endsOn({required Object date}) => 'Kinaisha ${date}';
	@override String daysLeftChip({required Object days}) => 'Siku ${days} zimebaki';
	@override String get lastDayChip => 'Siku ya mwisho';
	@override String bannerTitle({required Object tier, required Object days}) => '${tier} bure: siku ${days} zimebaki';
	@override String bannerTitleLastDay({required Object tier}) => '${tier} bure kinaisha leo';
	@override String bannerBody({required Object date}) => 'Kinaisha tarehe ${date}. Lipia sasa uendelee kutumia vipengele vyote.';
	@override String get bannerCta => 'Lipia';
}

// Path: receiptPrinter
class _Translations$receiptPrinter$sw extends Translations$receiptPrinter$en {
	_Translations$receiptPrinter$sw._(TranslationsSw root) : this._root = root, super.internal(root);

	final TranslationsSw _root; // ignore: unused_field

	// Translations
	@override String get printAction => 'Chapisha risiti';
	@override String get printShort => 'Chapisha';
	@override String get openPdf => 'Fungua PDF';
	@override String sending({required Object name}) => 'Inatuma kwa ${name}…';
	@override String get printed => 'Risiti imechapishwa.';
	@override String get systemFailed => 'Imeshindwa kufungua dirisha la kuchapisha. Jaribu tena.';
	@override late final _Translations$receiptPrinter$errors$sw errors = _Translations$receiptPrinter$errors$sw._(_root);
	@override late final _Translations$receiptPrinter$settings$sw settings = _Translations$receiptPrinter$settings$sw._(_root);
}

// Path: receiptPrinter.errors
class _Translations$receiptPrinter$errors$sw extends Translations$receiptPrinter$errors$en {
	_Translations$receiptPrinter$errors$sw._(TranslationsSw root) : this._root = root, super.internal(root);

	final TranslationsSw _root; // ignore: unused_field

	// Translations
	@override String get off => 'Bluetooth imezimwa. Iwashe kisha ujaribu tena.';
	@override String get permission => 'Ruhusu Mali Up kutumia Vifaa vilivyo karibu (Bluetooth) kwenye mipangilio ya simu ili kuchapisha.';
	@override String get unsupported => 'Kifaa hiki hakiwezi kuchapisha kwa Bluetooth. Chagua Printa ya mfumo badala yake.';
	@override String get notFound => 'Printa iliyohifadhiwa haijaunganishwa tena. Ichague upya kwenye Mipangilio → Printa ya risiti.';
	@override String get connectFailed => 'Imeshindwa kufikia printa. Hakikisha imewashwa, iko karibu na ina karatasi.';
}

// Path: receiptPrinter.settings
class _Translations$receiptPrinter$settings$sw extends Translations$receiptPrinter$settings$en {
	_Translations$receiptPrinter$settings$sw._(TranslationsSw root) : this._root = root, super.internal(root);

	final TranslationsSw _root; // ignore: unused_field

	// Translations
	@override String get sectionTitle => 'Uchapishaji';
	@override String get tileTitle => 'Printa ya risiti';
	@override String tileSubtitleSystem({required Object width}) => '${width} · Printa ya mfumo';
	@override String tileSubtitleBluetooth({required Object width, required Object name}) => '${width} · ${name}';
	@override String get screenTitle => 'Printa ya risiti';
	@override String get paperWidth => 'Upana wa karatasi';
	@override String get paperWidthHint => 'Angalia lebo kwenye roli ya karatasi au kwenye printa.';
	@override String get mm58Hint => 'Printa ndogo za mkononi / Bluetooth';
	@override String get mm80Hint => 'Printa za kaunta / mezani';
	@override String get connection => 'Aina ya printa';
	@override String get system => 'Printa ya mfumo';
	@override String get systemHint => 'Printa ya USB, Wi-Fi au Windows. Inafungua dirisha la kuchapisha.';
	@override String get bluetooth => 'Printa ya risiti ya Bluetooth';
	@override String get bluetoothHint => 'Inachapisha moja kwa moja, bila dirisha.';
	@override String get bluetoothAndroidOnly => 'Uchapishaji wa Bluetooth unafanya kazi kwenye simu na mashine za POS za Android. Kwenye kifaa hiki, tumia printa yenye dereva (USB au Wi-Fi).';
	@override String get choosePrinter => 'Chagua printa';
	@override String get pairFirst => 'Unganisha printa kwanza kwenye mipangilio ya Bluetooth ya simu (PIN mara nyingi ni 0000 au 1234), kisha gusa Onyesha upya.';
	@override String get refresh => 'Onyesha upya';
	@override String get noDevices => 'Hakuna vifaa vya Bluetooth vilivyounganishwa.';
	@override String get likelyPrinter => 'Printa';
	@override String get testPrint => 'Chapisha ukurasa wa majaribio';
	@override String get testSent => 'Ukurasa wa majaribio umetumwa.';
	@override String get selectPrinterFirst => 'Chagua printa kwanza.';
}

/// The flat map containing all translations for locale <sw>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsSw {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.name' => 'Mali Up',
			'pinResetCode.title' => 'Weka upya PIN yako',
			'pinResetCode.sentTo' => ({required Object phone}) => 'Weka namba ya siri ya tarakimu 6 tuliyotuma kwa SMS kwenda ${phone}.',
			'pinResetCode.sentToBoth' => ({required Object phone, required Object email}) => 'Weka namba ya siri ya tarakimu 6 tuliyotuma kwa SMS kwenda ${phone} na kwa barua pepe kwenda ${email}.',
			'pinResetCode.sentGeneric' => 'Weka namba ya siri ya kuweka upya PIN tuliyokutumia kwa SMS.',
			'pinResetCode.codeLabel' => 'Namba ya siri',
			'pinResetCode.codeError' => 'Weka namba ya siri ya tarakimu 6.',
			'pinResetCode.newPinLabel' => 'PIN mpya',
			'pinResetCode.confirmPinLabel' => 'Thibitisha PIN mpya',
			'pinResetCode.pinMismatch' => 'PIN hazifanani.',
			'pinResetCode.submit' => 'Weka upya PIN',
			'pinResetCode.resend' => 'Hukuipata? Tuma namba mpya',
			'pinResetCode.resendIn' => ({required Object seconds}) => 'Tuma namba mpya baada ya sekunde ${seconds}',
			'pinResetCode.resent' => 'Namba mpya inatumwa.',
			'pinResetCode.wrongCode' => ({required Object count}) => 'Namba si sahihi. Umebakiza majaribio ${count}.',
			'pinResetCode.wrongCodeNoCount' => 'Namba si sahihi.',
			'pinResetCode.expired' => 'Namba hii imekwisha muda. Tuma namba mpya.',
			'pinResetCode.tooManyAttempts' => 'Umekosea mara nyingi sana. Tuma namba mpya.',
			'pinResetCode.failed' => 'Imeshindikana kuweka upya PIN. Angalia mtandao na ujaribu tena.',
			'pinResetCode.sendFailed' => 'Imeshindikana kutuma namba mpya. Jaribu tena baada ya dakika chache.',
			'pinResetCode.backToLogin' => 'Rudi kuingia',
			'trial.giftCta' => 'Anza kutumia',
			'trial.giftSeePlans' => 'Angalia mipango',
			'trial.endsOn' => ({required Object date}) => 'Kinaisha ${date}',
			'trial.daysLeftChip' => ({required Object days}) => 'Siku ${days} zimebaki',
			'trial.lastDayChip' => 'Siku ya mwisho',
			'trial.bannerTitle' => ({required Object tier, required Object days}) => '${tier} bure: siku ${days} zimebaki',
			'trial.bannerTitleLastDay' => ({required Object tier}) => '${tier} bure kinaisha leo',
			'trial.bannerBody' => ({required Object date}) => 'Kinaisha tarehe ${date}. Lipia sasa uendelee kutumia vipengele vyote.',
			'trial.bannerCta' => 'Lipia',
			'receiptPrinter.printAction' => 'Chapisha risiti',
			'receiptPrinter.printShort' => 'Chapisha',
			'receiptPrinter.openPdf' => 'Fungua PDF',
			'receiptPrinter.sending' => ({required Object name}) => 'Inatuma kwa ${name}…',
			'receiptPrinter.printed' => 'Risiti imechapishwa.',
			'receiptPrinter.systemFailed' => 'Imeshindwa kufungua dirisha la kuchapisha. Jaribu tena.',
			'receiptPrinter.errors.off' => 'Bluetooth imezimwa. Iwashe kisha ujaribu tena.',
			'receiptPrinter.errors.permission' => 'Ruhusu Mali Up kutumia Vifaa vilivyo karibu (Bluetooth) kwenye mipangilio ya simu ili kuchapisha.',
			'receiptPrinter.errors.unsupported' => 'Kifaa hiki hakiwezi kuchapisha kwa Bluetooth. Chagua Printa ya mfumo badala yake.',
			'receiptPrinter.errors.notFound' => 'Printa iliyohifadhiwa haijaunganishwa tena. Ichague upya kwenye Mipangilio → Printa ya risiti.',
			'receiptPrinter.errors.connectFailed' => 'Imeshindwa kufikia printa. Hakikisha imewashwa, iko karibu na ina karatasi.',
			'receiptPrinter.settings.sectionTitle' => 'Uchapishaji',
			'receiptPrinter.settings.tileTitle' => 'Printa ya risiti',
			'receiptPrinter.settings.tileSubtitleSystem' => ({required Object width}) => '${width} · Printa ya mfumo',
			'receiptPrinter.settings.tileSubtitleBluetooth' => ({required Object width, required Object name}) => '${width} · ${name}',
			'receiptPrinter.settings.screenTitle' => 'Printa ya risiti',
			'receiptPrinter.settings.paperWidth' => 'Upana wa karatasi',
			'receiptPrinter.settings.paperWidthHint' => 'Angalia lebo kwenye roli ya karatasi au kwenye printa.',
			'receiptPrinter.settings.mm58Hint' => 'Printa ndogo za mkononi / Bluetooth',
			'receiptPrinter.settings.mm80Hint' => 'Printa za kaunta / mezani',
			'receiptPrinter.settings.connection' => 'Aina ya printa',
			'receiptPrinter.settings.system' => 'Printa ya mfumo',
			'receiptPrinter.settings.systemHint' => 'Printa ya USB, Wi-Fi au Windows. Inafungua dirisha la kuchapisha.',
			'receiptPrinter.settings.bluetooth' => 'Printa ya risiti ya Bluetooth',
			'receiptPrinter.settings.bluetoothHint' => 'Inachapisha moja kwa moja, bila dirisha.',
			'receiptPrinter.settings.bluetoothAndroidOnly' => 'Uchapishaji wa Bluetooth unafanya kazi kwenye simu na mashine za POS za Android. Kwenye kifaa hiki, tumia printa yenye dereva (USB au Wi-Fi).',
			'receiptPrinter.settings.choosePrinter' => 'Chagua printa',
			'receiptPrinter.settings.pairFirst' => 'Unganisha printa kwanza kwenye mipangilio ya Bluetooth ya simu (PIN mara nyingi ni 0000 au 1234), kisha gusa Onyesha upya.',
			'receiptPrinter.settings.refresh' => 'Onyesha upya',
			'receiptPrinter.settings.noDevices' => 'Hakuna vifaa vya Bluetooth vilivyounganishwa.',
			'receiptPrinter.settings.likelyPrinter' => 'Printa',
			'receiptPrinter.settings.testPrint' => 'Chapisha ukurasa wa majaribio',
			'receiptPrinter.settings.testSent' => 'Ukurasa wa majaribio umetumwa.',
			'receiptPrinter.settings.selectPrinterFirst' => 'Chagua printa kwanza.',
			_ => null,
		};
	}
}
