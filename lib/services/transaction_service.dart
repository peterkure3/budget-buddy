import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';

class TransactionService {
  static const String _storageKey = 'transactions';

  Future<List<Transaction>> loadTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = prefs.getStringList(_storageKey) ?? [];
      return transactionsJson
          .map((json) => Transaction.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      // Handle error appropriately
      print('Error loading transactions: $e');
      return [];
    }
  }

  Future<bool> saveTransactions(List<Transaction> transactions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsJson = transactions
          .map((transaction) => jsonEncode(transaction.toJson()))
          .toList();
      return await prefs.setStringList(_storageKey, transactionsJson);
    } catch (e) {
      print('Error saving transactions: $e');
      return false;
    }
  }
} 