import '../../../domain/entities/kbli_version.dart';

sealed class KbliEvent {
  const KbliEvent();
}

final class KbliSearchRequested extends KbliEvent {
  const KbliSearchRequested({required this.version, required this.query});

  final KbliVersion version;
  final String query;
}

final class KbliConversionsRequested extends KbliEvent {
  const KbliConversionsRequested({required this.sourceCode});

  final String sourceCode;
}

final class KbliDetailCleared extends KbliEvent {
  const KbliDetailCleared();
}
