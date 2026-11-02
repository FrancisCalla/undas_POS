import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_service.dart';

/// Initializes Hive local persistence engine and seeds demo data on initial boot.
final databaseInitProvider = FutureProvider<DatabaseService>((ref) async {
  final db = DatabaseService.instance;
  await db.initialize();
  return db;
});
