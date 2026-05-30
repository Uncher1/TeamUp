import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/project.dart';
import '../repositories/project_repo.dart';

class ProjectsProvider extends ChangeNotifier {
  final ProjectRepository repo;
  ProjectsProvider(this.repo);

  bool loading = false;
  String? error;
  List<Project> projects = [];

  List<Project> myProjects = [];
  bool loadingMine = false;
  String? mineError;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      projects = await repo.list();
    } catch (e) {
      error = ApiClient.messageFromError(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMine() async {
    loadingMine = true;
    mineError = null;
    notifyListeners();
    try {
      myProjects = await repo.myProjects();
    } catch (e) {
      mineError = ApiClient.messageFromError(e);
    } finally {
      loadingMine = false;
      notifyListeners();
    }
  }

  Future<Project?> create({
    required String title,
    required String description,
    List<Map<String, int>> requiredSkills = const [],
    List<int> interests = const [],
    String? category,
    int? teamSize,
    String? timeline,
  }) async {
    final created = await repo.create(
      title: title,
      description: description,
      requiredSkills: requiredSkills,
      interests: interests,
      category: category,
      teamSize: teamSize,
      timeline: timeline,
    );
    projects = [created, ...projects];
    notifyListeners();
    return created;
  }
}
