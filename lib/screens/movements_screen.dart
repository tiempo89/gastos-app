import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/balance_provider.dart';
import 'package:open_file/open_file.dart';
import '../models/movement.dart';
import './filter_screen.dart';

final _formatoNumero = NumberFormat.decimalPattern('es_ES');

class PantallaMovimientos extends StatefulWidget {
  const PantallaMovimientos({super.key});

  @override
  State<PantallaMovimientos> createState() => _PantallaMovimientosState();
}

class _PantallaMovimientosState extends State<PantallaMovimientos> {
  final TextEditingController _controladorConcepto = TextEditingController();
  final TextEditingController _controladorMonto = TextEditingController();
  bool _esMovimientoDigital = false;

  @override
  void dispose() {
    _controladorConcepto.dispose();
    _controladorMonto.dispose();
    super.dispose();
  }

  void _mostrarDialogoCrearPerfil(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear nuevo perfil'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nombre del perfil'),
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
              final name = controller.text;
              if (name.isNotEmpty) {
                Provider.of<BalanceProvider>(context, listen: false)
                    .crearPerfil(name);
                Navigator.pop(context); // Close dialog
                if (Navigator.canPop(context)) {
                  Navigator.pop(context); // Close drawer
                }
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  // Nota: la lógica de eliminación se maneja ahora dentro del IconButton de cada perfil.

  void _mostrarDialogoEditarPerfil(
      BuildContext context, String oldProfileName) {
    final TextEditingController controller =
        TextEditingController(text: oldProfileName);
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

  void _mostrarDialogoEditarSaldoInicial(
      BuildContext context, bool esEfectivo) {
    final initialValue = esEfectivo
        ? Provider.of<BalanceProvider>(context, listen: false)
            .saldoInicialEfectivo
        : Provider.of<BalanceProvider>(context, listen: false)
            .saldoInicialDigital;

    final TextEditingController controller = TextEditingController(
      text: initialValue.toString(),
    );
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text('Modificar saldo ${esEfectivo ? "en efectivo" : "digital"}'),
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
                Provider.of<BalanceProvider>(context, listen: false)
                    .establecerSaldoInicialEfectivo(amount);
              } else {
                Provider.of<BalanceProvider>(context, listen: false)
                    .establecerSaldoInicialDigital(amount);
              }
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEditarMovimiento(
      BuildContext context, int index, Movement movement) {
    final TextEditingController amountController =
        TextEditingController(text: movement.amount.toString());
    final TextEditingController conceptController =
        TextEditingController(text: movement.concept);
    DateTime selectedDate = movement.date;
    amountController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: amountController.text.length,
    );
    bool isDigital = movement.isDigital;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> selectDate(BuildContext context) async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(
                    2099), // Establece una fecha lejana para evitar errores
              );
              if (picked != null && picked != selectedDate) {
                setState(() {
                  selectedDate = picked;
                });
              }
            }

