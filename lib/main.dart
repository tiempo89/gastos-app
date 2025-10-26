import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
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
    final appDocumentDir = await getApplicationDocumentsDirectory();
    await Hive.initFlutter(appDocumentDir.path);
    Hive.registerAdapter(MovementAdapter());

    final balanceProvider = BalanceProvider();
    await balanceProvider.init();

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

class MiAplicacion extends StatelessWidget {
  const MiAplicacion({super.key});

  @override
  Widget build(BuildContext context) {
    final esModoOscuro = Provider.of<BalanceProvider>(context).esModoOscuro;
    return MaterialApp(
      title: 'Gestor de Dinero',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue, brightness: Brightness.dark),
        useMaterial3: true,
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
        ),
      ),
      themeMode: esModoOscuro ? ThemeMode.dark : ThemeMode.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Español
      ],
      locale:
          const Locale('es', 'ES'), // Establece español como idioma por defecto
      home: const PantallaMovimientos(),
    );
  }
}
