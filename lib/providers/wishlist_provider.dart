import 'package:flutter/foundation.dart';

class WishlistProvider extends ChangeNotifier {
  final Set<String> _raceIds = {};

  Set<String> get raceIds => Set.unmodifiable(_raceIds);

  bool contains(String raceId) => _raceIds.contains(raceId);

  void add(String raceId) {
    _raceIds.add(raceId);
    notifyListeners();
  }

  void remove(String raceId) {
    _raceIds.remove(raceId);
    notifyListeners();
  }

  void clear() {
    _raceIds.clear();
    notifyListeners();
  }
}
