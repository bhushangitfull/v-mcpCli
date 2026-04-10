// lib/widgets/zkp_proof_display.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget to display ZKP proofs in a beautiful, user-friendly format
class ZKPProofDisplay extends StatelessWidget {
  final Map<String, dynamic>? accessProof;
  final Map<String, dynamic>? integrityProof;
  final Map<String, dynamic>? auditEntry;
  final String filePath;

  const ZKPProofDisplay({
    Key? key,
    this.accessProof,
    this.integrityProof,
    this.auditEntry,
    required this.filePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        border: Border.all(
          color: Colors.blueGrey.shade300,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.verified_user, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Zero-Knowledge Proof Verification',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // File Path
          _buildProofRow(
            context,
            label: '📄 File',
            value: filePath,
            copyable: true,
          ),
          const Divider(height: 16),

          // Access Proof Section
          if (accessProof != null && accessProof!['success'] == true)
            Column(
              children: [
                _buildAccessProofSection(context),
                const Divider(height: 16),
              ],
            ),

          // Integrity Proof Section
          if (integrityProof != null && integrityProof!['success'] == true)
            Column(
              children: [
                _buildIntegrityProofSection(context),
                const Divider(height: 16),
              ],
            ),

          // Audit Entry Section
          if (auditEntry != null && auditEntry!['success'] == true)
            _buildAuditEntrySection(context),
        ],
      ),
    );
  }

  Widget _buildAccessProofSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          children: [
            Icon(Icons.lock_open, color: Colors.green.shade600, size: 18),
            const SizedBox(width: 8),
            Text(
              'Access Control Proof',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Message
        _buildProofRow(
          context,
          label: 'Status',
          value: accessProof?['message'] ?? 'Access verified',
          isStatus: true,
          color: Colors.green,
        ),

        // Proof (shortened)
        if (accessProof?['proof'] != null)
          _buildProofRow(
            context,
            label: 'Proof Hash',
            value: _shortenHash(accessProof!['proof'].toString()),
            copyable: true,
            tooltip: 'Proves access without revealing credentials',
          ),
      ],
    );
  }

  Widget _buildIntegrityProofSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          children: [
            Icon(Icons.verified, color: Colors.purple.shade600, size: 18),
            const SizedBox(width: 8),
            Text(
              'File Integrity Proof',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.purple.shade700,
                    fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // File Hash
        if (integrityProof?['file_hash'] != null)
          _buildProofRow(
            context,
            label: 'File Hash',
            value: _shortenHash(integrityProof!['file_hash'].toString()),
            copyable: true,
            tooltip: 'Merkle root hash of file content',
          ),

        // Total Lines
        if (integrityProof?['total_lines'] != null)
          _buildProofRow(
            context,
            label: 'File Size',
            value: '${integrityProof!['total_lines']} lines',
          ),

        // Verification Status
        _buildProofRow(
          context,
          label: 'Verification',
          value: 'Content integrity verified',
          isStatus: true,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildAuditEntrySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          children: [
            Icon(Icons.history, color: Colors.orange.shade600, size: 18),
            const SizedBox(width: 8),
            Text(
              'Immutable Audit Trail',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Audit ID
        if (auditEntry?['audit_id'] != null)
          _buildProofRow(
            context,
            label: 'Audit ID',
            value: auditEntry!['audit_id'].toString(),
            copyable: true,
          ),

        // Timestamp
        if (auditEntry?['timestamp'] != null)
          _buildProofRow(
            context,
            label: 'Timestamp',
            value: auditEntry!['timestamp'].toString(),
          ),

        // Data Size
        if (auditEntry?['data_size_bytes'] != null)
          _buildProofRow(
            context,
            label: 'Data Size',
            value: '${auditEntry!['data_size_bytes']} bytes',
          ),

        _buildProofRow(
          context,
          label: 'Status',
          value: 'Audit entry recorded',
          isStatus: true,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildProofRow(
    BuildContext context, {
    required String label,
    required String value,
    bool copyable = false,
    bool isStatus = false,
    Color? color,
    String? tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Value
          Expanded(
            child: Tooltip(
              message: tooltip ?? value,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isStatus
                      ? color?.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                  border: isStatus
                      ? Border.all(
                          color: color ?? Colors.grey,
                          width: 0.5,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          color: isStatus ? color : Colors.grey.shade800,
                          fontSize: 12,
                          fontWeight: isStatus ? FontWeight.w600 : null,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (copyable)
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: value));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Copied to clipboard'),
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.content_copy,
                            size: 14,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _shortenHash(String hash) {
    if (hash.length > 32) {
      return '${hash.substring(0, 16)}...${hash.substring(hash.length - 16)}';
    }
    return hash;
  }
}

/// Compact inline version for chat bubbles
class ZKPProofBadge extends StatelessWidget {
  final bool hasAccessProof;
  final bool hasIntegrityProof;
  final bool hasAuditEntry;

  const ZKPProofBadge({
    Key? key,
    this.hasAccessProof = false,
    this.hasIntegrityProof = false,
    this.hasAuditEntry = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final proofCount = [
      hasAccessProof,
      hasIntegrityProof,
      hasAuditEntry,
    ].where((p) => p).length;

    if (proofCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.verified_user,
            size: 14,
            color: Colors.blue.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            '$proofCount proof${proofCount > 1 ? 's' : ''} verified',
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
