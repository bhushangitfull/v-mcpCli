// Integration Guide: Using ZKP Proofs in Chat
// File: lib/page/layout/chat_page/zkp_integration_guide.md

# ZKP Proof Display Integration Guide

## Overview
This guide shows how to integrate zero-knowledge proof verification displays into your chat interface.

## Components

### 1. **ZKPProofDisplay Widget** (lib/widgets/zkp_proof_display.dart)
Visual component for displaying full proof details in a styled container.

```dart
// Full proof display
ZKPProofDisplay(
  accessProof: result.accessProof,
  integrityProof: result.integrityProof,
  auditEntry: result.auditEntry,
  filePath: selectedFilePath,
)

// Compact badge
ZKPProofBadge(
  hasAccessProof: result.accessProof?['success'] == true,
  hasIntegrityProof: result.integrityProof?['success'] == true,
  hasAuditEntry: result.auditEntry?['success'] == true,
)
```

### 2. **ZKPChatMessageHelper** (lib/utils/zkp_chat_message_helper.dart)
Converts proof results into chat messages for display.

```dart
// Create detailed proof message
final proofMessage = ZKPChatMessageHelper.createProofVerificationMessage(
  result: zkpResult,
  filePath: filePath,
  operation: 'read_file',
  parentMessageId: _parentMessageId,
);
_messages.add(proofMessage);

// Create compact badge
final badgeMessage = ZKPChatMessageHelper.createProofBadgeMessage(
  result: zkpResult,
  parentMessageId: _parentMessageId,
);
_messages.add(badgeMessage);

// Get summary text
final summary = ZKPChatMessageHelper.createProofSummary(
  result: zkpResult,
  filePath: filePath,
);
```

## Implementation in chat_page.dart

### Step 1: Add imports
```dart
import 'package:chatmcp/widgets/zkp_proof_display.dart';
import 'package:chatmcp/utils/zkp_chat_message_helper.dart';
```

### Step 2: Modify _sendToolCallAndProcessResponse to capture ZKP proofs

```dart
Future<void> _sendToolCallAndProcessResponse(
  String toolName,
  Map<String, dynamic> toolArguments,
) async {
  // ... existing code ...

  // When tool execution is filesystem MCP tool with ZKP
  if (toolName.contains('file') || toolName.contains('search')) {
    // Execute with ZKP handler
    final zkpResult = await _zkpMCPHandler?.processFileOperationWithZKP(
      filePath: toolArguments['path'] ?? toolArguments['file_path'] ?? '',
      operation: toolName,
      userId: currentUserId,
      operationParams: toolArguments,
    );

    if (zkpResult != null) {
      // Display proof verification message
      if (zkpResult.success) {
        final proofMessage = ZKPChatMessageHelper.createProofVerificationMessage(
          result: zkpResult,
          filePath: toolArguments['path'] ?? '',
          operation: toolName,
          parentMessageId: _parentMessageId,
        );
        
        setState(() {
          _messages.add(proofMessage);
        });

        // Log proof metadata
        Logger.root.info(
          'ZKP Proof: ${ZKPChatMessageHelper.extractProofMetadata(zkpResult)}',
        );
      } else {
        // Display error
        setState(() {
          _messages.add(ChatMessage(
            messageId: const Uuid().v4(),
            parentMessageId: _parentMessageId,
            role: MessageRole.system,
            content: '❌ Proof verification failed: ${zkpResult.error}',
          ));
        });
      }
    }
  }
}
```

### Step 3: Display proofs in Chat Message Bubble

Modify your `ChatMessageBubble` or message display widget:

```dart
// In chat_message_list.dart or chat_message_bubble.dart

@override
Widget build(BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Original message content
      _buildMessageContent(context),

      // Add ZKP proof display if present
      if (message.role == MessageRole.system && 
          message.content.contains('ZKP Verification')) {
        _buildZKPProofSection(context),
      },
    ],
  );
}

Widget _buildZKPProofSection(BuildContext context) {
  // Parse the system message to extract proof data
  // or store proof data directly in ChatMessage metadata
  return Container(
    margin: const EdgeInsets.only(top: 8),
    child: ZKPProofDisplay(
      // Parse from message or retrieve from state
      accessProof: /* extracted from message */,
      integrityProof: /* extracted from message */,
      auditEntry: /* extracted from message */,
      filePath: /* extracted from message */,
    ),
  );
}
```

### Step 4: Extend ChatMessage to Store Proof Metadata

