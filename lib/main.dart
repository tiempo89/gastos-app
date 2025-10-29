import 'dart:async';
import 'package:flutter/foundation.dart';
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
        // Vamos a definir un ColorScheme personalizado para el tema claro
        colorScheme: ColorScheme(
          brightness: Brightness.light, // Mantenemos que es un tema claro
          primary: const Color(0xFF006A60), // Color principal (ej. AppBar)
          onPrimary: Colors.white, // Color del texto sobre el primario
          primaryContainer: const Color(
              0xFF74F8E9), // Contenedor del primario (ej. DrawerHeader)
          onPrimaryContainer:
              const Color.fromARGB(255, 32, 21, 0), // Texto sobre el contenedor primario
          secondary: const Color(0xFF4A635F), // Color secundario para acentos
          onSecondary: Colors.white, // Texto sobre el secundario
          surface:
              const Color.fromARGB(255, 237, 238, 237), // Color de fondo para Cards, Dialogs
          onSurface: const Color(0xFF171D1C), // Color del texto principal
          error: const Color(0xFFBA1A1A), // Color para errores
          onError: Colors.white, // Texto sobre el color de error
        ),
        useMaterial3: true,
        scaffoldBackgroundColor:
            const Color.fromARGB(255, 212, 226, 223), // Color de fondo general de la app
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
        Locale('es', 'US'), // Español (Domingo primer día)
      ],
      // Establece español (con domingo como primer día) como idioma por defecto para toda la app.
      locale: const Locale('es', 'US'),
      home: const PantallaMovimientos(),
    );
  }
}
