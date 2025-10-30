import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gastos/models/movement.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io'; // Importar la librería dart:io para la clase File
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/balance_provider.dart';
import 'package:open_file/open_file.dart';

final _formatoNumero = NumberFormat.decimalPattern('es_ES');

class PantallaMovimientos extends StatefulWidget {
  const PantallaMovimientos({super.key});

  @override
  State<PantallaMovimientos> createState() => _PantallaMovimientosState();
}

class _PantallaMovimientosState extends State<PantallaMovimientos> {
  @override
  void initState() {
    super.initState();
    // Si después de la inicialización no hay perfil, forzamos la creación de uno.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<BalanceProvider>(context, listen: false);
      if (provider.perfilActual.isEmpty) {
        _mostrarDialogoCrearPerfil(context, canCancel: false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const _PerfilesDrawer(),
      appBar: AppBar(
        title: const Text('Movimientos'),
        actions: [
          // Botón exportar PDF
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              _showLoadingDialog(context, "Generando PDF...");
              final messenger = ScaffoldMessenger.of(context);
              final provider =
                  Provider.of<BalanceProvider>(context, listen: false);

              try {
                final path = await provider.exportarAPdf();
                if (!context.mounted) return;
                Navigator.pop(context); // Cierra diálogo de carga

                messenger.showSnackBar(SnackBar(
                  content: Text('PDF generado: $path'),
                  action: SnackBarAction(
                    label: 'Abrir',
                    onPressed: () => OpenFile.open(path),
                  ),
                ));
              } catch (e) {
                if (!context.mounted) return;
                Navigator.pop(context); // Cierra diálogo de carga
                messenger.showSnackBar(SnackBar(
                  content: Text('Error al generar PDF: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ));
              }
            },
            tooltip: 'Exportar PDF',
          ),
          // Botón de filtros (eliminado para simplificar, se puede añadir de nuevo si es necesario)
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              Provider.of<BalanceProvider>(context, listen: false)
                  .alternarTema();
            },
            tooltip: 'Cambiar tema',
          ),
        ],
      ),
      body: Column(
        children: [
          const _SaldosCard(),
          const _FormularioAgregarMovimiento(),
          const _ListaMovimientos(),
          // Total general (ahora dentro de _SaldosCard)
        ],
      ),
    );
  }
}

// --- WIDGETS EXTRAÍDOS ---

class _PerfilesDrawer extends StatelessWidget {
  const _PerfilesDrawer();

  @override
  Widget build(BuildContext context) {
    final balanceProvider = Provider.of<BalanceProvider>(context);
    final perfiles = balanceProvider.perfiles;

    return Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: SizedBox(
                width: double.infinity,
                child: Center(
                  child: Text(
                    'Perfiles',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/isla.jpg',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color.fromRGBO(0, 0, 0, 0.55)
                          : const Color.fromRGBO(255, 255, 255, 0.65),
                    ),
                  ),
                  ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      ...perfiles.map(
                        (profile) => _PerfilListTile(
                          title: Text(
                            profile,
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: profile == balanceProvider.perfilActual,
                          selectedTileColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(77),
                          profile: profile,
                          onTap: () {
                            balanceProvider.cambiarPerfil(profile);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.add),
                        title: const Text('Crear perfil'),
                        onTap: () => _mostrarDialogoCrearPerfil(context),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.file_upload),
                        title: const Text('Restaurar Backup'),
                        onTap: () => _importarBackup(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      
    );
  }
}
class _PerfilListTile extends StatelessWidget {
  final Widget title;
  final bool selected;
  final Color selectedTileColor;
  final VoidCallback onTap;
  final String profile;

  const _PerfilListTile({
    required this.title,
    required this.selected,
    required this.selectedTileColor,
    required this.onTap,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: title,
      selected: selected,
      selectedTileColor: selectedTileColor,
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            tooltip: 'Exportar backup',
            onPressed: () => _exportarBackup(context, profile),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar nombre',
            onPressed: () {
              Navigator.pop(context); // Close drawer
              _mostrarDialogoEditarPerfil(context, profile);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Eliminar perfil',
            onPressed: () => _eliminarPerfil(context, profile),
          ),
        ],
      ),
    );
  }
}

class _SaldosCard extends StatelessWidget {
  const _SaldosCard();

