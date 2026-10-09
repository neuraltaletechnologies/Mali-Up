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
			_ => null,
		};
	}
}
