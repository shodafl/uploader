import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

// Helper functions extracted from uploader.dart for testing
void validateArguments(List<String> arguments) {
  if (arguments.length < 3 || arguments.length > 4) {
    throw ArgumentError(
      'You should pass arguments in order: [packageName] [bundleFilePath] [jsonKeyFilePath]',
    );
  }
}

bool parseChangesNotSentForReview(List<String> arguments) {
  return arguments.length > 3 ? arguments[3] == 'true' : false;
}

void main() {
  group('Argument Validation', () {
    test('validates correct number of arguments', () {
      // Valid arguments
      expect(
          () => validateArguments(['com.example.app', 'bundle.aab', 'key.json']),
          returnsNormally);
      expect(
          () => validateArguments(
              ['com.example.app', 'bundle.aab', 'key.json', 'true']),
          returnsNormally);

      // Invalid arguments
      expect(() => validateArguments([]), throwsArgumentError);
      expect(() => validateArguments(['one']), throwsArgumentError);
      expect(() => validateArguments(['one', 'two']), throwsArgumentError);
      expect(() => validateArguments(['one', 'two', 'three', 'four', 'five']),
          throwsArgumentError);
    });

    test('parses changesNotSentForReview flag correctly', () {
      // Default (no flag)
      expect(
          parseChangesNotSentForReview(
              ['com.example.app', 'bundle.aab', 'key.json']),
          isFalse);

      // Explicit true
      expect(
          parseChangesNotSentForReview(
              ['com.example.app', 'bundle.aab', 'key.json', 'true']),
          isTrue);

      // Explicit false
      expect(
          parseChangesNotSentForReview(
              ['com.example.app', 'bundle.aab', 'key.json', 'false']),
          isFalse);
    });
  });

  group('Scopes Configuration', () {
    test('uses correct scopes', () {
      const scopes = ['https://www.googleapis.com/auth/androidpublisher'];

      expect(scopes, hasLength(1));
      expect(scopes[0], equals('https://www.googleapis.com/auth/androidpublisher'));
    });
  });

  group('JSON Key Parsing', () {
    test('can parse valid service account JSON', () {
      final validJson = '{"type": "service_account", "project_id": "test-project"}';
      
      final jsonMap = jsonDecode(validJson) as Map<String, dynamic>;
      
      expect(jsonMap, isA<Map<String, dynamic>>());
      expect(jsonMap['type'], equals('service_account'));
      expect(jsonMap['project_id'], equals('test-project'));
    });
  });

  group('File Operations', () {
    late Directory tempDir;
    late File tempJsonFile;
    late File tempBundleFile;
    
    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('uploader_test_');
      tempJsonFile = File('${tempDir.path}/key.json')
        ..writeAsStringSync('{"type": "service_account", "project_id": "test"}');
      tempBundleFile = File('${tempDir.path}/bundle.aab')
        ..writeAsStringSync('bundle content');
    });
    
    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });
    
    test('can read JSON key file', () {
      expect(tempJsonFile.existsSync(), isTrue);
      
      final content = tempJsonFile.readAsStringSync();
      expect(content, contains('service_account'));
      expect(content, contains('test'));
    });
    
    test('can get file length', () async {
      final length = await tempBundleFile.length();
      expect(length, equals(14)); // 'bundle content'.length
    });
    
    test('can open file stream', () async {
      final stream = tempBundleFile.openRead();
      final bytes = await stream.expand((chunk) => chunk).toList();
      
      expect(bytes.length, equals(14));
      expect(String.fromCharCodes(bytes), equals('bundle content'));
    });
  });
}