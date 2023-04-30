import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart' as sql;

/// Tutorial followed to implement SQL CRUD operations:
/// https://www.youtube.com/watch?v=MQhjx1HS_pI

class SQLHelper {
  static Future<void> createTables(sql.Database database) async {
    await database.execute("""CREATE TABLE contacts(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        name TEXT,
        phone TEXT,
        email TEXT,
        address TEXT,
        photo TEXT
      )
      """);
  }

  static Future<sql.Database> db() async {
    return sql.openDatabase(
      'contents_buddy.db',
      version: 1,
      onCreate: (sql.Database database, int version) async {
        debugPrint(
            "Creating a table.."); // Print statement to check if the table is created
        await createTables(database);
      },
    );
  }

  static Future<int> createContact(String name, String phone, String email,
      String address, String photo) async {
    final db = await SQLHelper.db();

    // map the data to be inserted
    final data = {
      'name': name.trim(),
      'phone': phone.trim(),
      'email': email.trim(),
      'address': address.trim(),
      'photo': photo
    };
    final id = await db.insert('contacts', data,
        conflictAlgorithm: sql.ConflictAlgorithm.replace);
    return id;
  }

  static Future<List<Map<String, dynamic>>> getContacts() async {
    final db = await SQLHelper.db();
    return db.query('contacts', orderBy: "id");
  }

  static Future<List<Map<String, dynamic>>> getContact(int id) async {
    final db = await SQLHelper.db();
    return db.query('contacts', where: "id = ?", whereArgs: [id], limit: 1);
  }

  // search contact by name or phone
  static Future<List<Map<String, dynamic>>> searchContacts(
      String keyword) async {
    final db = await SQLHelper.db();
    return db.query('contacts',
        where: "name LIKE ? OR phone LIKE ?",
        whereArgs: ['%$keyword%', '%$keyword%']);
  }

  static Future<int> updateContact(int id, String name, String phone,
      String email, String address, String photo) async {
    final db = await SQLHelper.db();

    // map the data to be updated
    final data = {
      'name': name.trim(),
      'phone': phone.trim(),
      'email': email.trim(),
      'address': address.trim(),
      'photo': photo
    };

    final result =
        await db.update('contacts', data, where: "id = ?", whereArgs: [id]);
    return result;
  }

  static Future<void> deleteContact(int id) async {
    final db = await SQLHelper.db();
    try {
      await db.delete("contacts", where: "id = ?", whereArgs: [id]);
    } catch (e) {
      debugPrint("Something went wrong when deleting a contact: $e");
    }
  }

  static String imageToBase64String(String path) {
    final bytes = File(path).readAsBytesSync();
    return base64.encode(bytes);
  }

  static void deleteBase64Image(String base64Image) {
    final RegExp regex = RegExp(r'^data:image/[^;]+;base64,');
    final String base64Str = base64Image.replaceAll(regex, '');
    final Uint8List bytes = base64.decode(base64Str);
    File.fromRawPath(bytes).deleteSync();
  }

  static String encodePhoto(String path) {
    final String base64Image = imageToBase64String(path);
    debugPrint(
        'Imaged Encoded'); // Print statement to check if the image is encoded
    return base64Image;
  }

  static File decodePhoto(String base64Image, String fileName) {
    final RegExp regex = RegExp(r'^data:image/[^;]+;base64,');
    final String base64Str = base64Image.replaceAll(regex, '');
    final Uint8List bytes = base64.decode(base64Str);
    final file = File(fileName)..writeAsBytesSync(bytes);
    debugPrint(
        'Image Decoded'); // Print statement to check if the image is decoded
    return file;
  }
}
