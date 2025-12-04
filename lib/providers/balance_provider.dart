import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/movement.dart';

enum Ordenamiento {
  fechaDescendente,
  fechaAscendente,
  alfabeticoAscendente,
  alfabeticoDescendente,
  montoAscendente,
  montoDescendente
}

enum FiltroTipo { todos, efectivo, digital }

enum FiltroOperacion { todos, ingresos, egresos }

enum FiltroPeriodo { todo, hoy, esteMes, esteAnio }

class BalanceProvider with ChangeNotifier {
  late Box<Movement> _cajaMovimientos;
  late Box<double> _cajaSaldos;
  late Box _cajaConfiguracion;
  late Box<String> _cajaPerfiles;

  // Filtros
  FiltroTipo _filtroTipo = FiltroTipo.todos;
  FiltroOperacion _filtroOperacion = FiltroOperacion.todos;
  FiltroPeriodo _filtroPeriodo = FiltroPeriodo.todo;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  String _perfilActual = '';
  List<String> _perfiles = [];

  double _saldoInicialEfectivo = 0.0;
  double _saldoInicialDigital = 0.0;
  bool _esModoOscuro = false;
  String? _rutaDeBackup;
  Ordenamiento _ordenamiento = Ordenamiento.fechaDescendente;

  // Getters públicos
  bool get esModoOscuro => _esModoOscuro;
  String get perfilActual => _perfilActual;
  List<String> get perfiles => _perfiles;
  double get saldoInicialEfectivo => _saldoInicialEfectivo;
  double get saldoInicialDigital => _saldoInicialDigital;
  Ordenamiento get ordenamiento => _ordenamiento;
  double get currentCashBalance => saldoActualEfectivo;
  double get currentDigitalBalance => saldoActualDigital;
  double get currentBalance => saldoActual;

  String? get rutaDeBackup => _rutaDeBackup;
  // Getters para filtros
  FiltroTipo get filtroTipo => _filtroTipo;
  FiltroOperacion get filtroOperacion => _filtroOperacion;
  FiltroPeriodo get filtroPeriodo => _filtroPeriodo;
  DateTime? get fechaInicio => _fechaInicio;
  DateTime? get fechaFin => _fechaFin;

  List<Movement> get movimientos {
    try {
      if (!_cajaMovimientos.isOpen) return [];
      var lista = _cajaMovimientos.values.toList();

      // Aplicar filtro de tipo (efectivo/digital)
      if (_filtroTipo == FiltroTipo.efectivo) {
        lista = lista.where((m) => !m.isDigital).toList();
      } else if (_filtroTipo == FiltroTipo.digital) {
        lista = lista.where((m) => m.isDigital).toList();
      }

      // Aplicar filtro de operación (ingresos/egresos)
      if (_filtroOperacion == FiltroOperacion.ingresos) {
        lista = lista.where((m) => m.amount > 0).toList();
      } else if (_filtroOperacion == FiltroOperacion.egresos) {
        lista = lista.where((m) => m.amount < 0).toList();
      }

      // Aplicar filtro de período
      final now = DateTime.now();
      switch (_filtroPeriodo) {
        case FiltroPeriodo.hoy:
          lista = lista
              .where((m) =>
                  m.date.year == now.year &&
                  m.date.month == now.month &&
                  m.date.day == now.day)
              .toList();
          break;
        case FiltroPeriodo.esteMes:
          lista = lista
              .where(
                  (m) => m.date.year == now.year && m.date.month == now.month)
              .toList();
          break;
        case FiltroPeriodo.esteAnio:
          lista = lista.where((m) => m.date.year == now.year).toList();
          break;
        case FiltroPeriodo.todo:
          // No aplicar filtro
          break;
      }

      // Aplicar filtro de fecha personalizado si está configurado
      if (_fechaInicio != null) {
        lista = lista.where((m) => m.date.isAfter(_fechaInicio!)).toList();
      }
      if (_fechaFin != null) {
        // Hacemos el filtro inclusivo para el día final.
        // Se considera hasta el final del día de _fechaFin.
        final fechaFinInclusiva = _fechaFin!.add(const Duration(days: 1));
        lista = lista.where((m) => m.date.isBefore(fechaFinInclusiva)).toList();
      }

      // Aplicar ordenamiento
      switch (_ordenamiento) {
        case Ordenamiento.fechaDescendente:
          lista.sort((a, b) => b.date.compareTo(a.date));
          break;
        case Ordenamiento.fechaAscendente:
          lista.sort((a, b) => a.date.compareTo(b.date));
          break;
        case Ordenamiento.alfabeticoAscendente:
          lista.sort((a, b) => a.concept.compareTo(b.concept));
          break;
        case Ordenamiento.alfabeticoDescendente:
          lista.sort((a, b) => b.concept.compareTo(a.concept));
          break;
        case Ordenamiento.montoAscendente:
          lista.sort((a, b) => a.amount.compareTo(b.amount));
          break;
        case Ordenamiento.montoDescendente:
          lista.sort((a, b) => b.amount.compareTo(a.amount));
          break;
      }

      return lista;
    } catch (e) {
      return [];
    }
  }

