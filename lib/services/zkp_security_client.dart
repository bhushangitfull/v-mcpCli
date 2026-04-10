// lib/services/zkp_security_client.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class ZKPSecurityClient {
  final String zkpServerUrl;
  bool _serverAvailable = false;

  ZKPSecurityClient({this.zkpServerUrl = 'http://localhost:8778'});

  // ===== FILE ACCESS CONTROL =====
  /// Generate proof of file access WITHOUT revealing your credential
  /// This proves you have permission to access a file without sending credentials
  Future<Map<String, dynamic>> proveFileAccess({
    required String credential,
    required String filePath,
  }) async {
    try {
      final nonce = const Uuid().v4();
      
      final response = await http.post(
        Uri.parse('$zkpServerUrl/prove/access'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'credential': credential,
          'file_path': filePath,
          'nonce': nonce,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'proof': data['proof'],
          'message': data['message'],
          'type': 'access_control',
        };
      }
      return {'success': false, 'error': 'Failed to generate access proof'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Verify access proof on server side
  Future<bool> verifyAccessProof({
    required String credential,
    required String filePath,
    required String nonce,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$zkpServerUrl/verify/access'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'credential': credential,
          'file_path': filePath,
          'nonce': nonce,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['verified'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ===== SEARCH INTEGRITY =====
  /// Prove search results are authentic WITHOUT revealing full file content
  /// This proves the matching lines actually exist in the file
  Future<Map<String, dynamic>> proveSearchIntegrity({
    required String fileContent,
    required List<String> matchingLines,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$zkpServerUrl/prove/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'file_content': fileContent,
          'matching_lines': matchingLines,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'proof': data['proof'],
          'message': data['message'],
          'type': 'search_integrity',
        };
      }
      return {'success': false, 'error': 'Failed to generate search proof'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Verify search integrity proof
  Future<Map<String, dynamic>> verifySearchIntegrity({
    required String fileContent,
    required List<String> matchingLines,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$zkpServerUrl/verify/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'file_content': fileContent,
          'matching_lines': matchingLines,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'verified': data['verified'],
          'file_root_hash': data['file_root_hash'],
          'total_lines': data['total_lines'],
          'matching_results': data['matching_results'],
          'message': data['message'],
        };
      }
      return {'verified': false, 'error': 'Verification failed'};
    } catch (e) {
      return {'verified': false, 'error': e.toString()};
    }
  }

  // ===== FILE SIZE ENFORCEMENT =====
  /// Prove file size is within limit WITHOUT revealing actual size
  /// This proves the file meets size requirements without exposing the exact size
  Future<Map<String, dynamic>> proveFileSizeLimit({
    required int fileSize,
    required int maxAllowedSize,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$zkpServerUrl/prove/file-size'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'file_size': fileSize,
          'max_allowed_size': maxAllowedSize,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'proof': data['proof'],
          'message': data['message'],
          'type': 'file_size_enforcement',
        };
      } else {
        final data = jsonDecode(response.body);
        return {'success': false, 'error': data['error'] ?? 'Size proof failed'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Verify file size limit proof
  Future<Map<String, dynamic>> verifyFileSizeLimit({
    required int fileSize,
    required int maxAllowedSize,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$zkpServerUrl/verify/file-size'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'file_size': fileSize,
          'max_allowed_size': maxAllowedSize,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'verified': data['verified'],
          'size_commitment': data['size_commitment'],
          'max_allowed': data['max_allowed'],
          'message': data['message'],
        };
      }
      return {'verified': false};
    } catch (e) {
      return {'verified': false, 'error': e.toString()};
    }
  }

  // ===== LLM AUDIT TRAIL =====
  /// Create audit entry when data is sent to LLM
  /// This creates an immutable record of what was shared with the LLM
  Future<Map<String, dynamic>> createAuditEntry({
    required String userId,
    required String filePath,
    required String dataSentToLLM,
    required String operation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$zkpServerUrl/audit/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'file_path': filePath,
          'data_sent_to_llm': dataSentToLLM,
          'operation': operation,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'audit_id': data['audit_id'],
          'timestamp': data['timestamp'],
          'data_size_bytes': data['data_size_bytes'],
          'message': data['message'],
          'type': 'audit_trail',
        };
      }
      return {'success': false, 'error': 'Failed to create audit entry'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get the complete audit trail with integrity proofs
  Future<Map<String, dynamic>> getAuditTrail() async {
    try {
      final response = await http.get(
        Uri.parse('$zkpServerUrl/audit/trail'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'error': 'Failed to retrieve audit trail'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Check server health
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$zkpServerUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(Duration(seconds: 5));

      _serverAvailable = response.statusCode == 200;
      return _serverAvailable;
    } catch (e) {
      _serverAvailable = false;
      return false;
    }
  }

  bool get isServerAvailable => _serverAvailable;
}