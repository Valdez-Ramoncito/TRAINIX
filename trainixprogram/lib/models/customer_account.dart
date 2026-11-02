import 'package:flutter/material.dart';
import 'package:trainixprogram/models/sim_flow_log.dart';
import 'package:trainixprogram/services/account_generator_service.dart';

class Account {
  final String accountId;
  final String ownerName;
  final Map<String, String> details;
  final bool isTarget;

  const Account({
    required this.accountId,
    required this.ownerName,
    required this.details,
    this.isTarget = false,
  });
}

class AccountProvider with ChangeNotifier {
  List<Account> _accounts = [];
  Account? _selectedAccount;
  bool _toolWorkDone = false;
  bool _identityVerified = false;
  String _lastToolAction = '';
  String _lastToolNote = '';
  bool _customerConfirmedResolved = false;
  String _searchQuery = '';
  bool _needsAccount = false;
  bool _casePackSession = false;

  List<Account> get accounts => _accounts;
  Account? get selectedAccount => _selectedAccount;
  bool get toolWorkDone => _toolWorkDone;
  bool get identityVerified => _identityVerified;
  String get lastToolAction => _lastToolAction;
  String get lastToolNote => _lastToolNote;
  bool get customerConfirmedResolved => _customerConfirmedResolved;
  bool get issueResolved => _customerConfirmedResolved;
  bool get needsAccount => _needsAccount;
  bool get casePackSession => _casePackSession;
  bool get accountGateSatisfied => !_needsAccount || _selectedAccount != null;

  void configureCaseGates({
    required bool needsAccount,
    required bool casePackSession,
    bool notify = true,
  }) {
    _needsAccount = needsAccount;
    _casePackSession = casePackSession;
    if (notify) notifyListeners();
  }

  List<Account> get filteredAccounts {
    if (_searchQuery.isEmpty) return _accounts;
    final q = _searchQuery.toLowerCase();
    return _accounts
        .where(
          (a) =>
              a.accountId.toLowerCase().contains(q) ||
              a.ownerName.toLowerCase().contains(q),
        )
        .toList();
  }

  void generateAccounts({
    required String sector,
    required String targetAccountId,
    required String problem,
    required String targetOwnerName,
    Map<String, String> targetDetailExtras = const {},
    bool notify = true,
  }) {
    _accounts = AccountGeneratorService.generate(
      sector: sector,
      targetAccountId: targetAccountId,
      problem: problem,
      targetOwnerName: targetOwnerName,
      targetDetailExtras: targetDetailExtras,
    );
    _selectedAccount = null;
    _toolWorkDone = false;
    _identityVerified = false;
    _lastToolAction = '';
    _lastToolNote = '';
    _customerConfirmedResolved = false;
    _searchQuery = '';
    if (notify) notifyListeners();
  }

  void search(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void selectAccount(Account account) {
    _selectedAccount = account;
    SimFlowLog.block('account.select', {
      'owner': account.ownerName,
      'id': account.accountId,
      'details': account.details.toString(),
    });
    notifyListeners();
  }

  void markToolWorkDone({String action = '', String note = ''}) {
    final a = action.trim();
    _lastToolAction = a;
    _lastToolNote = note.trim();
    final isIdentity =
        a.toLowerCase().contains('identity') ||
        a.toLowerCase().contains('verify');
    if (isIdentity) {
      _identityVerified = true;
    } else if (a.isNotEmpty) {
      _toolWorkDone = true;
    } else {
      _toolWorkDone = true;
    }
    SimFlowLog.block('account.tool', {
      'action': a,
      'note': note,
      'identityVerified': _identityVerified,
      'toolWorkDone': _toolWorkDone,
      'selected': _selectedAccount?.ownerName,
      'coverage': _selectedAccount?.details['Coverage'],
    });
    notifyListeners();
  }

  void resolveIssue() {
    markToolWorkDone();
  }

  void confirmCustomerResolved() {
    _customerConfirmedResolved = true;
    notifyListeners();
  }

  void reset({bool notify = true}) {
    _accounts = [];
    _selectedAccount = null;
    _toolWorkDone = false;
    _identityVerified = false;
    _lastToolAction = '';
    _lastToolNote = '';
    _customerConfirmedResolved = false;
    _searchQuery = '';
    _needsAccount = false;
    _casePackSession = false;
    if (notify) notifyListeners();
  }

  void notifyNow() {
    notifyListeners();
  }
}
