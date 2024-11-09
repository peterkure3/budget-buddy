import 'package:flutter/foundation.dart';

class Transaction {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String? categoryId;

  Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    this.categoryId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        description: json['description'],
        amount: json['amount'],
        date: DateTime.parse(json['date']),
      );
} 