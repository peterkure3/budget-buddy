import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget.dart';

class BudgetService {
  static const String _budgetKey = 'budget';

  Future<Budget?> loadBudget() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final budgetJson = prefs.getString(_budgetKey);
      if (budgetJson == null) return null;
      return Budget.fromJson(jsonDecode(budgetJson));
    } catch (e) {
      print('Error loading budget: $e');
      return null;
    }
  }

  Future<bool> saveBudget(Budget budget) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_budgetKey, jsonEncode(budget.toJson()));
    } catch (e) {
      print('Error saving budget: $e');
      return false;
    }
  }
} 