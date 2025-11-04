import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
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
    var lista = _cajaMovimientos.values.toList();

    // Aplicar filtro de tipo (efectivo/digital)
    if (_filtroTipo != FiltroTipo.todos) {
      lista = lista
          .where((m) =>
              _filtroTipo == FiltroTipo.efectivo ? !m.isDigital : m.isDigital)
          .toList();
    }

    // Aplicar filtro de operación (ingresos/egresos)
    if (_filtroOperacion != FiltroOperacion.todos) {
      lista = lista
          .where((m) => _filtroOperacion == FiltroOperacion.ingresos
              ? m.amount > 0
              : m.amount < 0)
          .toList();
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
            .where((m) => m.date.year == now.year && m.date.month == now.month)
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
  }

  double get saldoActualEfectivo {
    return _saldoInicialEfectivo +
        _cajaMovimientos.values
            .where((m) => !m.isDigital)
            .fold(0.0, (sum, m) => sum + m.amount);
  }

  double get saldoActualDigital {
    return _saldoInicialDigital +
        _cajaMovimientos.values
            .where((m) => m.isDigital)
            .fold(0.0, (sum, m) => sum + m.amount);
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
        // Si no hay perfiles, creamos uno por defecto para evitar errores.
        await crearPerfil('Principal');
        _perfilActual = 'Principal';
      } else {
        _perfilActual = _cajaConfiguracion.get('currentProfile',
            defaultValue: _perfiles.first);
      }

      // Asegurarse de que el perfil actual sea válido
      if (_perfiles.isNotEmpty && !_perfiles.contains(_perfilActual)) {
        _perfilActual = _perfiles.first;
      }
      // Inicializar las cajas antes de abrir el perfil
      _cajaMovimientos =
          await Hive.openBox<Movement>('movements_$_perfilActual');
      _cajaSaldos = await Hive.openBox<double>('balances_$_perfilActual');

      await _cargarDatosIniciales();
      notifyListeners();
    } catch (e) {
      debugPrint('Error en init: $e');
      rethrow;
    }
  }

  Future<void> _abrirCajasDelPerfil() async {
    try {
      if (_cajaMovimientos.isOpen) {
        await _cajaMovimientos.close();
      }
      if (_cajaSaldos.isOpen) {
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
      final box = Hive.box(nombreBox);
      if (box.isOpen) {
        await box.close();
      }
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
    _perfilActual = nombrePerfil;
    await _cajaConfiguracion.put('currentProfile', _perfilActual);
    await _abrirCajasDelPerfil();
  }

  Future<void> crearPerfil(String nombrePerfil) async {
    final recortado = nombrePerfil.trim();
    if (recortado.isEmpty || _perfiles.contains(recortado)) {
      return;
    }
    await _cajaPerfiles.add(recortado);
    _perfiles.add(recortado);
    // Siempre cambiamos al perfil recién creado para asegurar que las cajas se abran correctamente.
    await cambiarPerfil(recortado);
    notifyListeners();
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

      // Si es el perfil actual, actualizar el nombre y la configuración
      if (_perfilActual == nombreViejo) {
        _perfilActual = recortado;
        await _cajaConfiguracion.put('currentProfile', recortado);
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
      if (_perfilActual == recortado) {
        if (_cajaMovimientos.isOpen) await _cajaMovimientos.close();
        if (_cajaSaldos.isOpen) await _cajaSaldos.close();
      } else {
        // Si es otro perfil, nos aseguramos de que las cajas no estén abiertas por alguna otra razón.
        await _cerrarBoxSiAbierta(oldMovementsBoxName);
        await _cerrarBoxSiAbierta(oldBalancesBoxName);
      }

      // 3. Renombrar los archivos .hive y .lock directamente
      final oldMovementsFile = File('$path/$oldMovementsBoxName.hive');
      if (await oldMovementsFile.exists()) {
        await oldMovementsFile.rename('$path/$newMovementsBoxName.hive');
      }
      final oldMovementsLockFile = File('$path/$oldMovementsBoxName.lock');
      if (await oldMovementsLockFile.exists()) {
        await oldMovementsLockFile.rename('$path/$newMovementsBoxName.lock');
      }

      final oldBalancesFile = File('$path/$oldBalancesBoxName.hive');
      if (await oldBalancesFile.exists()) {
        await oldBalancesFile.rename('$path/$newBalancesBoxName.hive');
      }
      final oldBalancesLockFile = File('$path/$oldBalancesBoxName.lock');
      if (await oldBalancesLockFile.exists()) {
        await oldBalancesLockFile.rename('$path/$newBalancesBoxName.lock');
      }

      // 4. Si el perfil renombrado es el que estaba activo, lo reabrimos con su nuevo nombre.
      if (_perfilActual == recortado) {
        await _abrirCajasDelPerfil();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error al editar nombre de perfil: $e');
      rethrow;
    }
  }

  Future<void> eliminarPerfil(String nombrePerfil) async {
    if (_perfiles.isEmpty || !_perfiles.contains(nombrePerfil)) return;

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
      final movementsBoxName = 'movements_$nombrePerfil';
      final balancesBoxName = 'balances_$nombrePerfil';
      await _cerrarBoxSiAbierta(movementsBoxName);
      await _cerrarBoxSiAbierta(balancesBoxName);

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

      notifyListeners();
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

  Future<String> exportarAPdf() async => exportToPdf();

  Future<String> exportToPdf() async {
    // Cargar las fuentes TTF desde los assets
    final fontData = await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
    final boldFontData = await rootBundle.load("assets/fonts/Roboto-Bold.ttf");
    final ttf = pw.Font.ttf(fontData.buffer.asByteData());
    final boldTtf = pw.Font.ttf(boldFontData.buffer.asByteData());

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: ttf,
        bold: boldTtf,
      ),
    );
    final generationDate = DateTime.now();
    // Usamos la lista completa de movimientos, ignorando los filtros de la UI.
    final todosLosMovimientos = _cajaMovimientos.values.toList();
    // Opcional: Ordenar la lista para el reporte, por ejemplo, por fecha descendente.
    todosLosMovimientos.sort((a, b) => b.date.compareTo(a.date));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        header: (pw.Context context) {
          // Este widget se repetirá en la parte superior de cada página.
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text('Reporte de Movimientos',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Text(
                'Perfil: $_perfilActual',
                style: const pw.TextStyle(fontSize: 16),
              ),
              pw.Text(
                  'Generado: ${generationDate.day}/${generationDate.month}/${generationDate.year} a las ${generationDate.hour}:${generationDate.minute.toString().padLeft(2, '0')}'),
              pw.SizedBox(height: 20),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                          'Saldo Inicial Efectivo: \$${_saldoInicialEfectivo.toStringAsFixed(2)}'),
                      pw.Text(
                          'Saldo Actual Efectivo: \$${saldoActualEfectivo.toStringAsFixed(2)}'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                          'Saldo Inicial Digital: \$${_saldoInicialDigital.toStringAsFixed(2)}'),
                      pw.Text(
                          'Saldo Actual Digital: \$${saldoActualDigital.toStringAsFixed(2)}'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
            ],
          );
        },
        footer: (pw.Context context) {
          // Este widget se repetirá en la parte inferior de cada página.
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
            child: pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: pw.Theme.of(context)
                  .defaultTextStyle
                  .copyWith(color: PdfColors.grey),
            ),
          );
        },
        build: (pw.Context context) {
          // Esta es una lista de widgets que formarán el cuerpo principal del documento.
          // La librería se encargará de distribuirlos en las páginas necesarias.
          return [
            pw.Table(
              // 1. Bordes para toda la tabla
              border: pw.TableBorder.all(color: PdfColors.grey600),

              // 2. Anchos de columna flexibles
              columnWidths: const {
                0: pw.FlexColumnWidth(2), // Fecha
                1: pw.FlexColumnWidth(4), // Concepto
                2: pw.FlexColumnWidth(2), // Tipo
                3: pw.FlexColumnWidth(2.5), // Monto
              },

              // 3. Construcción de la tabla
              children: [
                // 3.1 Fila del Encabezado con estilo
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  children: [
                    _buildHeaderCell('Fecha'),
                    _buildHeaderCell('Concepto'),
                    _buildHeaderCell('Tipo'),
                    _buildHeaderCell('Monto',
                        alignment: pw.Alignment.centerRight),
                  ],
                ),

                // 3.2 Filas de datos
                // Usamos un bucle 'for' dentro de la lista para generar cada fila.
                for (final entry in todosLosMovimientos.asMap().entries)
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      // Alternamos el color de la fila usando el índice (entry.key)
                      color: entry.key % 2 == 0
                          ? PdfColors.white
                          : PdfColors.grey100,
                    ),
                    children: [
                      _buildCell(
                          '${entry.value.date.day}/${entry.value.date.month}/${entry.value.date.year}'),
                      _buildCell(entry.value.concept),
                      _buildCell(
                          entry.value.isDigital ? 'Digital' : 'Efectivo'),
                      _buildCell('\$${entry.value.amount.toStringAsFixed(2)}',
                          alignment: pw.Alignment.centerRight),
                    ],
                  )
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text(
                  'Total: \$${saldoActual.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ];
        },
      ), // Fin de MultiPage
    );

    final formattedDateTime =
        "${generationDate.year}${generationDate.month.toString().padLeft(2, '0')}${generationDate.day.toString().padLeft(2, '0')}_${generationDate.hour.toString().padLeft(2, '0')}${generationDate.minute.toString().padLeft(2, '0')}${generationDate.second.toString().padLeft(2, '0')}";
    final output = await getApplicationDocumentsDirectory();
    final file = File(
        '${output.path}/movimientos_${_perfilActual}_$formattedDateTime.pdf');
    await file.writeAsBytes(await pdf.save());

    // Añadimos una pequeña demora para asegurar que el sistema de archivos
    // haya liberado el archivo antes de intentar abrirlo. Esto previene
    // condiciones de carrera, especialmente con archivos grandes.
    await Future.delayed(const Duration(milliseconds: 200));

    final result = await OpenFile.open(file.path);

    // Opcional: Manejar el caso en que el archivo no se pueda abrir.
    if (result.type != ResultType.done) {
      // Si no se pudo abrir (ej. no hay visor de PDF), lanzamos una excepción
      // para que la UI pueda informar al usuario.
      throw Exception(
          'No se pudo abrir el archivo PDF automáticamente: ${result.message}');
    }

    return file.path;
  }

  // --- Funciones de ayuda para construir celdas de la tabla PDF ---

  pw.Widget _buildHeaderCell(String text,
      {pw.Alignment alignment = pw.Alignment.centerLeft}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        textAlign: _getpwTextAlign(alignment),
      ),
    );
  }

  pw.Widget _buildCell(String text,
      {pw.Alignment alignment = pw.Alignment.centerLeft}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        textAlign: _getpwTextAlign(alignment),
      ),
    );
  }

  pw.TextAlign _getpwTextAlign(pw.Alignment alignment) {
    if (alignment == pw.Alignment.center) return pw.TextAlign.center;
    if (alignment == pw.Alignment.centerRight) return pw.TextAlign.right;
    return pw.TextAlign.left;
  }
}
