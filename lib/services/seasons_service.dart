import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/season.dart';

class SeasonsService {
  Future<List<Season>> loadSeasons() async {
    final jsonStr = await rootBundle.loadString('assets/data/seasons.json');
    final List<dynamic> data = json.decode(jsonStr) as List<dynamic>;
    return data.map((e) => Season.fromJson(e as Map<String, dynamic>)).toList();
  }
}
