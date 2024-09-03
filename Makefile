build_cli:
	fvm dart run

update_version:
	rm lib/src/version.dart
	fvm dart run build_runner build --delete-conflicting-outputs