.PHONY: pigeon

# Regenerate the type-safe platform channel code (Dart/Kotlin/Swift) from
# pigeons/messages.dart.
pigeon:
	dart run pigeon --input pigeons/messages.dart
