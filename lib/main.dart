import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/balance_provider.dart';
import 'screens/movements_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/movement.dart';

void main() {
  // Ejecutamos toda la inicialización dentro de la misma zona usada por Flutter
  // para evitar errores de "Zone mismatch" al inicializar los bindings antes
  // de hacer runApp().
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Hive.initFlutter();
    Hive.registerAdapter(MovementAdapter());

    // Inicializar WindowManager en plataformas de escritorio
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS)) {
      await windowManager.ensureInitialized();

      // Abrir box para configuraciones de ventana
      final settingsBox = await Hive.openBox('window_settings');

      // Obtener dimensiones guardadas o usar valores por defecto óptimos
      final double width = settingsBox.get('width', defaultValue: 720.0);
      final double height = settingsBox.get('height', defaultValue: 1280.0);
      final double? x = settingsBox.get('x');
      final double? y = settingsBox.get('y');

      WindowOptions windowOptions = WindowOptions(
        size: Size(width, height),
        minimumSize: const Size(480, 820),
        center: x == null || y == null, // Centrar si no hay posición guardada
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
      );

      // Listener para guardar cambios
      windowManager.addListener(_WindowObserver(settingsBox));

      windowManager.waitUntilReadyToShow(windowOptions, () async {
        if (x != null && y != null) {
          await windowManager.setPosition(Offset(x, y));
        }
        await windowManager.show();
        await windowManager.focus();
      });
    }

    final balanceProvider = BalanceProvider();

    runApp(
      ChangeNotifierProvider.value(
        value: balanceProvider,
        child: const MiAplicacion(),
      ),
    );
  }, (error, stack) {
    // En modo debug mostramos la traza, en producción la omitimos
    if (kDebugMode) {
      debugPrint('Error no capturado en la zona: $error');
      debugPrint(stack.toString());
    }
  });
}

// Clase para escuchar y guardar cambios en la ventana
class _WindowObserver extends WindowListener {
  final Box settingsBox;
  _WindowObserver(this.settingsBox);

  @override
  void onWindowResize() async {
    final size = await windowManager.getSize();
    settingsBox.put('width', size.width);
    settingsBox.put('height', size.height);
  }

  @override
  void onWindowMove() async {
    final pos = await windowManager.getPosition();
    settingsBox.put('x', pos.dx);
    settingsBox.put('y', pos.dy);
  }
}

class MiAplicacion extends StatelessWidget {
  const MiAplicacion({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos un FutureBuilder para manejar la inicialización asíncrona del provider.
    return FutureBuilder(
      // Llamamos al método init() aquí en lugar de en main().
      future: Provider.of<BalanceProvider>(context, listen: false).init(),
      builder: (context, snapshot) {
        // Mientras se está inicializando, mostramos una pantalla de carga.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        // Una vez inicializado, construimos la app principal.
        // Ahora es seguro acceder a las propiedades del provider.
        return MaterialApp(
          title: 'Gestor de Dinero',
          theme: ThemeData.dark(useMaterial3: true).copyWith(
            appBarTheme: const AppBarTheme(
              centerTitle: true,
            ),
          ),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', 'US'), // Español (Domingo primer día)
          ],
          // Establece español (con domingo como primer día) como idioma por defecto para toda la app.
          locale: const Locale('es', 'US'),
          home: const PantallaMovimientos(),
        );
      },
    );
  }
}
