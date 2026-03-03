import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';
import '../models/user_model.dart';

class ExpenseProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<ExpenseModel> _expenses = [];
  bool _isLoading = false;
  String? _error;

  List<ExpenseModel> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  UserModel? _activeUser;

  void updateAuth(UserModel? user) {
    if (_activeUser?.id != user?.id ||
        _activeUser?.organizationId != user?.organizationId ||
        _activeUser?.role != user?.role) {
      _activeUser = user;
      _listenToExpenses();
    }
  }

  // Real-time listener subscription
  void _listenToExpenses() {
    if (_activeUser == null ||
        _activeUser!.organizationId == null ||
        _activeUser!.organizationId!.isEmpty) {
      _expenses = [];
      notifyListeners();
      return;
    }

    // Super admins shouldn't see expenses.
    if (_activeUser!.role == 'super_admin' ||
        _activeUser!.role == 'superadmin') {
      _expenses = [];
      notifyListeners();
      return;
    }

    Query query = _firestore
        .collection('expenses')
        .where('organizationId', isEqualTo: _activeUser!.organizationId);

    // Collectors can only see their own expenses
    if (_activeUser!.role == 'collector') {
      query = query.where('collectorId', isEqualTo: _activeUser!.id);
    }

    query.snapshots().listen(
      (snapshot) {
        _expenses = snapshot.docs
            .map(
              (doc) => ExpenseModel.fromJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList();

        // Sort explicitly by expenseDate descending locally if needed,
        // or just by createdAt descending if no index exists on the server.
        _expenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));

        _error = null;
        notifyListeners();
      },
      onError: (e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> addExpense(ExpenseModel expense) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('expenses').add(expense.toJson());
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateExpenseStatus(String expenseId, String newStatus) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _firestore.collection('expenses').doc(expenseId).update({
        'status': newStatus,
      });
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
