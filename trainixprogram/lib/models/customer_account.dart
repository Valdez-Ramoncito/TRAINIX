import 'package:flutter/material.dart';
import 'package:trainixprogram/services/account_generator_service.dart';

class Account {
  final String accountId;
  final String ownerName;

  //details of the account
  final Map<String, String> details;

  //is this the account that we're looking for
  //in a particular problem?
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

  //can be null because not all customers' problems
  //are account related
  Account? _selectedAccount;

  //is the issue of the current problem resolved?
  bool _issueResolved = false;

  String _searchQuery = '';

  List<Account> get accounts => _accounts;
  Account? get selectedAccount => _selectedAccount;
  bool get issueResolved => _issueResolved;

  //filters accounts that met the searchQuery
  List<Account> get filteredAccounts {
    //if the search field is empty, return all accounts
    if (_searchQuery.isEmpty) return _accounts;

    //to make it not case sensitive
    final q = _searchQuery.toLowerCase();

    //return the accounts that met the searchQuery
    //whether if the agent was searching for an
    //account ID or the owner's name
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
  }) {
    //calls on the account generator service to generate accounts
    //and return it here
    _accounts = AccountGeneratorService.generate(
      sector: sector,
      targetAccountId: targetAccountId,
      problem: problem,
      targetOwnerName: targetOwnerName,
    );
    _selectedAccount = null;
    _issueResolved = false;
    _searchQuery = '';
    notifyListeners();
  }

  void search(String query) {
    //this updates the searchQuery
    _searchQuery = query;
    notifyListeners();
  }

  void selectAccount(Account account) {
    //this updates the account selected by the agent
    _selectedAccount = account;
    notifyListeners();
  }

  void resolveIssue() {
    //this updates if the issue of the customer was resolved
    _issueResolved = true;
    notifyListeners();
  }

  //We reset all the generated accounts, selected account,
  //issue resolved, and searchQuery for the next customer
  void reset() {
    _accounts = [];
    _selectedAccount = null;
    _issueResolved = false;
    _searchQuery = '';
    notifyListeners();
  }
}
