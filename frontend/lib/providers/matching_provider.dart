import 'package:flutter/material.dart';
import '../models/match.dart';
import '../repositories/matching_repo.dart';

class MatchingProvider extends ChangeNotifier {
  final MatchingRepository _repo;
  MatchingProvider(this._repo);

  List<MatchedProject> projects = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      projects = await _repo.myProjects();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