  double get saldoActualEfectivo {
    try {
      if (!_cajaSaldos.isOpen || !_cajaMovimientos.isOpen) return 0.0;
      return _saldoInicialEfectivo +
          _cajaMovimientos.values
              .where((m) => !m.isDigital)
              .fold(0.0, (sum, m) => sum + m.amount);
    } catch (e) {
      return 0.0;
    }
  }

  double get saldoActualDigital {
    try {
      if (!_cajaSaldos.isOpen || !_cajaMovimientos.isOpen) return 0.0;
      return _saldoInicialDigital +
          _cajaMovimientos.values
              .where((m) => m.isDigital)
              .fold(0.0, (sum, m) => sum + m.amount);
    } catch (e) {
      return 0.0;
    }
  }

  double get saldoActual => saldoActualEfectivo + saldoActualDigital;

  Future<void> init() async {
    try {
      _cajaConfiguracion = await Hive.openBox('settings');
      _cajaPerfiles = await Hive.openBox<String>('profiles');

      _rutaDeBackup = _cajaConfiguracion.get('backupPath');
      _esModoOscuro = _cajaConfiguracion.get('isDarkMode', defaultValue: false);
      _ordenamiento = Ordenamiento.values[_cajaConfiguracion.get('sortOrder',
          defaultValue: Ordenamiento.fechaDescendente.index)];

      _perfiles = _cajaPerfiles.values.toList();
      if (_perfiles.isEmpty) {
        _perfilActual = ''; // No hay perfil, la UI forzará la creación.
      } else {
        _perfilActual = _cajaConfiguracion.get('currentProfile',
            defaultValue: _perfiles.first);
      }

      // Asegurarse de que el perfil actual sea válido
      if (_perfiles.isNotEmpty && !_perfiles.contains(_perfilActual)) {
        _perfilActual = _perfiles.first;
      }

      // Solo abrir cajas si hay un perfil válido
      if (_perfilActual.isNotEmpty) {
        _cajaMovimientos =
            await Hive.openBox<Movement>('movements_$_perfilActual');
        _cajaSaldos = await Hive.openBox<double>('balances_$_perfilActual');
        await _cargarDatosIniciales();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error en init: $e');
      rethrow;
    }
  }

  Future<void> _abrirCajasDelPerfil() async {
    try {
      // Comprobamos si la caja está abierta usando Hive.isBoxOpen, que es más seguro
      // que acceder a la variable de instancia directamente si aún no ha sido inicializada.
      final movementsBoxName = 'movements_$_perfilActual';
      if (Hive.isBoxOpen(movementsBoxName)) {
        await _cajaMovimientos.close();
      }
      final balancesBoxName = 'balances_$_perfilActual';
      if (Hive.isBoxOpen(balancesBoxName)) {
        await _cajaSaldos.close();
      }

      _cajaMovimientos =
          await Hive.openBox<Movement>('movements_$_perfilActual');
      _cajaSaldos = await Hive.openBox<double>('balances_$_perfilActual');

      await _cargarDatosIniciales();
      notifyListeners();
    } catch (e) {
      debugPrint('Error al abrir cajas del perfil: $e');
      rethrow;
    }
  }

  Future<void> _cargarDatosIniciales() async {
    _saldoInicialEfectivo = _cajaSaldos.get('cashBalance', defaultValue: 0.0)!;
    _saldoInicialDigital =
        _cajaSaldos.get('digitalBalance', defaultValue: 0.0)!;
  }

  Future<void> _cerrarBoxSiAbierta(String nombreBox) async {
    if (Hive.isBoxOpen(nombreBox)) {
      // Obtenemos la instancia de la caja ya abierta y la cerramos.
      await Hive.box(nombreBox).close();
    }
  }

  void alternarTema() {
    _esModoOscuro = !_esModoOscuro;
    _cajaConfiguracion.put('isDarkMode', _esModoOscuro);
    notifyListeners();
  }

  Future<void> establecerRutaDeBackup(String ruta) async {
    _rutaDeBackup = ruta;
    await _cajaConfiguracion.put('backupPath', ruta);
    notifyListeners();
  }

  void establecerOrdenamiento(Ordenamiento orden) {
    _ordenamiento = orden;
    _cajaConfiguracion.put('sortOrder', _ordenamiento.index);
    notifyListeners();
  }

  Future<void> cambiarPerfil(String nombrePerfil) async {
    if (nombrePerfil == _perfilActual || !_perfiles.contains(nombrePerfil)) {
      return;
    }

    // 1. Cerrar las cajas del perfil actual (el viejo) antes de cambiar.
    if (_cajaMovimientos.isOpen) await _cajaMovimientos.close();
    if (_cajaSaldos.isOpen) await _cajaSaldos.close();

    // 2. Actualizar el nombre del perfil.
    _perfilActual = nombrePerfil;

    // 3. Guardar el nuevo perfil en la configuración.
    await _cajaConfiguracion.put('currentProfile', _perfilActual);

    // 4. Abrir las cajas del nuevo perfil y notificar a la UI.
    await _abrirCajasDelPerfil();
  }

  Future<void> crearPerfil(String nombrePerfil) async {
    final recortado = nombrePerfil.trim();
    if (recortado.isEmpty || _perfiles.contains(recortado)) {
      return;
    }
    await _cajaPerfiles.add(recortado);
    _perfiles.add(recortado);

    // Si es el primer perfil, lo abrimos directamente. Si no, cambiamos a él.
    if (_perfilActual.isEmpty) {
      _perfilActual = recortado;
      await _cajaConfiguracion.put('currentProfile', _perfilActual);
      await _abrirCajasDelPerfil();
    } else {
      await cambiarPerfil(recortado);
    }
  }

  Future<void> editarNombrePerfil(
      String nombreViejo, String nombreNuevo) async {
    final recortado = nombreNuevo.trim();
    if (recortado.isEmpty ||
        nombreViejo == recortado ||
        _perfiles.contains(recortado) ||
        !_perfiles.contains(nombreViejo)) {
      return;
    }

    try {
      // Obtener el índice del perfil viejo en la lista
      final index = _perfiles.indexOf(nombreViejo);

      // Actualizar el nombre en la lista de perfiles
      _perfiles[index] = recortado;

      // Actualizar en la caja de perfiles
      for (var key in _cajaPerfiles.keys) {
        if (_cajaPerfiles.get(key) == nombreViejo) {
          await _cajaPerfiles.put(key, recortado);
          break;
        }
      }

      // --- Lógica de renombrado de archivos de Hive ---

      // 1. Definir nombres y rutas de las cajas
      final oldMovementsBoxName = 'movements_$nombreViejo';
      final oldBalancesBoxName = 'balances_$nombreViejo';
      final newMovementsBoxName = 'movements_$recortado';
      final newBalancesBoxName = 'balances_$recortado';

      final path = (await getApplicationDocumentsDirectory()).path;

      // 2. Cerrar las cajas si están abiertas para liberar los archivos
      // Si estamos renombrando el perfil actual, cerramos las cajas que el provider tiene abiertas.
      if (_perfilActual == nombreViejo) {
        if (_cajaMovimientos.isOpen) await _cajaMovimientos.close();
        if (_cajaSaldos.isOpen) await _cajaSaldos.close();
      } else {
        // Si es otro perfil, nos aseguramos de que las cajas no estén abiertas por alguna otra razón.
        await _cerrarBoxSiAbierta(oldMovementsBoxName);
        await _cerrarBoxSiAbierta(oldBalancesBoxName);
      }

      // 3. Renombrar los archivos .hive y .lock directamente
      String? oldMovementsPath;
      String? oldBalancesPath;

      if (_perfilActual == nombreViejo && _cajaMovimientos.isOpen) {
        oldMovementsPath = _cajaMovimientos.path;
      } else {
        final exactFile = File('$path/$oldMovementsBoxName.hive');
        final lowerFile =
            File('$path/${oldMovementsBoxName.toLowerCase()}.hive');
        if (await exactFile.exists()) {
          oldMovementsPath = exactFile.path;
        } else if (await lowerFile.exists()) {
          oldMovementsPath = lowerFile.path;
        }
      }

      if (_perfilActual == nombreViejo && _cajaSaldos.isOpen) {
        oldBalancesPath = _cajaSaldos.path;
      } else {
        final exactFile = File('$path/$oldBalancesBoxName.hive');
        final lowerFile =
            File('$path/${oldBalancesBoxName.toLowerCase()}.hive');
        if (await exactFile.exists()) {
          oldBalancesPath = exactFile.path;
        } else if (await lowerFile.exists()) {
          oldBalancesPath = lowerFile.path;
        }
      }

      if (oldMovementsPath != null) {
        final oldFile = File(oldMovementsPath);
        String newFilename;

        // Determinar convención de nombres basada en el archivo viejo
        if (oldMovementsPath
            .endsWith('${oldMovementsBoxName.toLowerCase()}.hive')) {
          newFilename = '${newMovementsBoxName.toLowerCase()}.hive';
        } else {
          newFilename = '$newMovementsBoxName.hive';
        }

        final newPath = '$path/$newFilename';
        await oldFile.rename(newPath);

        final oldLockPath = oldMovementsPath.replaceAll('.hive', '.lock');
        final oldLockFile = File(oldLockPath);
        if (await oldLockFile.exists()) {
          final newLockFilename = newFilename.replaceAll('.hive', '.lock');
          await oldLockFile.rename('$path/$newLockFilename');
        }
      }

      if (oldBalancesPath != null) {
        final oldFile = File(oldBalancesPath);
        String newFilename;

        if (oldBalancesPath
            .endsWith('${oldBalancesBoxName.toLowerCase()}.hive')) {
          newFilename = '${newBalancesBoxName.toLowerCase()}.hive';
        } else {
          newFilename = '$newBalancesBoxName.hive';
        }

        final newPath = '$path/$newFilename';
        await oldFile.rename(newPath);

        final oldLockPath = oldBalancesPath.replaceAll('.hive', '.lock');
        final oldLockFile = File(oldLockPath);
        if (await oldLockFile.exists()) {
          final newLockFilename = newFilename.replaceAll('.hive', '.lock');
          await oldLockFile.rename('$path/$newLockFilename');
        }
      }

      // 4. Si el perfil renombrado es el que estaba activo, actualizamos el nombre y la configuración.
      // IMPORTANTE: Hacemos esto DESPUÉS de renombrar los archivos exitosamente.
      if (_perfilActual == nombreViejo) {
        _perfilActual = recortado;
        await _cajaConfiguracion.put('currentProfile', recortado);
        // Reabrimos las cajas con el nuevo nombre
        await _abrirCajasDelPerfil();
      }

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> eliminarPerfil(String nombrePerfil) async {
    if (_perfiles.isEmpty || !_perfiles.contains(nombrePerfil)) return;

    final movementsBoxName = 'movements_$nombrePerfil';
    final balancesBoxName = 'balances_$nombrePerfil';

    try {
      // 1. Determinar cuál será el próximo perfil activo
      String? proximoPerfilActivo;
      bool seEliminaElPerfilActual = _perfilActual == nombrePerfil;

      if (seEliminaElPerfilActual) {
        if (_perfiles.length > 1) {
          // Si hay más perfiles, el próximo será el primero que no sea el que se elimina.
          proximoPerfilActivo = _perfiles.firstWhere((p) => p != nombrePerfil);
        } else {
          // Si se elimina el último perfil, no habrá próximo perfil.
          proximoPerfilActivo = null;
        }
      }

      // 2. Cerrar las cajas del perfil a eliminar (si están abiertas)
      // Esto es crucial si el perfil a eliminar no es el activo.
      if (seEliminaElPerfilActual) {
        // Si es el perfil actual, cerramos las instancias que el provider ya conoce.
        if (_cajaMovimientos.isOpen) await _cajaMovimientos.close();
        if (_cajaSaldos.isOpen) await _cajaSaldos.close();
      } else {
        // Si es otro perfil, usamos el método genérico para cerrarlas.
        await _cerrarBoxSiAbierta(movementsBoxName);
        await _cerrarBoxSiAbierta(balancesBoxName);
      }

      // 3. Eliminar los archivos de las cajas del disco
      await Hive.deleteBoxFromDisk(movementsBoxName);
      await Hive.deleteBoxFromDisk(balancesBoxName);

      // 4. Eliminar el perfil de la lista en memoria y de la caja de perfiles en disco
      _perfiles.remove(nombrePerfil);
      for (var key in _cajaPerfiles.keys) {
        if (_cajaPerfiles.get(key) == nombrePerfil) {
          await _cajaPerfiles.delete(key);
          break;
        }
      }

      // 5. Si se eliminó el perfil actual, cambiar al nuevo perfil activo
      if (seEliminaElPerfilActual) {
        _perfilActual = proximoPerfilActivo ?? '';
        await _cajaConfiguracion.put('currentProfile', _perfilActual);

        // Si hay un nuevo perfil, ábrelo. Si no (era el último), las cajas
        // permanecerán cerradas y el provider en un estado "vacío" seguro.
        if (proximoPerfilActivo != null) {
          await _abrirCajasDelPerfil();
        }
        // Si proximoPerfilActivo es null, no hacemos nada, la UI se encargará
        // de pedir un nuevo perfil.
      }
    } catch (e) {
      debugPrint('Error al eliminar perfil: $e');
      rethrow;
    }
  }

  Future<void> agregarMovimiento(Movement movimiento) async {
    await _cajaMovimientos.add(movimiento);
    notifyListeners();
  }

  Future<void> editarMovimiento(dynamic key, Movement nuevoMovimiento) async {
    // Usamos la clave única del objeto Hive para asegurar que editamos el correcto.
    if (_cajaMovimientos.containsKey(key)) {
      await _cajaMovimientos.put(key, nuevoMovimiento);
      notifyListeners();
    }
  }

  Future<void> eliminarMovimiento(dynamic key) async {
    // Usamos la clave única del objeto Hive para asegurar que eliminamos el correcto.
    if (_cajaMovimientos.containsKey(key)) {
      await _cajaMovimientos.delete(key);
      notifyListeners();
    }
  }

  Future<void> limpiarMovimientos() async {
    await _cajaMovimientos.clear();
    notifyListeners();
  }

  Future<void> establecerSaldoInicialEfectivo(double saldo) async {
    _saldoInicialEfectivo = saldo;
    await _cajaSaldos.put('cashBalance', saldo);
    notifyListeners();
  }

  Future<void> establecerSaldoInicialDigital(double saldo) async {
    _saldoInicialDigital = saldo;
    await _cajaSaldos.put('digitalBalance', saldo);
    notifyListeners();
  }

  // Métodos para establecer filtros
  void establecerFiltroTipo(FiltroTipo tipo) {
    _filtroTipo = tipo;
    notifyListeners();
  }

  void establecerFiltroOperacion(FiltroOperacion operacion) {
    _filtroOperacion = operacion;
    notifyListeners();
  }

  void establecerFiltroPeriodo(FiltroPeriodo periodo) {
    _filtroPeriodo = periodo;
    _fechaInicio = null;
    _fechaFin = null;
    notifyListeners();
  }

  void establecerFiltroFechaPersonalizado(DateTime inicio, DateTime fin) {
    _filtroPeriodo = FiltroPeriodo.todo;
    _fechaInicio = inicio;
    _fechaFin = fin;
    notifyListeners();
  }

  void limpiarFiltros() {
    _filtroTipo = FiltroTipo.todos;
    _filtroOperacion = FiltroOperacion.todos;
    _filtroPeriodo = FiltroPeriodo.todo;
    _fechaInicio = null;
    _fechaFin = null;
    notifyListeners();
  }

  Future<String> exportProfileBackup(String profile,
      {String? outputPath}) async {
    if (!_perfiles.contains(profile)) {
      throw Exception('El perfil $profile no existe');
    }

    final Map<String, dynamic> data = {};
    final movementsBoxName = 'movements_$profile';
    final balancesBoxName = 'balances_$profile';
    final String finalOutputPath = outputPath ??
        _rutaDeBackup ??
        (await getApplicationDocumentsDirectory()).path;

    try {
      // Exportar movimientos
      if (await Hive.boxExists(movementsBoxName)) {
        Box<Movement> box;
        bool needsClosing = false;

        if (Hive.isBoxOpen(movementsBoxName)) {
          box = Hive.box<Movement>(movementsBoxName);
        } else {
          box = await Hive.openBox<Movement>(movementsBoxName);
          needsClosing = true;
        }

        data['movements'] = box.values.map((m) {
          return {
            'date': m.date.toIso8601String(),
            'concept': m.concept,
            'amount': m.amount,
            'isDigital': m.isDigital,
          };
        }).toList();

        if (needsClosing) {
          await box.close();
        }
      } else {
        data['movements'] = [];
      }

      // Exportar saldos
      if (await Hive.boxExists(balancesBoxName)) {
        Box<double> box;
        bool needsClosing = false;

        if (Hive.isBoxOpen(balancesBoxName)) {
          box = Hive.box<double>(balancesBoxName);
        } else {
          box = await Hive.openBox<double>(balancesBoxName);
          needsClosing = true;
        }

        final Map<String, dynamic> balancesMap = {};
        for (var key in box.keys) {
          balancesMap[key.toString()] = box.get(key);
        }
        data['balances'] = balancesMap;

        if (needsClosing) {
          await box.close();
        }
      } else {
        data['balances'] = {};
      }

      data['profile'] = profile;
      data['exportedAt'] = DateTime.now().toIso8601String();

      final filename =
          'gastos_backup_${profile}_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('$finalOutputPath/$filename');
      await file.writeAsString(jsonEncode(data));
      return file.path;
    } catch (e) {
      debugPrint('Error al exportar backup: $e');
      rethrow;
    }
  }

  Future<void> importProfileBackup(String jsonString) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonString);

      // 1. Validar la estructura del JSON
      if (data['profile'] == null ||
          data['movements'] == null ||
          data['balances'] == null) {
        throw Exception('El archivo de backup no es válido o está corrupto.');
      }

      // 2. Manejar nombres de perfil duplicados
      String originalName = data['profile'];
      String profileName = originalName;
      int counter = 1;
      while (_perfiles.contains(profileName)) {
        profileName = '$originalName (${counter++})';
      }

      // 3. Crear y cambiar al nuevo perfil
      await crearPerfil(profileName);

      // 4. Importar los movimientos
      final List<dynamic> movementsData = data['movements'];
      final List<Movement> newMovements = movementsData.map((m) {
        return Movement(
          date: DateTime.parse(m['date']),
          concept: m['concept'],
          amount: (m['amount'] as num).toDouble(),
          isDigital: m['isDigital'],
        );
      }).toList();

      // Asegurarse de que la caja de movimientos del nuevo perfil esté abierta
      final movementsBox = Hive.box<Movement>('movements_$profileName');
      await movementsBox.addAll(newMovements);

      // 5. Importar los saldos iniciales
      final Map<String, dynamic> balancesData = data['balances'];
      final balancesBox = Hive.box<double>('balances_$profileName');

      final double cashBalance =
          (balancesData['cashBalance'] as num?)?.toDouble() ?? 0.0;
      final double digitalBalance =
          (balancesData['digitalBalance'] as num?)?.toDouble() ?? 0.0;

      await balancesBox.put('cashBalance', cashBalance);
      await balancesBox.put('digitalBalance', digitalBalance);

      // 6. Recargar los datos del perfil recién importado
      await _cargarDatosIniciales();

      // Notificar a la UI para que se actualice
      notifyListeners();
    } on FormatException {
      throw Exception('El formato del archivo JSON es incorrecto.');
    } catch (e) {
      // Re-lanzar cualquier otra excepción para que la UI la maneje
      rethrow;
    }
  }
}