  @override
  Widget build(BuildContext context) {
    final balanceProvider = Provider.of<BalanceProvider>(context);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Efectivo
          InkWell(
            onTap: () => _mostrarDialogoEditarSaldoInicial(context, true),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.money, color: Colors.green),
                      SizedBox(width: 8),
                      Text("Efectivo", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Inicial: \$${_formatoNumero.format(balanceProvider.saldoInicialEfectivo)}",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "\$${_formatoNumero.format(balanceProvider.saldoActualEfectivo)}",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          color: balanceProvider.currentCashBalance >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // Digital
          InkWell(
            onTap: () => _mostrarDialogoEditarSaldoInicial(context, false),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.blue),
                      SizedBox(width: 8),
                      Text("Digital", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Inicial: \$${_formatoNumero.format(balanceProvider.saldoInicialDigital)}",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "\$${_formatoNumero.format(balanceProvider.saldoActualDigital)}",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          color: balanceProvider.currentDigitalBalance >= 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // Total
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text("TOTAL",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text(
                  "\$${_formatoNumero.format(balanceProvider.saldoActual)}",
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: balanceProvider.currentBalance >= 0
                        ? Colors.green
                        : Colors.red,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormularioAgregarMovimiento extends StatefulWidget {
  const _FormularioAgregarMovimiento();

  @override
  State<_FormularioAgregarMovimiento> createState() =>
      __FormularioAgregarMovimientoState();
}

class __FormularioAgregarMovimientoState
    extends State<_FormularioAgregarMovimiento> {
  final _controladorConcepto = TextEditingController();
  final _controladorMonto = TextEditingController();
  bool _esMovimientoDigital = false;

  @override
  void dispose() {
    _controladorConcepto.dispose();
    _controladorMonto.dispose();
    super.dispose();
  }

  void _agregarMovimiento() {
    final balanceProvider =
        Provider.of<BalanceProvider>(context, listen: false);
    final concept = _controladorConcepto.text;
    final amount =
        double.tryParse(_controladorMonto.text.replaceAll(',', '.')) ?? 0.0;

    if (concept.isNotEmpty) {
      balanceProvider.agregarMovimiento(
        Movement(
          date: DateTime.now(),
          concept: concept,
          amount: amount,
          isDigital: _esMovimientoDigital,
        ),
      );

      setState(() {
        _controladorConcepto.clear();
        _controladorMonto.clear();
        FocusScope.of(context).unfocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                TextField(
                  controller: _controladorConcepto,
                  decoration: const InputDecoration(
                    labelText: "Concepto",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(
                        controller: _controladorMonto,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true, signed: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9\.\-]'))
                        ],
                        decoration: const InputDecoration(
                          labelText: "Monto (+ ingreso, - gasto)",
                          border: OutlineInputBorder(),
                          prefixText: "\$",
                          helperText: "Usa coma para decimales",
                        ),),
                    ),
                    const SizedBox(width: 10),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: false,
                          icon: Tooltip(
                            message: 'Efectivo',
                            child: Icon(Icons.money,
                                color: Colors.green, size: 28),
                          ),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          icon: Tooltip(
                            message: 'Digital',
                            child: Icon(Icons.account_balance_wallet,
                                color: Colors.blue, size: 28),
                          ),
                        ),
                      ],
                      selected: {_esMovimientoDigital},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setState(() {
                          _esMovimientoDigital = newSelection.first;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _agregarMovimiento,
                        child: const Text("Agregar movimiento"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('¿Borrar todos los movimientos?'),
                            content: const Text(
                              'Esta acción no se puede deshacer y eliminará todos los movimientos. Los saldos iniciales se mantendrán.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () { 
                                  final balanceProvider = Provider.of<BalanceProvider>(context, listen: false);
                                  balanceProvider.limpiarMovimientos();
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Todos los movimientos han sido eliminados'),
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                    foregroundColor: Colors.red),
                                child: const Text('Borrar'),
                              ),
                            ],
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Icon(Icons.delete_forever),
                    ),
                  ],
                ),
              ],
            ),
          );
  }
}

class _ListaMovimientos extends StatelessWidget {
  const _ListaMovimientos();

