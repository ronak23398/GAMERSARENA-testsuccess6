import 'package:flutter/material.dart';
import 'package:gamers_gram/data/models/wallet_model.dart';
import 'package:intl/intl.dart';

class TransactionTile extends StatelessWidget {
  final WalletTransaction transaction;

  const TransactionTile({
    super.key,
    required this.transaction,
  });

  Color _getStatusColor() {
    switch (transaction.status) {
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

  IconData _getTransactionIcon() {
    switch (transaction.type) {
      case 'deposit':
        return Icons.add_circle_outline;
      case 'withdrawal':
        return Icons.remove_circle_outline;
      case 'freeze':
        return Icons.ac_unit;
      case 'unfreeze':
        return Icons.water_drop_outlined;
      case 'win':
        return Icons.emoji_events_outlined;
      case 'loss':
        return Icons.sentiment_dissatisfied_outlined;
      default:
        return Icons.swap_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        _getTransactionIcon(),
        color: _getStatusColor(),
        size: 28,
      ),
      title: Text(
        transaction.description,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        DateFormat('MMM dd, yyyy HH:mm').format(transaction.timestamp),
        style: TextStyle(
          color: Colors.grey[600],
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '₹${transaction.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: transaction.type == 'withdrawal' ||
                      transaction.type == 'freeze' ||
                      transaction.type == 'loss'
                  ? Colors.red
                  : Colors.green,
            ),
          ),
          Text(
            transaction.status,
            style: TextStyle(
              fontSize: 12,
              color: _getStatusColor(),
            ),
          ),
        ],
      ),
    );
  }
}
