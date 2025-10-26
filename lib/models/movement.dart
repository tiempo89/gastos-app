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

  @override
  String toString() {
    return 'Movement(date: $date, concept: $concept, amount: $amount, isDigital: $isDigital)';
  }
}
