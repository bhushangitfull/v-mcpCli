import 'package:flutter/material.dart';
import 'package:chatmcp/llm/model.dart' as llm_model;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ChatModelProvider extends ChangeNotifier {
  static final ChatModelProvider _instance = ChatModelProvider._internal();
  factory ChatModelProvider() => _instance;
  ChatModelProvider._internal() {
    _loadSavedModel();
  }

  // Get the currently selected model
  static const String _modelKey = 'current_model';
  llm_model.Model _currentModel = llm_model.Model(
    name: "gemini-2.5-flash",
    label: "Gemini 2.5 Flash",
    providerId: "gemini",
    icon: "assets/icons/gemini.png",
    providerName: "Gemini",
    apiStyle: "gemini",
  );

  llm_model.Model get currentModel => _currentModel;

  set currentModel(llm_model.Model model) {
    _currentModel = model;
    _saveSavedModel();
    notifyListeners();
  }

  Future<void> _loadSavedModel() async {
    final prefs = await SharedPreferences.getInstance();
    final modelName = prefs.getString(_modelKey) ?? "";
    if (modelName.isNotEmpty) {
      _currentModel = llm_model.Model.fromJson(jsonDecode(modelName));
    }
    notifyListeners();
  }

  Future<void> _saveSavedModel() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelKey, _currentModel.toString());
  }
}
