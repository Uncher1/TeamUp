// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/foundation.dart';

import '../models/interest.dart';
import '../models/skill.dart';
import '../repositories/lookup_repo.dart';

/// Loads the skill and interest catalogs once and caches them in memory.
class LookupProvider extends ChangeNotifier {
  final LookupRepository repo;
  LookupProvider(this.repo);

  List<Skill> skills = [];
  List<Interest> interests = [];
  bool _loaded = false;
  bool loading = false;

  Future<void> ensureLoaded() async {
    if (_loaded || loading) return;
    loading = true;
    notifyListeners();
    try {
      final results = await Future.wait([repo.skills(), repo.interests()]);
      skills = results[0] as List<Skill>;
      interests = results[1] as List<Interest>;
      _loaded = true;
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
