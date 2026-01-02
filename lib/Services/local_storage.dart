import 'package:hive/hive.dart';
import '../Models/fish_history.dart';

class LocalStorage {
  static const String boxName = 'fish_history_box';

  Future<void> init() async {
    Hive.registerAdapter(FishHistoryAdapter());
    await Hive.openBox<FishHistory>(boxName);
  }

  Box<FishHistory> get box => Hive.box<FishHistory>(boxName);

  Future<void> addPrediction(FishHistory history) async {
    await box.put(history.id, history);
  }

  List<FishHistory> getAll() {
    final list = box.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> delete(String id) async {
    await box.delete(id);
  }
}

final LocalStorage localStorage = LocalStorage();
