import 'package:flutter/foundation.dart';
import '../models/season.dart';
import '../services/seasons_service.dart';

class SeasonsProvider extends ChangeNotifier {
  final _service = SeasonsService();

  List<Season> _seasons = [];
  Season? _active;
  bool _loading = false;
  String? _error;

  List<Season> get seasons => _seasons;
  Season? get active => _active;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _seasons = await _service.loadSeasons();
      if (_seasons.isNotEmpty) {
        _active = _seasons.first;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setActive(Season s) {
    _active = s;
    notifyListeners();
  }
}