Modify [lib/dao/chat.dart](lib/dao/chat.dart) to include optional proof data:

```dart
class ChatMessage {
  // ... existing fields ...
  
  // ZKP proof metadata
  final Map<String, dynamic>? zkpProofData;
  
  ChatMessage({
    required String messageId,
    // ... existing parameters ...
    this.zkpProofData,
  });
}
```

Then use it:

```dart
final proofMessage = ChatMessage(
  messageId: const Uuid().v4(),
  parentMessageId: _parentMessageId,
  role: MessageRole.system,
  content: 'File operation with ZKP verification',
  zkpProofData: {
    'accessProof': zkpResult.accessProof,
    'integrityProof': zkpResult.integrityProof,
    'auditEntry': zkpResult.auditEntry,
    'filePath': filePath,
    'operation': operation,
  },
);

_messages.add(proofMessage);
```

## Display Strategies

### Strategy 1: Inline with Content (Recommended)
Show proof badge with file content, expandable on tap:

```
User: Show me config.dart
Assistant: [File content here]
🔒 3 proofs verified (Access | Integrity | Audit)
[Tap to expand proof details]
```

### Strategy 2: Separate System Messages
Display proofs as separate messages after file content:

```
User: Show me config.dart
Assistant: [File content here]
System: ✅ ZKP Verification Complete
├─ 🔒 Access Proof: [hash...]
├─ ✔️ Integrity Proof: [hash...]
└─ 📋 Audit Trail: [ID...]
```

### Strategy 3: Collapsible Card
Show collapsible card in chat:

```
User: Show me config.dart
Assistant: [File content here]
┌─────────────────────────────┐
│ ✅ ZKP Verification ▼       │
├─────────────────────────────┤
│ [Expanded proof details]    │
└─────────────────────────────┘
```

### Strategy 4: Toast Notification
Show proof status as floating toast:

```
Toast: "✅ File verified with 3 proofs (Access, Integrity, Audit)"
```

## Best Practices

1. **Always show proof status** - User should know file operations are verified
2. **Make it clickable** - Allow users to expand/collapse proof details
3. **Color coding** - Green for success, red for failure, blue for info
4. **Icons** - Use consistent icons: 🔒 access, ✔️ integrity, 📋 audit
5. **Log metadata** - Always log proof hashes for debugging
6. **Handle offline** - Gracefully degrade if ZKP server is unavailable

## Example: Full Setup

```dart
// In _handleSubmitted or _sendToolCallAndProcessResponse

final zkpResult = await _zkpMCPHandler.processFileOperationWithZKP(
  filePath: filePath,
  operation: 'read_file',
  userId: userId,
);

if (zkpResult.success) {
  // Add file content message
  setState(() {
    _messages.add(ChatMessage(
      messageId: const Uuid().v4(),
      parentMessageId: _parentMessageId,
      role: MessageRole.assistant,
      content: zkpResult.content,
      zkpProofData: {
        'accessProof': zkpResult.accessProof,
        'integrityProof': zkpResult.integrityProof,
        'auditEntry': zkpResult.auditEntry,
        'filePath': filePath,
      },
    ));
  });

  // Log proof metadata for analytics
  Logger.root.info(
    'ZKP Proof Metadata: ${ZKPChatMessageHelper.extractProofMetadata(zkpResult)}',
  );
}
```

## Testing

```dart
// Test proof display
void testZKPProofDisplay() {
  const mockResult = MCPFileOperationResult(
    success: true,
    content: 'test content',
    accessProof: {
      'success': true,
      'message': 'Access proven',
      'proof': {'response': 'mock_proof_hash'},
    },
    integrityProof: {
      'success': true,
      'file_hash': 'abc123...def456',
      'total_lines': 42,
    },
    auditEntry: {
      'success': true,
      'audit_id': 'audit_123',
      'timestamp': '2026-04-10T10:00:00Z',
    },
  );

  final message = ZKPChatMessageHelper.createProofVerificationMessage(
    result: mockResult,
    filePath: 'lib/example.dart',
    operation: 'read_file',
  );

  expect(message.role, MessageRole.system);
  expect(message.content, contains('✅ ZKP Verification Complete'));
  expect(message.content, contains('🔒 ACCESS PROOF'));
  expect(message.content, contains('✔️ FILE INTEGRITY PROOF'));
  expect(message.content, contains('📋 AUDIT TRAIL'));
}
```
