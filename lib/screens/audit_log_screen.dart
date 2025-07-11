import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../services/audit_service.dart';

class AuditLogScreen extends StatefulWidget {
  final String? certificateId;
  final String? userId;
  
  const AuditLogScreen({
    super.key,
    this.certificateId,
    this.userId,
  });

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final AuditService _auditService = AuditService();
  List<Map<String, dynamic>> _auditLogs = [];
  bool _isLoading = true;
  String _filterAction = 'All';
  DateTime? _startDate;
  DateTime? _endDate;

  final List<String> _actionFilters = [
    'All',
    'certificateCreated',
    'certificateIssued',
    'certificateApproved',
    'certificateRejected',
    'certificateViewed',
    'certificateDownloaded',
    'certificateShared',
    'signatureAdded',
    'watermarkApplied',
    'userLogin',
    'userLogout',
    'roleChanged',
  ];

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _isLoading = true);
    
    try {
      List<Map<String, dynamic>> logs;
      
      if (widget.certificateId != null) {
        logs = await _auditService.getCertificateAuditLogs(widget.certificateId!);
      } else if (widget.userId != null) {
        logs = await _auditService.getUserAuditLogs(widget.userId!);
      } else {
        logs = await _auditService.getAllAuditLogs(limit: 200);
      }
      
      setState(() {
        _auditLogs = logs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading audit logs: $e')),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredLogs {
    return _auditLogs.where((log) {
      // Filter by action
      if (_filterAction != 'All' && log['action'] != _filterAction) {
        return false;
      }
      
      // Filter by date range
      if (_startDate != null || _endDate != null) {
        final timestamp = log['timestamp'] as Timestamp?;
        if (timestamp == null) return false;
        
        final logDate = timestamp.toDate();
        
        if (_startDate != null && logDate.isBefore(_startDate!)) {
          return false;
        }
        
        if (_endDate != null && logDate.isAfter(_endDate!)) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown';
    final date = timestamp.toDate();
    return DateFormat('MMM dd, yyyy HH:mm:ss').format(date);
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'certificateCreated':
      case 'certificateIssued':
      case 'certificateApproved':
      case 'signatureAdded':
      case 'watermarkApplied':
        return Colors.green;
      case 'certificateRejected':
      case 'certificateRevoked':
        return Colors.red;
      case 'certificateViewed':
      case 'certificateDownloaded':
      case 'certificateShared':
        return Colors.blue;
      case 'userLogin':
      case 'userLogout':
        return Colors.orange;
      case 'roleChanged':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'certificateCreated':
        return Icons.add_circle;
      case 'certificateIssued':
        return Icons.verified;
      case 'certificateApproved':
        return Icons.check_circle;
      case 'certificateRejected':
        return Icons.cancel;
      case 'certificateViewed':
        return Icons.visibility;
      case 'certificateDownloaded':
        return Icons.download;
      case 'certificateShared':
        return Icons.share;
      case 'signatureAdded':
        return Icons.edit;
      case 'watermarkApplied':
        return Icons.water_drop;
      case 'userLogin':
        return Icons.login;
      case 'userLogout':
        return Icons.logout;
      case 'roleChanged':
        return Icons.admin_panel_settings;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.certificateId != null 
          ? 'Certificate Audit Log' 
          : widget.userId != null 
            ? 'User Audit Log' 
            : 'System Audit Log'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAuditLogs,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                // Action filter
                Row(
                  children: [
                    const Text('Action: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _filterAction,
                      items: _actionFilters.map((action) => DropdownMenuItem(
                        value: action,
                        child: Text(action),
                      )).toList(),
                      onChanged: (value) {
                        setState(() => _filterAction = value!);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Date filters
                Row(
                  children: [
                    const Text('Date Range: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _startDate = date);
                        }
                      },
                      child: Text(_startDate == null 
                        ? 'Start Date' 
                        : DateFormat('MMM dd, yyyy').format(_startDate!)),
                    ),
                    const Text(' to '),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _endDate = date);
                        }
                      },
                      child: Text(_endDate == null 
                        ? 'End Date' 
                        : DateFormat('MMM dd, yyyy').format(_endDate!)),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                        });
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Audit logs list
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredLogs.isEmpty
                ? const Center(child: Text('No audit logs found'))
                : ListView.builder(
                    itemCount: _filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = _filteredLogs[index];
                      final action = log['action'] as String? ?? 'unknown';
                      final description = log['description'] as String? ?? 'No description';
                      final timestamp = log['timestamp'] as Timestamp?;
                      final userEmail = log['userEmail'] as String? ?? 'Unknown';
                      final userRole = log['userRole'] as String? ?? 'Unknown';
                      final metadata = log['metadata'] as Map<String, dynamic>? ?? {};
                      
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getActionColor(action),
                            child: Icon(
                              _getActionIcon(action),
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            description,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Action: $action'),
                              Text('User: $userEmail ($userRole)'),
                              Text('Time: ${_formatTimestamp(timestamp)}'),
                              if (metadata.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Details: ${metadata.toString()}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          isThreeLine: true,
                          onTap: () {
                            _showLogDetails(log);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showLogDetails(Map<String, dynamic> log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Audit Log Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Action', log['action'] ?? 'Unknown'),
              _buildDetailRow('Description', log['description'] ?? 'No description'),
              _buildDetailRow('User Email', log['userEmail'] ?? 'Unknown'),
              _buildDetailRow('User Role', log['userRole'] ?? 'Unknown'),
              _buildDetailRow('User ID', log['userId'] ?? 'Unknown'),
              _buildDetailRow('Target ID', log['targetId'] ?? 'N/A'),
              _buildDetailRow('Target Type', log['targetType'] ?? 'N/A'),
              _buildDetailRow('Timestamp', _formatTimestamp(log['timestamp'])),
              if (log['metadata'] != null) ...[
                const SizedBox(height: 8),
                const Text('Metadata:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  const JsonEncoder().convert(log['metadata']),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
} 