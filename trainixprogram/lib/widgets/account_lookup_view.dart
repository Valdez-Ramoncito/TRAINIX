import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
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
  final TextEditingController _actionNoteController = TextEditingController();
  final ScrollController _listScrollController = ScrollController();
  final GlobalKey _detailsKey = GlobalKey();
  String _selectedAction = 'Confirm identity on file';

  @override
  void dispose() {
    _searchController.dispose();
    _actionNoteController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  void _applyNoteForAction(String action, Account? account) {
    final issue = account?.details['Issue'] ?? 'Customer request';
    final ending =
        account?.details['Card Ending'] ??
        account?.details['Member ID'] ??
        account?.details['Mobile Ending'] ??
        account?.details['Email'] ??
        '';
    final lower = action.toLowerCase();
    String note;
    if (lower.contains('identity') || lower.contains('verify')) {
      note = ending.isEmpty
          ? 'Matched customer name on file for $issue.'
          : 'Matched name and reference ($ending) on file for $issue.';
    } else if (lower.contains('service request') || lower.contains('file')) {
      note = 'Filed service request for: $issue.';
    } else if (lower.contains('callback')) {
      note = 'Scheduled callback regarding: $issue.';
    } else if (lower.contains('ticket') || lower.contains('review')) {
      note = 'Opened review ticket for: $issue.';
    } else if (lower.contains('escalat')) {
      note = 'Escalated to specialist for: $issue.';
    } else {
      note = 'Recorded action for: $issue.';
    }
    _actionNoteController.text = note;
  }

  void _submitAccountAction(AccountProvider accountProvider) {
    if (accountProvider.selectedAccount == null) return;
    final action = _selectedAction;
    if (_actionNoteController.text.trim().isEmpty) {
      _applyNoteForAction(action, accountProvider.selectedAccount);
    }
    final note = _actionNoteController.text.trim();
    accountProvider.markToolWorkDone(action: action, note: note);
    final isIdentity =
        action.toLowerCase().contains('identity') ||
        action.toLowerCase().contains('verify');
    final msg = isIdentity
        ? 'Identity confirmed on file.'
        : 'Recorded: $action';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        backgroundColor: const Color(0xFF14532D),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
    setState(() {});
  }

  void _scrollToDetails() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _detailsKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          alignment: 0.05,
        );
        return;
      }
      if (_listScrollController.hasClients) {
        _listScrollController.animateTo(
          _listScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark
        ? Theme.of(context).colorScheme.surface
        : const Color(0xFF0B0F17);

    return Consumer<AccountProvider>(
      builder: (context, accountProvider, child) {
        return Padding(
          padding: const EdgeInsets.only(top: 20.0, left: 20, right: 20),
          child: SingleChildScrollView(
            controller: _listScrollController,
            child: Container(
              color: bgColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (accountProvider.needsAccount) ...[
                    _buildSearchInput(accountProvider),
                    const Gap(20),
                  ],

                  if (accountProvider.identityVerified ||
                      accountProvider.toolWorkDone) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14532D),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF22C55E)),
                      ),
                      child: Text(
                        accountProvider.toolWorkDone
                            ? 'Action recorded: ${accountProvider.lastToolAction.isEmpty ? 'Service action submitted' : accountProvider.lastToolAction}'
                            : 'Identity confirmed on file. You can explain findings or submit a service request next.',
                        style: const TextStyle(
                          color: Color(0xFFBBF7D0),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  if (!accountProvider.needsAccount)
                    _buildNoAccountsView(accountProvider)
                  else if (accountProvider.accounts.isEmpty)
                    _buildNoAccountsView(accountProvider)
                  else ...[
                    _buildAccountsListHeader(accountProvider),
                    const Gap(12),
                    _buildAccountsList(accountProvider),
                    const Gap(24),
                    if (accountProvider.selectedAccount != null) ...[
                      KeyedSubtree(
                        key: _detailsKey,
                        child: _buildAccountDetails(accountProvider),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Modern Search Bar Input
  Widget _buildSearchInput(AccountProvider accountProvider) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 27, 28, 30)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 22),
          const Gap(12),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: accountProvider.search,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Search by account ID or customer name...',
                hintStyle: TextStyle(
                  color: Color.fromARGB(255, 91, 92, 93),
                  fontSize: 14,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                accountProvider.search('');
                setState(() {});
              },
              child: const Icon(
                Icons.close_rounded,
                color: Color(0xFF9CA3AF),
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  // View displayed when no accounts are required/generated
  Widget _buildNoAccountsView(AccountProvider accountProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color.fromARGB(130, 28, 28, 28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color.fromARGB(255, 40, 40, 40)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 40, 41, 41),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_turned_in_rounded,
              color: Color.fromARGB(255, 247, 247, 248),
              size: 32,
            ),
          ),
          const Gap(16),
          Text(
            accountProvider.needsAccount
                ? 'No Matching Accounts Yet'
                : 'No Account Lookup Needed',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(10),
          Text(
            accountProvider.needsAccount
                ? 'Ask the customer for identity details, then search again. Select the correct account before applying any account action.'
                : 'This case does not need Account Lookup. Clarify what the customer needs, give a clear answer or next step, and confirm they understand.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const Gap(24),
          if (accountProvider.customerConfirmedResolved)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF059669)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF34D399),
                    size: 20,
                  ),
                  Gap(8),
                  Text(
                    'Customer confirmed resolved',
                    style: TextStyle(
                      color: Color(0xFF34D399),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else if (accountProvider.toolWorkDone)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A5F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3B82F6)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.build_circle_outlined,
                    color: Color(0xFF93C5FD),
                    size: 20,
                  ),
                  Gap(8),
                  Text(
                    'Tool work noted. Wait for customer confirmation.',
                    style: TextStyle(
                      color: Color(0xFF93C5FD),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else ...[
            const Text(
              'Account action',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            ),
            const Gap(8),
            DropdownButtonFormField<String>(
              value: _selectedAction,
              dropdownColor: const Color(0xFF1A1F26),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF121212),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Confirm identity on file',
                  child: Text('Confirm identity on file'),
                ),
                DropdownMenuItem(
                  value: 'File service request',
                  child: Text('File service request'),
                ),
                DropdownMenuItem(
                  value: 'Schedule callback',
                  child: Text('Schedule callback'),
                ),
                DropdownMenuItem(
                  value: 'Open review ticket',
                  child: Text('Open review ticket'),
                ),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _selectedAction = v;
                    _applyNoteForAction(v, accountProvider.selectedAccount);
                  });
                }
              },
            ),
            const Gap(10),
            TextField(
              controller: _actionNoteController,
              maxLines: 2,
              readOnly: true,
              style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Note fills in when you pick an action',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFF0F1419),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Gap(12),
            ElevatedButton.icon(
              onPressed: accountProvider.selectedAccount == null
                  ? null
                  : () => _submitAccountAction(accountProvider),
              icon: const Icon(Icons.task_alt, size: 18),
              label: Text(_submitLabelForAction(_selectedAction)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Header section above the account list
  Widget _buildAccountsListHeader(AccountProvider accountProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.badge_outlined, color: Color(0xFF3B82F6), size: 20),
            Gap(8),
            Text(
              'Customer Accounts',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${accountProvider.filteredAccounts.length} found',
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Filtered account cards list
  Widget _buildAccountsList(AccountProvider accountProvider) {
    final filtered = accountProvider.filteredAccounts;

    if (filtered.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 28, 29, 29),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color.fromARGB(255, 50, 51, 54)),
        ),
        child: const Text(
          'No matching accounts found.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color.fromARGB(255, 181, 184, 189),
            fontSize: 13,
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const Gap(10),
      itemBuilder: (context, index) {
        final account = filtered[index];
        final isSelected =
            accountProvider.selectedAccount?.accountId == account.accountId;

        return GestureDetector(
          onTap: () {
            accountProvider.selectAccount(account);
            if (account.isTarget) {
              _applyNoteForAction(_selectedAction, account);
            }
            _scrollToDetails();
            setState(() {});
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1E293B)
                  : const Color.fromARGB(255, 28, 29, 29),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : const Color.fromARGB(255, 42, 44, 45),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isSelected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF1F2937),
                  child: Text(
                    account.ownerName.isNotEmpty
                        ? account.ownerName[0].toUpperCase()
                        : 'A',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Gap(14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.ownerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        'ID: ${account.accountId}',
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF3B82F6),
                    size: 22,
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF475569),
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Selected account detail card
  Widget _buildAccountDetails(AccountProvider accountProvider) {
    final account = accountProvider.selectedAccount!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 26, 26, 26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 38, 38, 40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.folder_shared_outlined,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                  Gap(8),
                  Text(
                    'Account Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (account.isTarget)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E3A8A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2563EB)),
                  ),
                  child: const Text(
                    'Verified Customer',
                    style: TextStyle(
                      color: Color(0xFF93C5FD),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const Gap(16),
          const Divider(height: 1, color: Color.fromARGB(255, 94, 95, 96)),
          const Gap(16),
          ...account.details.entries.map((entry) {
            final isIssueField = entry.key == 'Issue' && account.isTarget;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isIssueField
                    ? const Color(0x80451A03)
                    : const Color.fromARGB(255, 32, 32, 32),
                borderRadius: BorderRadius.circular(10),
                border: isIssueField
                    ? Border.all(color: const Color(0xFFB45309))
                    : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      entry.key,
                      style: TextStyle(
                        color: isIssueField
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFF9CA3AF),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        color: isIssueField
                            ? const Color(0xFFFBBF24)
                            : Colors.white,
                        fontSize: 13,
                        fontWeight: isIssueField
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const Gap(16),
          if (accountProvider.customerConfirmedResolved)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF059669)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF34D399),
                    size: 20,
                  ),
                  Gap(8),
                  Text(
                    'Customer confirmed resolved',
                    style: TextStyle(
                      color: Color(0xFF34D399),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else if (accountProvider.toolWorkDone)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A5F),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3B82F6)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.build_circle_outlined,
                    color: Color(0xFF93C5FD),
                    size: 20,
                  ),
                  Gap(8),
                  Text(
                    'Action applied. Await customer confirmation.',
                    style: TextStyle(
                      color: Color(0xFF93C5FD),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          else if (account.isTarget) ...[
            const Text(
              'Choose the correct action for this step, then submit. The note fills in for you.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            ),
            const Gap(8),
            DropdownButtonFormField<String>(
              value: _selectedAction,
              dropdownColor: const Color(0xFF1A1F26),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF121212),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Confirm identity on file',
                  child: Text('Confirm identity on file'),
                ),
                DropdownMenuItem(
                  value: 'File service request',
                  child: Text('File service request'),
                ),
                DropdownMenuItem(
                  value: 'Schedule callback',
                  child: Text('Schedule callback'),
                ),
                DropdownMenuItem(
                  value: 'Open review ticket',
                  child: Text('Open review ticket'),
                ),
              ],
              onChanged: (v) {
                if (v != null) {
                  setState(() {
                    _selectedAction = v;
                    _applyNoteForAction(v, account);
                  });
                }
              },
            ),
            const Gap(8),
            TextField(
              controller: _actionNoteController,
              maxLines: 2,
              readOnly: true,
              style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Note fills in when you pick an action',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: const Color(0xFF0F1419),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Gap(10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _submitAccountAction(accountProvider),
                icon: const Icon(Icons.task_alt, size: 18),
                label: Text(_submitLabelForAction(_selectedAction)),
                style: ElevatedButton.styleFrom(
                  enabledMouseCursor: SystemMouseCursors.click,
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x80451A03),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFB45309)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFFBBF24),
                    size: 18,
                  ),
                  Gap(8),
                  Expanded(
                    child: Text(
                      'This is not the customer\'s active account.',
                      style: TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _submitLabelForAction(String action) {
    final lower = action.toLowerCase();
    if (lower.contains('identity') || lower.contains('verify')) {
      return 'Confirm identity';
    }
    if (lower.contains('service request') || lower.contains('file')) {
      return 'File service request';
    }
    if (lower.contains('callback')) {
      return 'Schedule callback';
    }
    if (lower.contains('ticket') || lower.contains('review')) {
      return 'Open review ticket';
    }
    return 'Submit account action';
  }
}
