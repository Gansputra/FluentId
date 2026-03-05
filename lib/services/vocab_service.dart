import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/vocab.dart';

class VocabService {
  static const String _assetPath = 'assets/data/vocabBasic.json';

  Future<List<Vocab>> loadVocabularies(String fileName) async {
    try {
      final String response = await rootBundle.loadString('assets/data/$fileName');
      final List<dynamic> data = json.decode(response);
      return data.map((json) => Vocab.fromJson(json)).toList();
    } catch (e) {
      // Error handling: print error and return empty list
      print('Error loading vocabularies: $e');
      return [];
    }
  }
}