            return AlertDialog(
              title: const Text('Editar movimiento'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: <Widget>[
                      Text(DateFormat('dd/MM/yyyy hh:mm')
                          .format(selectedDate.toLocal())),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () => selectDate(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: conceptController,
                    decoration: const InputDecoration(
                      labelText: 'Concepto',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: const InputDecoration(
                      labelText: 'Monto',
                      border: OutlineInputBorder(),
                      prefixText: '\$',
                      helperText: 'Usa punto para decimales',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: false,
                        icon: Icon(Icons.money, color: Colors.green, size: 28),
                        label: Text('Efectivo'),
                      ),
                      ButtonSegment<bool>(
                        value: true,
                        icon: Icon(Icons.account_balance_wallet,
                            color: Colors.blue, size: 28),
                        label: Text('Digital'),
                      ),
                    ],
                    selected: {isDigital},
                    onSelectionChanged: (Set<bool> selected) {
                      setState(() {
                        isDigital = selected.first;
                      });
                    },
                  ),
                ],
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
                        movement
                            .amount; // Reemplaza la coma por punto para el parseo
                    final newConcept = conceptController.text.isEmpty
                        ? movement.concept
                        : conceptController.text;

                    final newMovement = Movement(
                      date: selectedDate,
                      concept: newConcept,
                      amount: newAmount,
                      isDigital: isDigital,
                    );

                    await Provider.of<BalanceProvider>(context, listen: false)
                        .editarMovimiento(index, newMovement);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: const Text('Guardar'),
                ),
                TextButton(
                  onPressed: () async {
                    await Provider.of<BalanceProvider>(context, listen: false)
                        .eliminarMovimiento(index);
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

  @override
  Widget build(BuildContext context) {
    final balanceProvider = Provider.of<BalanceProvider>(context);

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/drawer_background.jpg'),
                  fit: BoxFit.cover,
                  colorFilter:
                      ColorFilter.mode(Color(0x80000000), BlendMode.darken),
                ),
              ),
              child: Text(
                'Perfiles',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [const Shadow(blurRadius: 10, color: Colors.black)],
                ),
              ),
            ),
            ...balanceProvider.perfiles.map((profile) => ListTile(
                  title: Text(
                    profile,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: profile == balanceProvider.perfilActual,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Editar nombre',
                        onPressed: () {
                          Navigator.pop(context); // Close drawer
                          _mostrarDialogoEditarPerfil(context, profile);
                        },
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Eliminar perfil',
                        onPressed: () async {
                          Navigator.pop(context); // Close drawer
                          final bp = Provider.of<BalanceProvider>(context,
                              listen: false);
                          // Confirm deletion
                          if (!context.mounted) return;
                          final result = await showDialog<Map<String, dynamic>>(
                            context: context,
                            builder: (context) {
                              bool shouldExport = true;
                              return StatefulBuilder(
                                builder: (context, setState) => AlertDialog(
                                  title: Text('¿Eliminar perfil "$profile"?'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                          'Esta acción eliminará los saldos y movimientos asociados a este perfil. ¿Quieres continuar?'),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: shouldExport,
                                            onChanged: (v) => setState(() {
                                              shouldExport = v ?? false;
                                            }),
                                          ),
                                          const SizedBox(width: 8),
                                          const Expanded(
                                            child: Text(
                                                'Exportar backup antes de borrar (recomendado)'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(
                                          context, {'confirmed': false}),
                                      child: const Text('Cancelar'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, {
                                        'confirmed': true,
                                        'export': shouldExport,
                                      }),
                                      style: TextButton.styleFrom(
                                          foregroundColor: Colors.red),
                                      child: const Text('Eliminar'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );

                          if (result == null || result['confirmed'] != true) {
                            return;
                          }

                          final bool doExport = result['export'] == true;
                          final buildContext = context;

                          // Primero cambiar de perfil si es necesario
                          if (bp.perfilActual == profile) {
                            if (bp.perfiles.length > 1) {
                              // Cambiar a otro perfil disponible
                              String nuevoPerfil =
                                  bp.perfiles.firstWhere((p) => p != profile);
                              await bp.cambiarPerfil(nuevoPerfil);
                            }
                          }

                          // Ahora intentar el backup si se solicitó
                          if (doExport) {
                            try {
                              final path =
                                  await bp.exportProfileBackup(profile);
                              if (!buildContext.mounted) return;
                              ScaffoldMessenger.of(buildContext).showSnackBar(
                                SnackBar(
                                  content: Text('Backup guardado en: $path'),
                                  duration: const Duration(seconds: 4),
                                ),
                              );
                            } catch (e) {
                              if (!buildContext.mounted) return;
                              ScaffoldMessenger.of(buildContext).showSnackBar(
                                SnackBar(
                                  content: Text('Error al exportar backup: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              // Si la exportación falla, abortar la eliminación para seguridad
                              return;
                            }
                          }

                          // Finalmente eliminar el perfil
                          await bp.eliminarPerfil(profile);

                          // Si no quedan perfiles, abrir el diálogo para crear uno nuevo
                          if (bp.perfiles.isEmpty) {
                            if (!buildContext.mounted) return;
                            _mostrarDialogoCrearPerfil(buildContext);
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    balanceProvider.cambiarPerfil(profile);
                    Navigator.pop(context);
                  },
                )),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Crear Perfil'),
              onTap: () => _mostrarDialogoCrearPerfil(context),
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: const Text('Movimientos'),
        actions: [
          // Botón exportar PDF
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final provider =
                  Provider.of<BalanceProvider>(context, listen: false);
              final messenger = ScaffoldMessenger.of(context);
              messenger.hideCurrentSnackBar();
              messenger.showSnackBar(const SnackBar(
                content: Text('Generando PDF...'),
                duration: Duration(days: 1),
              ));
              try {
                final path = await provider.exportarAPdf();
                messenger.hideCurrentSnackBar();
                messenger.showSnackBar(SnackBar(
                  content: Text('PDF generado: $path'),
                  action: SnackBarAction(
                    label: 'Abrir',
                    onPressed: () => OpenFile.open(path),
                  ),
                ));
              } catch (e) {
                messenger.hideCurrentSnackBar();
                messenger.showSnackBar(const SnackBar(
                  content: Text('Error al generar PDF'),
                ));
              }
            },
            tooltip: 'Exportar PDF',
          ),
          // Botón de filtros
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FilterScreen(),
                ),
              );
            },
            tooltip: 'Filtrar movimientos',
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              final provider =
                  Provider.of<BalanceProvider>(context, listen: false);
              provider.alternarTema();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Tarjeta superior con saldos
          Card(
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
                            Text(
                              "Efectivo",
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Inicial: \$${_formatoNumero.format(balanceProvider.saldoInicialEfectivo)}",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
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
                  onTap: () =>
                      _mostrarDialogoEditarSaldoInicial(context, false),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.account_balance_wallet,
                                color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              "Digital",
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Inicial: \$${_formatoNumero.format(balanceProvider.saldoInicialDigital)}",
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "\$${_formatoNumero.format(balanceProvider.saldoActualDigital)}",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    balanceProvider.currentDigitalBalance >= 0
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
              ],
            ),
          ),

          // Formulario para agregar movimiento
          Padding(
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
                    Expanded(
                      child: TextField(
                        controller: _controladorMonto,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9\.\-]'))
                        ],
                        decoration: const InputDecoration(
                          labelText: "Monto (+ ingreso, - gasto)",
                          border: OutlineInputBorder(),
                          prefixText: "\$",
                          helperText: "Usa coma para decimales",
                        ),
                      ),
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
                        onPressed: () {
                          final concept = _controladorConcepto.text;
                          final amount = double.tryParse(_controladorMonto.text
                                  .replaceAll(',', '.')) ??
                              0.0;

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
                            });
                          }
                        },
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
          ),

          // Lista de movimientos con fondo de imagen
          Expanded(
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
                          onLongPress: () => _mostrarDialogoEditarMovimiento(
                              context, index, movement),
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
                                        .withAlpha(balanceProvider.esModoOscuro
                                            ? 51
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
          ),
          // Total general (al final)
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text(
                    "TOTAL",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
          ),
        ],
      ),
    );
  }
}
