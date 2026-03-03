import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/institution_income_model.dart';
import '../models/org_expense_model.dart';
import '../models/teacher_model.dart';
import '../models/salary_payment_model.dart';
import '../models/user_model.dart';

class InstitutionProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<InstitutionIncomeModel> _incomes = [];
  List<OrgExpenseModel> _orgExpenses = [];
  List<TeacherModel> _teachers = [];
  List<SalaryPaymentModel> _salaryPayments = [];

  bool _isLoading = false;
  String? _error;

  List<InstitutionIncomeModel> get incomes => _incomes;
  List<OrgExpenseModel> get orgExpenses => _orgExpenses;
  List<TeacherModel> get teachers => _teachers;
  List<SalaryPaymentModel> get salaryPayments => _salaryPayments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  UserModel? _activeUser;
  UserModel? get activeUser => _activeUser;

  void updateAuth(UserModel? user) {
    if (_activeUser?.id != user?.id ||
        _activeUser?.organizationId != user?.organizationId ||
        _activeUser?.role != user?.role) {
      _activeUser = user;
      _listenToData();
    }
  }

  void _listenToData() {
    if (_activeUser == null ||
        _activeUser!.organizationId == null ||
        _activeUser!.organizationId!.isEmpty ||
        !(_activeUser!.role == 'org_admin' || _activeUser!.role == 'admin')) {
      _incomes = [];
      _orgExpenses = [];
      _teachers = [];
      _salaryPayments = [];
      notifyListeners();
      return;
    }

    final orgId = _activeUser!.organizationId!;

    // Listen to institution_income
    _firestore
        .collection('institution_income')
        .where('organizationId', isEqualTo: orgId)
        .snapshots()
        .listen(
          (snapshot) {
            debugPrint(
              '[InstitutionProvider] Fetched ${snapshot.docs.length} incomes',
            );
            _incomes = snapshot.docs
                .map(
                  (doc) => InstitutionIncomeModel.fromJson(doc.data(), doc.id),
                )
                .toList();
            _incomes.sort((a, b) => b.incomeDate.compareTo(a.incomeDate));
            notifyListeners();
          },
          onError: (e) {
            debugPrint('[InstitutionProvider] Error on incomes: $e');
            _error = e.toString();
            notifyListeners();
          },
        );

    // Listen to org_expenses
    _firestore
        .collection('org_expenses')
        .where('organizationId', isEqualTo: orgId)
        .snapshots()
        .listen(
          (snapshot) {
            debugPrint(
              '[InstitutionProvider] Fetched ${snapshot.docs.length} orgExpenses',
            );
            _orgExpenses = snapshot.docs
                .map((doc) => OrgExpenseModel.fromJson(doc.data(), doc.id))
                .toList();
            _orgExpenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
            notifyListeners();
          },
          onError: (e) {
            debugPrint('[InstitutionProvider] Error on orgExpenses: $e');
            _error = e.toString();
            notifyListeners();
          },
        );

    // Listen to teachers
    _firestore
        .collection('teachers')
        .where('organizationId', isEqualTo: orgId)
        .snapshots()
        .listen(
          (snapshot) {
            debugPrint(
              '[InstitutionProvider] Fetched ${snapshot.docs.length} teachers',
            );
            _teachers = snapshot.docs
                .map((doc) => TeacherModel.fromJson(doc.data(), doc.id))
                .toList();
            _teachers.sort((a, b) => a.name.compareTo(b.name));
            notifyListeners();
          },
          onError: (e) {
            debugPrint('[InstitutionProvider] Error on teachers: $e');
            _error = e.toString();
            notifyListeners();
          },
        );

    // Listen to salary_payments
    _firestore
        .collection('salary_payments')
        .where('organizationId', isEqualTo: orgId)
        .snapshots()
        .listen(
          (snapshot) {
            debugPrint(
              '[InstitutionProvider] Fetched ${snapshot.docs.length} salaryPayments',
            );
            _salaryPayments = snapshot.docs
                .map((doc) => SalaryPaymentModel.fromJson(doc.data(), doc.id))
                .toList();
            _salaryPayments.sort(
              (a, b) => b.paymentDate.compareTo(a.paymentDate),
            );
            notifyListeners();
          },
          onError: (e) {
            debugPrint('[InstitutionProvider] Error on salaryPayments: $e');
            _error = e.toString();
            notifyListeners();
          },
        );
  }

  Future<void> addIncome(InstitutionIncomeModel income) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      await _firestore.collection('institution_income').add(income.toJson());
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addOrgExpense(OrgExpenseModel expense) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      await _firestore.collection('org_expenses').add(expense.toJson());
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Teacher CRUD ─────────────────────────────────────────────────────────

  Future<void> addTeacher(TeacherModel teacher) async {
    try {
      await _firestore.collection('teachers').add(teacher.toJson());
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> updateTeacher(TeacherModel teacher) async {
    try {
      await _firestore.collection('teachers').doc(teacher.id).update({
        'name': teacher.name,
        'defaultSalary': teacher.defaultSalary,
      });
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  Future<void> deleteTeacher(String teacherId) async {
    try {
      await _firestore.collection('teachers').doc(teacherId).delete();
    } catch (e) {
      _error = e.toString();
      rethrow;
    }
  }

  // ─── Salary Payment CRUD ──────────────────────────────────────────────────

  Future<void> addSalaryPayment(SalaryPaymentModel payment) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      await _firestore.collection('salary_payments').add(payment.toJson());
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Totals ───────────────────────────────────────────────────────────────

  // Get total income within a date range
  double getTotalIncome(DateTime start, DateTime end) {
    return _incomes
        .where(
          (i) =>
              i.incomeDate.isAfter(
                start.subtract(const Duration(seconds: 1)),
              ) &&
              i.incomeDate.isBefore(end.add(const Duration(seconds: 1))),
        )
        .fold(0.0, (acc, i) => acc + i.amount);
  }

  // Get total org expenses within a date range
  double getTotalOrgExpenses(DateTime start, DateTime end) {
    return _orgExpenses
        .where(
          (e) =>
              e.expenseDate.isAfter(
                start.subtract(const Duration(seconds: 1)),
              ) &&
              e.expenseDate.isBefore(end.add(const Duration(seconds: 1))),
        )
        .fold(0.0, (acc, e) => acc + e.amount);
  }

  // Get total salary paid within a date range
  double getTotalSalary(DateTime start, DateTime end) {
    return _salaryPayments
        .where(
          (s) =>
              s.paymentDate.isAfter(
                start.subtract(const Duration(seconds: 1)),
              ) &&
              s.paymentDate.isBefore(end.add(const Duration(seconds: 1))),
        )
        .fold(0.0, (acc, s) => acc + s.paidAmount);
  }
}