  @override
  Widget build(BuildContext context) {
    final balanceProvider = Provider.of<BalanceProvider>(context);

    return Expanded(
            child: Stack(
              children: [
                // Imagen de fondo
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/frieren.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
                // Capa semitransparente para mejorar contraste
                Positioned.fill(
                  child: Container(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color.fromRGBO(0, 0, 0, 0.45)
                        : const Color.fromRGBO(255, 255, 255, 0.35),
                  ),
                ),
                // Lista de movimientos encima
                Positioned.fill(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8),
                    itemCount: balanceProvider.movimientos.length,
                    itemBuilder: (context, index) {
                      final movement = balanceProvider.movimientos[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        // Hacemos la tarjeta semi-transparente para que se vea
                        // la imagen de fondo de la lista.
                        color: Theme.of(context).brightness == Brightness.dark
                            ? const Color.fromRGBO(0, 0, 0, 0.25)
                            : const Color.fromRGBO(255, 255, 255, 0.55),
                        elevation: 1,
                        child: InkWell(
                          onLongPress: () =>
                              _mostrarDialogoEditarMovimiento(context, movement),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                // Fecha y tipo de movimiento
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: (movement.isDigital
                                            ? Colors.blue
                                            : Colors.green)
                                        .withAlpha(balanceProvider.esModoOscuro ? 51
                                            : 26),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "${movement.date.day}/${movement.date.month}",
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Icon(
                                        movement.isDigital
                                            ? Icons.account_balance_wallet
                                            : Icons.money,
                                        color: movement.isDigital
                                            ? Colors.blue
                                            : Colors.green,
                                        size: 16,
                                      ),
                                      Text(
                                        movement.isDigital
                                            ? 'Digital'
                                            : 'Efectivo',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: movement.isDigital
                                              ? Colors.blue
                                              : Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Concepto y monto
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              movement.concept,
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                            Text(
                                              'Mantén presionado para editar',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        "\$${_formatoNumero.format(movement.amount)}",
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: movement.amount >= 0
                                                ? Colors.green
                                                : Colors.red,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
  }
}

// --- FUNCIONES DE DIÁLOGO Y LÓGICA DE BOTONES (fuera de las clases de widget) ---

void _showLoadingDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    barrierDismissible:
        false, // El usuario no puede cerrar el diálogo tocando fuera
    builder: (BuildContext context) {
      return AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 24),
            Text(message),
          ],
        ),
      );
    },
  );
}

Future<void> _importarBackup(BuildContext context) async {
  // 1. Usar file_picker para seleccionar un archivo JSON
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
  );

  if (result != null && result.files.single.path != null) {
    // Asegurarse de que el widget sigue montado antes de usar el context.
    if (!context.mounted) return;

    // Guardamos la referencia al ScaffoldMessenger antes de la pausa asíncrona.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    _showLoadingDialog(context, "Restaurando backup...");

    try {
      final provider = Provider.of<BalanceProvider>(context, listen: false);
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();

      // Ahora usamos la referencia al provider que obtuvimos antes del await.
      await provider.importProfileBackup(jsonString);

      // 3. Cerrar diálogo y mostrar mensaje de éxito
      if (navigator.canPop()) {
        navigator.pop(); // Cierra el diálogo de carga
      }
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Backup restaurado con éxito.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // 4. Cerrar diálogo y mostrar mensaje de error
      if (navigator.canPop()) {
        navigator.pop(); // Cierra el diálogo de carga
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al restaurar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

void _mostrarDialogoCrearPerfil(BuildContext context, {bool canCancel = true}) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    barrierDismissible: canCancel,
    builder: (context) => AlertDialog(
      title: const Text('Crear nuevo perfil'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(labelText: 'Nombre del perfil'),
        autofocus: true,
        textCapitalization: TextCapitalization.words,
      ),
      actions: [
        if (canCancel)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        TextButton(
          onPressed: () {
            final name = controller.text;
            if (name.isNotEmpty) {
              Provider.of<BalanceProvider>(context, listen: false)
                  .crearPerfil(name);
              Navigator.pop(context); // Cierra diálogo
            }
          },
          child: const Text('Crear'),
        ),
      ],
    ),
  );
}

void _mostrarDialogoEditarPerfil(BuildContext context, String oldProfileName) {
  final controller = TextEditingController(text: oldProfileName);
  controller.selection =
      TextSelection(baseOffset: 0, extentOffset: controller.text.length);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Editar nombre del perfil'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(labelText: 'Nuevo nombre'),
        autofocus: true,
        textCapitalization: TextCapitalization.words,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            final newName = controller.text;
            Provider.of<BalanceProvider>(context, listen: false)
                .editarNombrePerfil(oldProfileName, newName);
            Navigator.pop(context);
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}

Future<void> _exportarBackup(BuildContext context, String profile) async {
  final bp = Provider.of<BalanceProvider>(context, listen: false);
  final messenger = ScaffoldMessenger.of(context);
  String? outputPath = bp.rutaDeBackup;

  if (outputPath == null) {
    outputPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Selecciona una carpeta para guardar el backup',
    );

    if (outputPath == null) {
      messenger.showSnackBar(const SnackBar(
          content: Text(
              'Exportación cancelada. No se seleccionó ninguna carpeta.')));
      return;
    }
    await bp.establecerRutaDeBackup(outputPath);
  }

  messenger.showSnackBar(SnackBar(
    content: Text('Generando backup para "$profile"...'),
  ));

  try {
    final path = await bp.exportProfileBackup(profile);
    messenger.showSnackBar(
      SnackBar(
        content: Text('Backup guardado en: $path'),
        duration: const Duration(seconds: 4),
      ),
    );
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('Error al exportar backup: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

Future<void> _eliminarPerfil(BuildContext context, String profile) async {
  // Capturamos el contexto principal de la pantalla de forma segura.
  final mainScreenContext = context;
  final messenger = ScaffoldMessenger.of(mainScreenContext);
  final bp = Provider.of<BalanceProvider>(mainScreenContext, listen: false);

  Navigator.pop(mainScreenContext); // Cierra el drawer

  final result = await showDialog<Map<String, dynamic>>(
    context: mainScreenContext,
    builder: (dialogContext) {
      bool shouldExport = true;
      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('¿Eliminar perfil "$profile"?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'Esta acción no se puede deshacer. ¿Quieres continuar?'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: shouldExport,
                    onChanged: (v) => setState(() => shouldExport = v ?? false),
                  ),
                  const Expanded(
                      child: Text('Exportar backup antes (recomendado)')),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, {'confirmed': false}),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext,
                  {'confirmed': true, 'export': shouldExport}),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
    },
  );

  if (result == null || result['confirmed'] != true) return;

  final bool doExport = result['export'] == true;

  if (doExport) {
    try {
      final path = await bp.exportProfileBackup(profile);
      messenger.showSnackBar(SnackBar(
        content: Text('Backup guardado en: $path'),
        duration: const Duration(seconds: 4),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Error al exportar backup: $e. Eliminación abortada.'),
        backgroundColor: Colors.red,
      ));
      return; // Abortar si el backup falla
    }
  }

  await bp.eliminarPerfil(profile);

  // Si después de eliminar, el perfil actual está vacío (porque era el último),
  // forzamos la creación de uno nuevo.
  if (bp.perfilActual.isEmpty && mainScreenContext.mounted) {
    _mostrarDialogoCrearPerfil(mainScreenContext, canCancel: false);
  }
}

void _mostrarDialogoEditarSaldoInicial(BuildContext context, bool esEfectivo) {
  final provider = Provider.of<BalanceProvider>(context, listen: false);
  final initialValue =
      esEfectivo ? provider.saldoInicialEfectivo : provider.saldoInicialDigital;

  final controller = TextEditingController(text: initialValue.toString());
  controller.selection =
      TextSelection(baseOffset: 0, extentOffset: controller.text.length);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Modificar saldo ${esEfectivo ? "en efectivo" : "digital"}'),
      content: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Saldo',
          prefixText: '\$',
          prefixIcon: Icon(
            esEfectivo ? Icons.money : Icons.account_balance_wallet,
            color: esEfectivo ? Colors.green : Colors.blue,
          ),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            final amount = double.tryParse(controller.text) ?? 0.0;
            if (esEfectivo) {
              provider.establecerSaldoInicialEfectivo(amount);
            } else {
              provider.establecerSaldoInicialDigital(amount);
            }
            Navigator.pop(context);
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}

void _mostrarDialogoEditarMovimiento(BuildContext context, Movement movement) {
  final amountController = TextEditingController(text: movement.amount.toString());
  final conceptController = TextEditingController(text: movement.concept);
  DateTime selectedDate = movement.date;
  bool isDigital = movement.isDigital;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> selectDate() async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2099),
            );
            if (picked != null && picked != selectedDate) {
              setState(() => selectedDate = picked);
            }
          }

