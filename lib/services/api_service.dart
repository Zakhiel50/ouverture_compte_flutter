import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import 'package:firebase_auth/firebase_auth.dart';

class ApiService {
  // Configured to automatically select the right localhost address depending on the platform
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000'; // Special loopback IP for Android Emulator
    }
    return 'http://localhost:3000'; // iOS / macOS / Linux / Windows
  }

  /// Initialise et ouvre la boîte Hive pour l'API
  static Future<Box> boxInit() async {
    if (Hive.isBoxOpen('apiEligibilite')) {
      return Hive.box('apiEligibilite');
    }
    return await Hive.openBox('apiEligibilite');
  }

  /// Stocke la réponse API dans Hive avec une clé personnalisée (String, Uri, etc.)
  static Future<void> addItemWithCustomKey(dynamic key, dynamic data) async {
    final box = await boxInit();
    final String stringKey = key.toString();
    await box.put(stringKey, data);
    debugPrint('Données sauvegardées dans Hive [$stringKey] : $data');
  }

  /// Récupère la réponse API stockée dans Hive
  static Future<dynamic> getItemWithCustomKey(dynamic key) async {
    final box = await boxInit();
    return box.get(key.toString());
  }

  /// Récupère les données d'un utilisateur depuis l'API et les enregistre dans Hive
  static Future<Map<String, dynamic>> fetchUserData({String? userId}) async {
    final firebaseUid = FirebaseAuth.instance.currentUser?.uid;
    final targetUserId =
        (userId != null && userId.isNotEmpty) ? userId : (firebaseUid ?? 'usr_101');
    final uri = Uri.parse('$baseUrl/api/users/$targetUserId');

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          await addItemWithCustomKey(uri, jsonResponse['data']);

          return Map<String, dynamic>.from(jsonResponse['data'] as Map);
        } else {
          throw Exception("L'API a répondu avec une erreur métier.");
        }
      } else {
        throw Exception("Erreur serveur (Code ${response.statusCode})");
      }
    } catch (e) {
      final cachedData = await getItemWithCustomKey(uri);
      if (cachedData != null && cachedData is Map) {
        return Map<String, dynamic>.from(cachedData);
      }
      throw Exception("Impossible de contacter l'API sur $uri : $e");
    }
  }
}
