import 'package:flutter/material.dart';
import '../services/donation_service.dart';

class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({super.key});

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
  List<Map<String, dynamic>> _donations = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDonationData();
  }

  Future<void> _loadDonationData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final donations = await DonationService.getDonationHistory();
      final stats = await DonationService.getDonationStats();

      setState(() {
        _donations = donations;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load donation history: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal[50],
      appBar: AppBar(
        title: Text('Donation History'),
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadDonationData),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.teal),
                    SizedBox(height: 16),
                    Text('Loading donation history...'),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadDonationData,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Statistics Cards
                      _buildStatsSection(),
                      SizedBox(height: 24),

                      // Donation History
                      Text(
                        'Your Donation History',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      SizedBox(height: 16),

                      if (_donations.isEmpty)
                        _buildEmptyState()
                      else
                        _buildDonationList(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildStatsSection() {
    return Column(
      children: [
        // Total Donations Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.teal[700]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.3),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Donated',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        DonationService.formatCurrency(
                          _stats['totalAmount'] ?? 0.0,
                          'myr',
                        ),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.favorite, color: Colors.white, size: 40),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(
                    'Total Donations',
                    '${_stats['totalDonations'] ?? 0}',
                    Icons.receipt_long,
                  ),
                  _buildStatItem(
                    'Average Amount',
                    DonationService.formatCurrency(
                      _stats['averageAmount'] ?? 0.0,
                      'myr',
                    ),
                    Icons.trending_up,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(Icons.favorite_border, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No donations yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Make your first donation to support our project!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.favorite),
            label: Text('Donate Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              // Navigate to donation screen
              Navigator.pushNamed(context, '/donation');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDonationList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _donations.length,
      itemBuilder: (context, index) {
        final donation = _donations[index];
        final date = DateTime.parse(donation['date']);
        final amount = donation['amount'] as num;
        final status = donation['status'] as String;
        final transactionId = donation['transactionId'] as String?;

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getStatusIcon(status),
                color: _getStatusColor(status),
                size: 24,
              ),
            ),
            title: Row(
              children: [
                Text(
                  DonationService.formatCurrency(amount.toDouble(), 'myr'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                Text(
                  _formatDate(date),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                if (transactionId != null) ...[
                  SizedBox(height: 2),
                  Text(
                    'ID: $transactionId',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
            trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
            onTap: () => _showDonationDetails(donation),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'failed':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showDonationDetails(Map<String, dynamic> donation) {
    final date = DateTime.parse(donation['date']);
    final amount = donation['amount'] as num;
    final status = donation['status'] as String;
    final transactionId = donation['transactionId'] as String?;
    final currency = donation['currency'] as String? ?? 'myr';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                SizedBox(width: 8),
                Text('Donation Details'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  'Amount',
                  DonationService.formatCurrency(amount.toDouble(), currency),
                ),
                _buildDetailRow('Status', status.toUpperCase()),
                _buildDetailRow('Date', _formatDate(date)),
                if (transactionId != null)
                  _buildDetailRow('Transaction ID', transactionId),
                _buildDetailRow('Currency', currency.toUpperCase()),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[800])),
          ),
        ],
      ),
    );
  }
}
