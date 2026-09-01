import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trainixprogram/models/customer_account.dart';

//shared Account Lookup UI, used identically by both the voice and chat
//channels.
class AccountLookupView extends StatefulWidget {
  //current sector, used only to pick the right action-button label
  final String sector;

  const AccountLookupView({super.key, required this.sector});

  @override
  State<AccountLookupView> createState() => _AccountLookupViewState();
}

class _AccountLookupViewState extends State<AccountLookupView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AccountProvider>(
      builder: (context, accountProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: accountProvider.search,
                      decoration: const InputDecoration(
                        labelText: 'Search by account ID or name',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (accountProvider.accounts.isEmpty)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'No account lookup needed for this conversation.\n'
                        'If you\'ve resolved the issue through guidance, '
                        'troubleshooting, or an escalation, the customer '
                        'should wrap up naturally on their own. If they '
                        'don\'t, you can close it out manually below.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      if (accountProvider.issueResolved)
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Issue resolved',
                              style: TextStyle(color: Colors.green),
                            ),
                          ],
                        )
                      else
                        ElevatedButton(
                          onPressed: accountProvider.resolveIssue,
                          child: const Text('Mark as Resolved'),
                        ),
                    ],
                  ),
                )
              else ...[
                const Text(
                  'Accounts',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    itemCount: accountProvider.filteredAccounts.length,
                    itemBuilder: (_, index) {
                      final account = accountProvider.filteredAccounts[index];
                      final isSelected =
                          accountProvider.selectedAccount?.accountId ==
                          account.accountId;
                      return ListTile(
                        dense: true,
                        selected: isSelected,
                        title: Text(
                          '${account.accountId}    ${account.ownerName}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () => accountProvider.selectAccount(account),
                      );
                    },
                  ),
                ),
                const Divider(),
                if (accountProvider.selectedAccount != null) ...[
                  const Text(
                    'Account Details',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  ...accountProvider.selectedAccount!.details.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        '${e.key}: ${e.value}',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              e.key == 'Issue' &&
                                  accountProvider.selectedAccount!.isTarget
                              ? Colors.red
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (accountProvider.issueResolved)
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Issue resolved in system',
                          style: TextStyle(color: Colors.green),
                        ),
                      ],
                    )
                  else if (accountProvider.selectedAccount!.isTarget)
                    ElevatedButton(
                      onPressed: accountProvider.resolveIssue,
                      child: Text(_getActionLabel(widget.sector)),
                    )
                  else
                    const Text(
                      'This is not the customer\'s account.',
                      style: TextStyle(color: Colors.orange, fontSize: 12),
                    ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  //Return the appropriate action-button text for the given sector
  String _getActionLabel(String sector) {
    switch (sector) {
      case 'Finance':
        return 'Apply Financial Adjustment';
      case 'Healthcare':
        return 'Process Healthcare Request';
      case 'Telco':
        return 'Restore Service';
      default:
        return 'Apply Technical Fix';
    }
  }
}
