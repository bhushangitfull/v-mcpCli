import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chatmcp/provider/mcp_server_provider.dart';

class ServerStateProvider extends ChangeNotifier {
  static final ServerStateProvider _instance = ServerStateProvider._internal();
  factory ServerStateProvider() => _instance;
  ServerStateProvider._internal();

  final Map<String, bool> _enabledStates = {};

  final Map<String, bool> _runningStates = {};

  final Map<String, bool> _startingStates = {};


  int get enabledCount => _enabledStates.values.where((value) => value).length;

  bool isEnabled(String serverName) => _enabledStates[serverName] ?? false;


  bool isRunning(String serverName) => _runningStates[serverName] ?? false;


  bool isStarting(String serverName) => _startingStates[serverName] ?? false;


  void setEnabled(String serverName, bool value) {
    _enabledStates[serverName] = value;
    notifyListeners();
  }

  void setRunning(String serverName, bool value) {
    _runningStates[serverName] = value;
    _startingStates.remove(serverName); 
    notifyListeners();
  }

  
  void setStarting(String serverName, bool value) {
    _startingStates[serverName] = value;
    notifyListeners();
  }

  
  void syncFromProvider(McpServerProvider provider, List<String> servers) {
    if (servers.isEmpty) return;

    bool changed = false;
    for (String server in servers) {
    
      bool enabled = provider.isToolCategoryEnabled(server);
      if (_enabledStates[server] != enabled) {
        _enabledStates[server] = enabled;
        changed = true;
      }

      bool running = provider.mcpServerIsRunning(server);
      if (_runningStates[server] != running) {
        _runningStates[server] = running;
        changed = true;
      }
    }

    if (changed) {
      notifyListeners();
    }
  }
}
