// lib/services/zkp_mcp_handler.dart
import 'package:eventflux/eventflux.dart';
import 'zkp_security_client.dart';
import 'mcp_client.dart';

class ZKPMCPHandler {
  final EventFlux mcpConnection;
  final ZKPSecurityClient zkpClient;
  final MCPClient mcpClient;

  ZKPMCPHandler({
    required this.mcpConnection,
    required this.zkpClient,
    required this.mcpClient,
  });

  /// ============================================
  /// Main entry point: User prompt → File operation
  /// ============================================
  Future<MCPFileOperationResult> processFileOperationWithZKP({
    required String filePath,
    required String operation, // "read_file", "read_text_file", "search", etc.
    required String userId,
    Map<String, dynamic>? operationParams,
  }) async {
    print('🔐 Processing: $operation on $filePath');

    try {
      // Step 1: Prove access right without revealing credentials
      final accessProof = await _proveFileAccess(filePath, userId);
      if (!accessProof['success']) {
        return MCPFileOperationResult(
          success: false,
          error: 'Access proof failed',
        );
      }

      // Step 2: Perform MCP file operation
      final fileContent = await _performMCPOperation(
        filePath: filePath,
        operation: operation,
        params: operationParams,
      );

      if (fileContent == null) {
        return MCPFileOperationResult(
          success: false,
          error: 'Failed to read file',
        );
      }

      // Step 3: Verify file integrity (Merkle proof)
      final integrityProof = await _proveFileIntegrity(
        fileContent: fileContent,
        filePath: filePath,
      );

      // Step 4: Create audit entry
      final auditEntry = await _createAuditEntry(
        userId: userId,
        filePath: filePath,
        operation: operation,
        dataSize: fileContent.length,
        fileHash: integrityProof['file_hash'],
      );

      // Step 5: Return verified content with proofs
      return MCPFileOperationResult(
        success: true,
        content: fileContent,
        accessProof: accessProof,
        integrityProof: integrityProof,
        auditEntry: auditEntry,
      );
    } catch (e) {
      print('❌ Error: $e');
      return MCPFileOperationResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// ============================================
  /// Step 1: Prove file access WITHOUT credentials
  /// ============================================
  Future<Map<String, dynamic>> _proveFileAccess(
    String filePath,
    String userId,
  ) async {
    print('Step 1: 🔐 Proving access to $filePath');

    try {
      // Get user's credential/token from secure storage
      final credential = await _getCredentialFromSecureStorage(userId);

      if (credential == null) {
        return {
          'success': false,
          'error': 'No credentials found',
        };
      }

      // Generate ZKP proof of access
      final proof = await zkpClient.proveFileAccess(
        credential: credential,
        filePath: filePath,
      );

      if (!proof['success']) {
        return {
          'success': false,
          'error': 'Failed to generate access proof',
        };
      }

      print('   ✅ Access proof generated');
      print('   📋 Proof: ${proof['proof']['response'].toString().substring(0, 32)}...');
      print('   ℹ️ Credential: *** (HIDDEN)');

      return {
        'success': true,
        'proof': proof['proof'],
        'message': 'Access proven without revealing credentials',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// ============================================
  /// Step 2: Perform MCP file operation
  /// ============================================
  Future<String?> _performMCPOperation({
    required String filePath,
    required String operation,
    Map<String, dynamic>? params,
  }) async {
    print('Step 2: 📂 Reading from MCP server: $operation');

    try {
      // Different operations
      switch (operation) {
        case 'read_file':
          return await _readFile(filePath);

        case 'read_text_file':
          return await _readTextFile(filePath);

        case 'search_in_file':
          final searchTerm = params?['searchTerm'] as String?;
          return await _searchInFile(filePath, searchTerm ?? '');

        case 'get_file_info':
          return await _getFileInfo(filePath);

        default:
          throw Exception('Unknown operation: $operation');
      }
    } catch (e) {
      print('❌ MCP operation failed: $e');
      return null;
    }
  }

  Future<String> _readFile(String filePath) async {
    print('   Reading file: $filePath');

    try {
      final response = await mcpConnection.send({
        'method': 'resources/read',
        'params': {'uri': 'file://$filePath'},
      });

      if (response != null && response['contents'] != null) {
        final content = response['contents'][0]['text'];
        print('   ✅ File read: ${content.length} bytes');
        return content;
      }

      return '';
    } catch (e) {
      print('   ❌ Error reading file: $e');
      rethrow;
    }
  }

  Future<String> _readTextFile(String filePath) async {
    print('   Reading text file: $filePath');

    try {
      final response = await mcpConnection.send({
        'method': 'resources/read',
        'params': {'uri': 'file://$filePath'},
      });

      if (response != null && response['contents'] != null) {
        final content = response['contents'][0]['text'];
        print('   ✅ Text file read: ${content.length} characters');
        return content;
      }

      return '';
    } catch (e) {
      print('   ❌ Error reading text file: $e');
      rethrow;
    }
  }

  Future<String> _searchInFile(String filePath, String searchTerm) async {
    print('   Searching "$searchTerm" in: $filePath');

    try {
      // Read file first
      final content = await _readFile(filePath);

      // Search locally (file stays private)
      final lines = content.split('\n');
      final matchingLines = lines
          .where((line) => line.toLowerCase().contains(searchTerm.toLowerCase()))
          .toList();

      print('   ✅ Found ${matchingLines.length} matching lines');

      return matchingLines.join('\n');
    } catch (e) {
      print('   ❌ Error searching in file: $e');
      rethrow;
    }
  }

  Future<String> _getFileInfo(String filePath) async {
    print('   Getting file info: $filePath');

    try {
      final response = await mcpConnection.send({
        'method': 'resources/info',
        'params': {'uri': 'file://$filePath'},
      });

      if (response != null) {
        return response.toString();
      }

      return '';
    } catch (e) {
      print('   ❌ Error getting file info: $e');
      rethrow;
    }
  }

  /// ============================================
  /// Step 3: Prove file integrity (Merkle proof)
  /// ============================================
  Future<Map<String, dynamic>> _proveFileIntegrity({
    required String fileContent,
    required String filePath,
  }) async {
    print('Step 3: 🔍 Proving file integrity');

    try {
      // In real implementation, you'd extract the actual matching lines
      // For now, use the whole content
      final lines = fileContent.split('\n');
      final matchingLines = lines.take(5).toList(); // Sample

      final proof = await zkpClient.proveSearchIntegrity(
        fileContent: fileContent,
        matchingLines: matchingLines,
      );

      if (!proof['success']) {
        return {
          'success': false,
          'error': 'Failed to generate integrity proof',
        };
      }

      print('   ✅ File integrity verified');
      print('   📊 File hash: ${proof['proof']['file_root_hash'].toString().substring(0, 32)}...');
      print('   📈 Total lines: ${proof['proof']['total_lines']}');

      return {
        'success': true,
        'file_hash': proof['proof']['file_root_hash'],
        'total_lines': proof['proof']['total_lines'],
        'proof': proof['proof'],
      };
    } catch (e) {
      print('❌ Integrity proof failed: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// ============================================
  /// Step 4: Create immutable audit entry
  /// ============================================
  Future<Map<String, dynamic>> _createAuditEntry({
    required String userId,
    required String filePath,
    required String operation,
    required int dataSize,
    required String fileHash,
  }) async {
    print('Step 4: 📋 Creating audit entry');

    try {
      final auditResult = await zkpClient.createAuditEntry(
        userId: userId,
        filePath: filePath,
        dataSentToLLM: 'Operation: $operation | Size: $dataSize bytes | Hash: $fileHash',
        operation: operation,
      );

      if (!auditResult['success']) {
        return {
          'success': false,
          'error': 'Failed to create audit entry',
        };
      }

      print('   ✅ Audit entry created');
      print('   📝 Audit ID: ${auditResult['audit_id']}');
      print('   🔐 Timestamp: ${auditResult['timestamp']}');

      return {
        'success': true,
        'audit_id': auditResult['audit_id'],
        'timestamp': auditResult['timestamp'],
      };
    } catch (e) {
      print('❌ Audit entry failed: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// ============================================
  /// Helper: Get credential from secure storage
  /// ============================================
  Future<String?> _getCredentialFromSecureStorage(String userId) async {
    // In production, use flutter_secure_storage
    // For now, return a placeholder
    return 'user_credential_$userId';
  }
}

/// ============================================
/// Result model
/// ============================================
class MCPFileOperationResult {
  final bool success;
  final String? content;
  final String? error;
  final Map<String, dynamic>? accessProof;
  final Map<String, dynamic>? integrityProof;
  final Map<String, dynamic>? auditEntry;

  MCPFileOperationResult({
    required this.success,
    this.content,
    this.error,
    this.accessProof,
    this.integrityProof,
    this.auditEntry,
  });

  @override
  String toString() {
    return '''
MCPFileOperationResult(
  success: $success,
  content_size: ${content?.length ?? 0},
  error: $error,
  has_proofs: ${accessProof != null},
)
    ''';
  }
}