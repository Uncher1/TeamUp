// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../models/match.dart';
import '../repositories/matching_repo.dart';

class MatchingProvider extends ChangeNotifier {
  final MatchingRepository _repo;
  MatchingProvider(this._repo);

  // Existing: matched projects for the current user.
  List<MatchedProject> projects = [];
  bool loading = false;
  String? error;

  // Find Teammates: ranked candidate users for a chosen project.
  int? selectedProjectId;
  List<MatchedUser> candidates = [];
  bool loadingCandidates = false;
  String? candidatesError;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      projects = await _repo.myProjects();
    } catch (e) {
      error = ApiClient.messageFromError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadCandidates(int projectId) async {
    selectedProjectId = projectId;
    candidates = [];
    candidatesError = null;
    loadingCandidates = true;
    notifyListeners();
    try {
      candidates = await _repo.usersForProject(projectId);
    } catch (e) {
      candidatesError = ApiClient.messageFromError(e);
    } finally {
      loadingCandidates = false;
      notifyListeners();
    }
  }
}
