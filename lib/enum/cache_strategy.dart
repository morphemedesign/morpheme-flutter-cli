import 'package:morpheme_cli/helper/recase.dart';

extension CacheStrategyExtension on CacheStrategy? {
  String toParamCacheStrategy({int? ttl, bool? keepExpiredCache}) {
    if (this == null) {
      return 'cacheStrategy: cacheStrategy';
    }
    if (this == CacheStrategy.justAsync) {
      return 'cacheStrategy: cacheStrategy ?? ${this?.value.pascalCase}Strategy(),';
    }
    return 'cacheStrategy: cacheStrategy ?? ${this?.value.pascalCase}Strategy(${ttl == null ? '' : 'ttlValue: const Duration(minutes: $ttl)'}${keepExpiredCache == null ? '' : ttl == null ? '' : ', keepExpiredCache: $keepExpiredCache'}${ttl != null || keepExpiredCache != null ? ',' : ''}),';
  }

  String toParamCacheStrategyTest({int? ttl, bool? keepExpiredCache}) {
    if (this == null) {
      return '';
    }
    if (this == CacheStrategy.justAsync) {
      return 'cacheStrategy: ${this?.value.pascalCase}Strategy(),';
    }
    return 'cacheStrategy: ${this?.value.pascalCase}Strategy(${ttl == null ? '' : 'ttlValue: const Duration(minutes: $ttl)'}${keepExpiredCache == null ? '' : ttl == null ? '' : ', keepExpiredCache: $keepExpiredCache'}${ttl != null || keepExpiredCache != null ? ',' : ''}),';
  }
}

enum CacheStrategy {
  asyncOrCache('async_or_cache'),
  cacheOrAsync('cache_or_async'),
  justAsync('just_async'),
  justCache('just_cache');

  const CacheStrategy(this.value);

  final String value;

  static CacheStrategy fromString(String value) {
    return CacheStrategy.values.firstWhere((e) => e.value == value);
  }
}
