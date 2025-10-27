# gastos

**Gastos** es una aplicación de gestión financiera personal desarrollada en Flutter, diseñada para ofrecer un control detallado y flexible de tus ingresos y egresos. La aplicación utiliza Hive para el almacenamiento local, garantizando un rendimiento rápido y la persistencia de los datos directamente en el dispositivo.

## Características Principales

- **Gestión de Múltiples Perfiles**: Crea perfiles separados (por ejemplo, "Personal", "Negocio") para gestionar diferentes conjuntos de finanzas de forma independiente. Cada perfil tiene sus propios saldos y registros.
- **Doble Seguimiento de Saldos**: Registra y visualiza tus saldos de **Efectivo** y **Digital** por separado, además de un total general.
- **Registro de Movimientos**: Añade fácilmente nuevos ingresos o gastos, especificando el concepto, el monto y si la transacción fue en efectivo o digital.
- **Edición y Eliminación**: Modifica o elimina cualquier movimiento con una pulsación larga sobre el registro.
- **Filtrado Avanzado**: Filtra tus movimientos por:
    - **Tipo**: Efectivo, Digital o Todos.
    - **Operación**: Ingresos, Egresos o Todos.
    - **Período**: Hoy, Este Mes, Este Año o un rango de fechas personalizado.
- **Ordenamiento Flexible**: Ordena la lista de movimientos por fecha, concepto o monto, tanto en orden ascendente como descendente.
- **Exportación de Datos**:
    - **Exportar a PDF**: Genera un reporte en PDF con el resumen de saldos y la lista de movimientos filtrados.
    - **Copia de Seguridad (Backup)**: Exporta los datos de un perfil a un archivo JSON para tener una copia de seguridad o para migración.
- **Personalización**:
    - **Tema Claro y Oscuro**: Cambia entre modos de visualización para una mejor experiencia de usuario.
    - **Saldos Iniciales Ajustables**: Modifica los saldos iniciales de efectivo y digital en cualquier momento.
