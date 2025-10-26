// Esta es una prueba de widget básica de Flutter.
//
// Para realizar una interacción con un widget en tu prueba, usa la utilidad WidgetTester
// en el paquete flutter_test. Por ejemplo, puedes enviar gestos de toque y desplazamiento.
// También puedes usar WidgetTester para encontrar widgets hijos en el árbol de widgets,
// leer texto y verificar que los valores de las propiedades de los widgets son correctos.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gastos/main.dart';

void main() {
  testWidgets('Prueba de humo de incremento de contador',
      (WidgetTester tester) async {
    // Construye nuestra aplicación y activa un frame.
    await tester.pumpWidget(const MiAplicacion());

    // Verifica que nuestro contador comienza en 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Toca el ícono '+' y activa un frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verifica que nuestro contador se ha incrementado.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
