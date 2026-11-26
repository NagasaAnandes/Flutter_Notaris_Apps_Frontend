import 'package:flutter/foundation.dart';

import '../../../domain/entities/kbli.dart';
import '../../../domain/entities/kbli_conversion.dart';
import '../../../domain/entities/kbli_version.dart';

@immutable
class KbliState {
  const KbliState({
    this.results = const [],
    this.query = '',
    this.version = KbliVersion.kbli2020,
    this.conversions = const [],
    this.isLoading = false,
    this.isLoadingConversions = false,
    this.error,
    this.conversionsError,
  });

  final List<Kbli> results;
  final String query;
  final KbliVersion version;
  final List<KbliConversion> conversions;

  final bool isLoading;
  final bool isLoadingConversions;

  final String? error;
  final String? conversionsError;

  KbliState copyWith({
    List<Kbli>? results,
    String? query,
    KbliVersion? version,
    List<KbliConversion>? conversions,
    bool? isLoading,
    bool? isLoadingConversions,
    String? error,
    bool clearError = false,
    String? conversionsError,
    bool clearConversionsError = false,
    bool clearConversions = false,
  }) {
    return KbliState(
      results: results ?? this.results,
      query: query ?? this.query,
      version: version ?? this.version,
      conversions: clearConversions
          ? const []
          : conversions ?? this.conversions,
      isLoading: isLoading ?? this.isLoading,
      isLoadingConversions: isLoadingConversions ?? this.isLoadingConversions,
      error: clearError ? null : error ?? this.error,
      conversionsError: clearConversionsError
          ? null
          : conversionsError ?? this.conversionsError,
    );
  }
}
