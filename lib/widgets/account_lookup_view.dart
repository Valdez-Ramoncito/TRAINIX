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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            child: Container(
              color: bgColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Search Input Field
                  _buildSearchInput(accountProvider),
                  const Gap(20),

                  if (accountProvider.accounts.isEmpty)
                    _buildNoAccountsView(accountProvider)
                  else ...[
                    _buildAccountsListHeader(accountProvider),
                    const Gap(12),
                    _buildAccountsList(accountProvider),
                    const Gap(24),
                    if (accountProvider.selectedAccount != null) ...[
                      _buildAccountDetails(accountProvider),
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
          const Text(
            'No Account Lookup Needed',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(10),
          const Text(
            'If you\'ve resolved the issue through guidance, troubleshooting, '
            'or an escalation, the customer will wrap up naturally. '
            'You can also mark the issue as resolved manually below.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const Gap(24),
          if (accountProvider.issueResolved)
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
                    'Issue Resolved',
                    style: TextStyle(
                      color: Color(0xFF34D399),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: accountProvider.resolveIssue,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
              label: const Text('Mark as Resolved'),
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
          onTap: () => accountProvider.selectAccount(account),
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
          if (accountProvider.issueResolved)
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
                    'Issue Resolved in System',
                    style: TextStyle(
                      color: Color(0xFF34D399),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else if (account.isTarget)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: accountProvider.resolveIssue,
                icon: const Icon(Icons.flash_on_rounded, size: 18),
                label: Text(_getActionLabel(widget.sector)),
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
            )
          else
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

  // Return the appropriate action-button text for the given sector
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
