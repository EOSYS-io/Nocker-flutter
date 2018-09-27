import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

final String databaseName = 'producer.db';
final String tableName = 'producer';
final String columnId = '_id';
final String columnTitle = 'title';
final String columnUrl = 'url';
final String columnEndpoint = 'endpoint';
final String columnLogoUrl = 'logo_url';

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
              $columnEndpoint text not null,
              $columnLogoUrl text not null
            )
          ''');
        },
    );
  }

  void insert(String title, String url, String endpoint, String logoUrl) async {
    await db.insert(tableName, {
      columnTitle: title,
      columnUrl: url,
      columnEndpoint: endpoint,
      columnLogoUrl: logoUrl
    }).catchError((error) => print(error));
  }

  Future<String> getLogoUrl(String title) async {
    List<String> result = await db.query(
        tableName,
        columns: [columnLogoUrl],
        where: '$columnTitle = ?',
        whereArgs: [title]
    ).then((list) => list.map((map) => map[columnLogoUrl].toString()).toList());
    return (result == null || result.length > 0) ? result[0] : null;
  }

  Future<List<String>> getEndpoints(String title) async {
    List<String> result = await db.query(
        tableName,
        columns: [columnEndpoint],
        where: '$columnTitle = ?',
        whereArgs: [title]
    ).then((list) => list.map((map) => map[columnEndpoint].toString()).toList());
    return (result == null || result.length > 0) ? result : null;
  }

  Future close() async {
    Future f = await db.close();
    db = null;
    return f;
  }
}