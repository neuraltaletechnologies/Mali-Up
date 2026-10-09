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
}

// Path: app
class _Translations$app$sw extends Translations$app$en {
	_Translations$app$sw._(TranslationsSw root) : this._root = root, super.internal(root);

	final TranslationsSw _root; // ignore: unused_field

	// Translations
	@override String get name => 'Mali Up';
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
			_ => null,
		};
	}
}
