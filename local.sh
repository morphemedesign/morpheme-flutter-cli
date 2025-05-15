rm -f pubspec.lock
rm -rf .dart_tool
dart pub get

dart pub global activate --source path . --overwrite