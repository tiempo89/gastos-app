import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/balance_provider.dart';

class FilterScreen extends StatelessWidget {
  const FilterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BalanceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filtros'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              provider.limpiarFiltros();
              Navigator.pop(context);
            },
            tooltip: 'Limpiar filtros',
          ),
        ],
      ),
      body: ListView(
        children: [
          // Sección de Ordenamiento
          _buildSection(
            title: 'Ordenar por',
            child: Column(
              children: [
                _buildOrderOption(
                  context: context,
                  title: 'Fecha (más reciente primero)',
                  value: Ordenamiento.fechaDescendente,
                  selectedValue: provider.ordenamiento,
                  onSelect: (value) => provider.alternarOrdenamiento(),
                ),
                _buildOrderOption(
                  context: context,
                  title: 'Fecha (más antiguo primero)',
                  value: Ordenamiento.fechaAscendente,
                  selectedValue: provider.ordenamiento,
                  onSelect: (value) => provider.alternarOrdenamiento(),
                ),
                _buildOrderOption(
                  context: context,
                  title: 'Alfabético (A-Z)',
                  value: Ordenamiento.alfabeticoAscendente,
                  selectedValue: provider.ordenamiento,
                  onSelect: (value) => provider.alternarOrdenamiento(),
                ),
                _buildOrderOption(
                  context: context,
                  title: 'Alfabético (Z-A)',
                  value: Ordenamiento.alfabeticoDescendente,
                  selectedValue: provider.ordenamiento,
                  onSelect: (value) => provider.alternarOrdenamiento(),
                ),
                _buildOrderOption(
                  context: context,
                  title: 'Monto (menor a mayor)',
                  value: Ordenamiento.montoAscendente,
                  selectedValue: provider.ordenamiento,
                  onSelect: (value) => provider.alternarOrdenamiento(),
                ),
                _buildOrderOption(
                  context: context,
                  title: 'Monto (mayor a menor)',
                  value: Ordenamiento.montoDescendente,
                  selectedValue: provider.ordenamiento,
                  onSelect: (value) => provider.alternarOrdenamiento(),
                ),
              ],
            ),
          ),

          // Sección de Tipo de Movimiento
          _buildSection(
            title: 'Tipo de movimiento',
            child: Column(
              children: [
                _buildFilterOption(
                  context: context,
                  title: 'Todos',
                  value: FiltroTipo.todos,
                  selectedValue: provider.filtroTipo,
                  onSelect: provider.establecerFiltroTipo,
                ),
                _buildFilterOption(
                  context: context,
                  title: 'Efectivo',
                  value: FiltroTipo.efectivo,
                  selectedValue: provider.filtroTipo,
                  onSelect: provider.establecerFiltroTipo,
                ),
                _buildFilterOption(
                  context: context,
                  title: 'Digital',
                  value: FiltroTipo.digital,
                  selectedValue: provider.filtroTipo,
                  onSelect: provider.establecerFiltroTipo,
                ),
              ],
            ),
          ),

          // Sección de Operación
          _buildSection(
            title: 'Operación',
            child: Column(
              children: [
                _buildFilterOption(
                  context: context,
                  title: 'Todos',
                  value: FiltroOperacion.todos,
                  selectedValue: provider.filtroOperacion,
                  onSelect: provider.establecerFiltroOperacion,
                ),
                _buildFilterOption(
                  context: context,
                  title: 'Ingresos',
                  value: FiltroOperacion.ingresos,
                  selectedValue: provider.filtroOperacion,
                  onSelect: provider.establecerFiltroOperacion,
                ),
                _buildFilterOption(
                  context: context,
                  title: 'Egresos',
                  value: FiltroOperacion.egresos,
                  selectedValue: provider.filtroOperacion,
                  onSelect: provider.establecerFiltroOperacion,
                ),
              ],
            ),
          ),

          // Sección de Período
          _buildSection(
            title: 'Período',
            child: Column(
              children: [
                _buildFilterOption(
                  context: context,
                  title: 'Todo',
                  value: FiltroPeriodo.todo,
                  selectedValue: provider.filtroPeriodo,
                  onSelect: provider.establecerFiltroPeriodo,
                ),
                _buildFilterOption(
                  context: context,
                  title: 'Hoy',
                  value: FiltroPeriodo.hoy,
                  selectedValue: provider.filtroPeriodo,
                  onSelect: provider.establecerFiltroPeriodo,
                ),
                _buildFilterOption(
                  context: context,
                  title: 'Este mes',
                  value: FiltroPeriodo.esteMes,
                  selectedValue: provider.filtroPeriodo,
                  onSelect: provider.establecerFiltroPeriodo,
                ),
                _buildFilterOption(
                  context: context,
                  title: 'Este año',
                  value: FiltroPeriodo.esteAnio,
                  selectedValue: provider.filtroPeriodo,
                  onSelect: provider.establecerFiltroPeriodo,
                ),
                ListTile(
                  title: const Text('Período personalizado'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _showDateRangePicker(context, provider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildOrderOption({
    required BuildContext context,
    required String title,
    required Ordenamiento value,
    required Ordenamiento selectedValue,
    required ValueChanged<Ordenamiento> onSelect,
  }) {
    return InkWell(
      onTap: () => onSelect(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selectedValue == value
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).unselectedWidgetColor,
                  width: 2,
                ),
              ),
              child: selectedValue == value
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption<T>({
    required BuildContext context,
    required String title,
    required T value,
    required T selectedValue,
    required ValueChanged<T> onSelect,
  }) {
    return InkWell(
      onTap: () => onSelect(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selectedValue == value
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).unselectedWidgetColor,
                  width: 2,
                ),
              ),
              child: selectedValue == value
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDateRangePicker(
    BuildContext context,
    BalanceProvider provider,
  ) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      currentDate: DateTime.now(),
      saveText: 'Aplicar',
      helpText: 'Seleccionar período',
      cancelText: 'Cancelar',
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).primaryColor,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      provider.establecerFiltroFechaPersonalizado(
        picked.start,
        picked.end,
      );
    }
  }
}