          return AlertDialog(
            title: const Text('Editar movimiento'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: <Widget>[
                      Text(DateFormat('dd/MM/yyyy').format(selectedDate.toLocal())),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: selectDate,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: conceptController,
                    decoration: const InputDecoration(
                        labelText: 'Concepto', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: const InputDecoration(
                        labelText: 'Monto',
                        border: OutlineInputBorder(),
                        prefixText: '\$'),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                          value: false,
                          icon: Icon(Icons.money, color: Colors.green),
                          label: Text('Efectivo')),
                      ButtonSegment<bool>(
                          value: true,
                          icon: Icon(Icons.account_balance_wallet,
                              color: Colors.blue),
                          label: Text('Digital')),
                    ],
                    selected: {isDigital},
                    onSelectionChanged: (selected) =>
                        setState(() => isDigital = selected.first),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () async {
                  final newAmount = double.tryParse(
                          amountController.text.replaceAll(',', '.')) ??
                      movement.amount;
                  final newConcept = conceptController.text.isEmpty
                      ? movement.concept
                      : conceptController.text;

                  final newMovement = Movement(
                      date: selectedDate,
                      concept: newConcept,
                      amount: newAmount,
                      isDigital: isDigital);

                  final provider =
                      Provider.of<BalanceProvider>(context, listen: false);
                  await provider.editarMovimiento(movement.key, newMovement);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                child: const Text('Guardar'),
              ),
              TextButton(
                onPressed: () async {
                  final provider =
                      Provider.of<BalanceProvider>(context, listen: false);
                  await provider.eliminarMovimiento(movement.key);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ],
          );
        },
      );
    },
  );
}
