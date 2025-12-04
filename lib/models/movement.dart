import 'package:hive/hive.dart';

part 'movement.g.dart';

@HiveType(typeId: 0)
class Movement extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  String concept;

  @HiveField(2)
  double amount;

  @HiveField(3)
  bool isDigital;

  Movement({
    required this.date,
    required this.concept,
    required this.amount,
    required this.isDigital,
  });

  // Constructor para crear una nueva instancia con los mismos datos,
  // útil para la edición.
  factory Movement.withKey({
    required DateTime date,
    required String concept,
    required double amount,
    required bool isDigital,
  }) {
    return Movement(
        date: date, concept: concept, amount: amount, isDigital: isDigital);
  }

  @override
  String toString() {
    return 'Movement(date: $date, concept: $concept, amount: $amount, isDigital: $isDigital)';
  }
}
