import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastos/providers/balance_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gastos/models/movement.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('gastos_test_');

    // Mock path_provider
    const MethodChannel channel =
        MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return tempDir.path;
    });

    // Initialize Hive
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MovementAdapter());
    }
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Renaming profile preserves data and updates configuration correctly',
      () async {
    final provider = BalanceProvider();

    // 1. Initialize and create a profile
    await provider.init();
    await provider.crearPerfil('OldProfile');

    // 2. Add some data
    await provider.establecerSaldoInicialEfectivo(100.0);
    await provider.agregarMovimiento(Movement(
      date: DateTime.now(),
      concept: 'Test Movement',
      amount: 50.0,
      isDigital: false,
    ));

    expect(provider.perfilActual, 'OldProfile');
    expect(provider.saldoActualEfectivo, 150.0);
    expect(provider.movimientos.length, 1);

    // 3. Rename the profile
    await provider.editarNombrePerfil('OldProfile', 'NewProfile');

    // 4. Verify provider state
    expect(provider.perfilActual, 'NewProfile');

    // 5. Verify data is preserved
    // The getters should work without throwing "Box closed" error
    expect(provider.saldoActualEfectivo, 150.0);
    expect(provider.movimientos.length, 1);
    expect(provider.movimientos.first.concept, 'Test Movement');
  });
}
