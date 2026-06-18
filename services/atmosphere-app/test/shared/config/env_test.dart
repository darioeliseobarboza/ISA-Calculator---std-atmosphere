import 'package:atmosphere_app/shared/config/env.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Env.fromDotenv', () {
    tearDown(() {
      // Limpiar el estado global de dotenv entre tests.
      dotenv.clean();
    });

    test('TS-1: carga API_BASE_URL cuando está presente', () {
      dotenv.testLoad(fileInput: 'API_BASE_URL=http://localhost:8080');

      final env = Env.fromDotenv();

      expect(env.apiBaseUrl, 'http://localhost:8080');
    });

    test('TS-2: fail-fast con StateError cuando falta API_BASE_URL', () {
      dotenv.testLoad(fileInput: '');

      expect(
        Env.fromDotenv,
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'missing env API_BASE_URL',
          ),
        ),
      );
    });
  });
}
