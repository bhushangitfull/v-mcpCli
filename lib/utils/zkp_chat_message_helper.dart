// lib/utils/zkp_chat_message_helper.dart
import 'package:chatmcp/dao/chat.dart';
import 'package:chatmcp/llm/model.dart';
import 'package:chatmcp/services/zkp_mcp_handler.dart';

/// Helper to convert ZKP proof results into chat messages
class ZKPChatMessageHelper {
  /// Create a system message displaying the ZKP proof information
  static ChatMessage createProofVerificationMessage({
    required MCPFileOperationResult result,
    required String filePath,
    required String operation,
    String parentMessageId = '',
  }) {
    if (!result.success) {
      return ChatMessage(
        messageId: _generateId(),
        parentMessageId: parentMessageId,
        role: MessageRole.system,
        content: '''🔴 ZKP Verification Failed
File: $filePath
Operation: $operation
Error: ${result.error ?? 'Unknown error'}''',
      );
    }

    // Build detailed proof message
    StringBuffer content = StringBuffer();
    content.writeln('✅ ZKP Verification Complete');
    content.writeln('File: $filePath');
    content.writeln('Operation: $operation');
    content.writeln();

    // Access Proof Section
    if (result.accessProof != null && result.accessProof!['success'] == true) {
      content.writeln('🔒 ACCESS PROOF');
      content.writeln('├─ Status: ${result.accessProof!['message'] ?? "Verified"}');
      if (result.accessProof!['proof'] != null) {
        final proofHash = _shortenHash(result.accessProof!['proof'].toString());
        content.writeln('├─ Proof: $proofHash');
      }
      content.writeln('└─ Proof proves you have access without revealing credentials');
      content.writeln();
    }

    // Integrity Proof Section
    if (result.integrityProof != null && result.integrityProof!['success'] == true) {
      content.writeln('✔️ FILE INTEGRITY PROOF');
      if (result.integrityProof!['file_hash'] != null) {
        final hash = _shortenHash(result.integrityProof!['file_hash'].toString());
        content.writeln('├─ File Hash: $hash');
      }
      if (result.integrityProof!['total_lines'] != null) {
        content.writeln('├─ File Size: ${result.integrityProof!['total_lines']} lines');
      }
      content.writeln('└─ Merkle proof verifies file content hasn\'t been tampered');
      content.writeln();
    }

    // Audit Entry Section
    if (result.auditEntry != null && result.auditEntry!['success'] == true) {
      content.writeln('📋 AUDIT TRAIL');
      if (result.auditEntry!['audit_id'] != null) {
        content.writeln('├─ Audit ID: ${result.auditEntry!['audit_id']}');
      }
      if (result.auditEntry!['timestamp'] != null) {
        content.writeln('├─ Timestamp: ${result.auditEntry!['timestamp']}');
      }
      content.writeln('└─ Immutable record created on ZKP server');
    }

    return ChatMessage(
      messageId: _generateId(),
      parentMessageId: parentMessageId,
      role: MessageRole.system,
      content: content.toString(),
    );
  }

  /// Create a compact inline badge message
  static ChatMessage createProofBadgeMessage({
    required MCPFileOperationResult result,
    String parentMessageId = '',
  }) {
    final proofTypes = <String>[];

    if (result.accessProof != null && result.accessProof!['success'] == true) {
      proofTypes.add('🔒 Access');
    }
    if (result.integrityProof != null && result.integrityProof!['success'] == true) {
      proofTypes.add('✔️ Integrity');
    }
    if (result.auditEntry != null && result.auditEntry!['success'] == true) {
      proofTypes.add('📋 Audit');
    }

    return ChatMessage(
      messageId: _generateId(),
      parentMessageId: parentMessageId,
      role: MessageRole.system,
      content: '[ZKP Verified: ${proofTypes.join(" | ")}]',
    );
  }

  /// Create a collapsible section message
  /// This returns formatted text that can be rendered as collapsible in UI
  static String createProofSummary({
    required MCPFileOperationResult result,
    required String filePath,
  }) {
    if (!result.success) {
      return '❌ Proof verification failed: ${result.error}';
    }

    final parts = <String>[];

    if (result.accessProof?['success'] == true) {
      parts.add('🔒 Access Proven');
    }
    if (result.integrityProof?['success'] == true) {
      parts.add('✔️ Integrity Verified');
    }
    if (result.auditEntry?['success'] == true) {
      parts.add('📋 Audited');
    }

    return '✅ ZKP Verified (${parts.join(", ")})';
  }

  /// Extract proof metadata for analytics/logging
  static Map<String, dynamic> extractProofMetadata(
    MCPFileOperationResult result,
  ) {
    return {
      'success': result.success,
      'hasAccessProof': result.accessProof?['success'] == true,
      'hasIntegrityProof': result.integrityProof?['success'] == true,
      'hasAuditEntry': result.auditEntry?['success'] == true,
      'fileHash': result.integrityProof?['file_hash'],
      'auditId': result.auditEntry?['audit_id'],
      'timestamp': result.auditEntry?['timestamp'],
      'error': result.error,
    };
  }

  static String _shortenHash(String hash) {
    if (hash.length > 32) {
      return '${hash.substring(0, 16)}...${hash.substring(hash.length - 16)}';
    }
    return hash;
  }

  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
