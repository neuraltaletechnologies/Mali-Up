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
			_ => null,
		};
	}
}
