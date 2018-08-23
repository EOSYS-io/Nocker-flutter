import 'dart:async';

import 'package:eos_node_checker/model/EosNode.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

final String databaseName = 'producer.db';
final String tableName = 'producer';
final String columnId = '_id';
final String columnTitle = 'title';
final String columnUrl = 'url';
final String columnEndpoint = 'endpoint';

class ProducerProvider {
  Database db;

  Future open() async {
    if (db != null) {
      return;
    }

    final dbPath = await getDatabasesPath();
    String path = join(dbPath, databaseName);
    db = await openDatabase(path, version: 1,
        onCreate: (db, version) {
          db.execute('''
            create table $tableName (
              $columnId integer primary key autoincrement,
              $columnTitle text not null,
              $columnUrl text not null,
              $columnEndpoint text not null
            )
          ''');
        }
    );
  }

  void insert(EosNode node) async {
    db.insert(tableName, {
      columnTitle: node.title,
      columnUrl: node.url,
      columnEndpoint: node.endpoint
    });
  }

  Future<String> getEndpoint(String title) async {
    List result = await db.query(
        tableName,
        columns: [columnTitle, columnEndpoint],
        where: '$columnTitle = ?',
        whereArgs: [title]
    );
    return result.length > 0 ? result.first[columnEndpoint] : null;
  }

  Future close() async {
    Future f = db.close();
    db = null;
    return f;
  }
}