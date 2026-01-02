import 'package:hive/hive.dart';
part 'fish_history.g.dart';

@HiveType(typeId: 0)
class FishHistory {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String imagePath;

  @HiveField(2)
  final String speciesLabel;

  @HiveField(3)
  final double speciesConfidence;

  @HiveField(4)
  final String freshnessLabel;

  @HiveField(5)
  final double freshnessConfidence;

  @HiveField(6)
  final DateTime createdAt;

  FishHistory({
    required this.id,
    required this.imagePath,
    required this.speciesLabel,
    required this.speciesConfidence,
    required this.freshnessLabel,
    required this.freshnessConfidence,
    required this.createdAt,
  });
}
