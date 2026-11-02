import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/models/training/scenarios/scenario_models.dart';

class ScenarioAccountLookupPanel extends StatelessWidget {
  final List<ScenarioAccount> accounts;
  final String searchQuery;
  final String? selectedAccountId;
  final bool issueResolved;
  final bool accountsRevealed;
  final bool allowSearch;
  final bool allowSelect;
  final bool allowResolve;
  final TextEditingController searchController;
  final ScrollController? scrollController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onSelectAccount;
  final VoidCallback? onConfirmSearch;
  final VoidCallback? onConfirmSelect;
  final VoidCallback? onResolve;
  final String sector;
  final bool flashError;
  final bool flashSuccess;

  const ScenarioAccountLookupPanel({
    super.key,
    required this.accounts,
    required this.searchQuery,
    required this.selectedAccountId,
    required this.issueResolved,
    required this.accountsRevealed,
    required this.allowSearch,
    required this.allowSelect,
    required this.allowResolve,
    required this.searchController,
    this.scrollController,
    required this.onSearchChanged,
    required this.onSelectAccount,
    required this.onConfirmSearch,
    required this.onConfirmSelect,
    required this.onResolve,
    required this.sector,
    this.flashError = false,
    this.flashSuccess = false,
  });

  List<ScenarioAccount> get _filtered {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return accounts;
    return accounts
        .where(
          (a) =>
              a.ownerName.toLowerCase().contains(q) ||
              a.accountId.toLowerCase().contains(q),
        )
        .toList();
  }

  ScenarioAccount? get _selected {
    if (selectedAccountId == null) return null;
    for (final a in accounts) {
      if (a.accountId == selectedAccountId) return a;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, left: 8, right: 8, bottom: 8),
      child: SingleChildScrollView(
        key: const PageStorageKey('scenario_account_lookup'),
        controller: scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSearchInput(),
            const Gap(20),
            if (!accountsRevealed)
              _buildSearchPrompt()
            else ...[
              _buildAccountsListHeader(),
              const Gap(12),
              _buildAccountsList(),
              const Gap(24),
              if (_selected != null) _buildAccountDetails(_selected!),
            ],
            if (allowSearch && onConfirmSearch != null) ...[
              const Gap(16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: onConfirmSearch,
                  child: const Text('Confirm Search'),
                ),
              ),
            ],
            if (allowSelect && onConfirmSelect != null) ...[
              const Gap(12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed:
                      selectedAccountId == null ? null : onConfirmSelect,
                  child: const Text('Confirm Selected Account'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchInput() {
    return Container(
      decoration: BoxDecoration(
        color: flashError
            ? const Color(0xFF3A1515)
            : flashSuccess
                ? const Color(0xFF153A22)
                : const Color(0xFF1A1A1B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: flashError
              ? Colors.redAccent
              : flashSuccess
                  ? Colors.green
                  : const Color.fromARGB(255, 27, 28, 30),
          width: (flashError || flashSuccess) ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 22),
          const Gap(12),
          Expanded(
            child: TextField(
              controller: searchController,
              enabled: allowSearch || allowSelect || allowResolve,
              onChanged: onSearchChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) {
                if (allowSearch && onConfirmSearch != null) {
                  onConfirmSearch!();
                }
              },
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
          if (searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                searchController.clear();
                onSearchChanged('');
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

  Widget _buildSearchPrompt() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color.fromARGB(130, 28, 28, 28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color.fromARGB(255, 40, 40, 40)),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_rounded, color: Color(0xFF9CA3AF), size: 36),
          Gap(12),
          Text(
            'Search for an account',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Gap(8),
          Text(
            'Type a customer name or account ID, then confirm search. Matching accounts will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsListHeader() {
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
            '${_filtered.length} found',
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

  Widget _buildAccountsList() {
    final filtered = _filtered;
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
      separatorBuilder: (_, __) => const Gap(10),
      itemBuilder: (context, index) {
        final account = filtered[index];
        final isSelected = selectedAccountId == account.accountId;
        return GestureDetector(
          onTap: (allowSelect || allowResolve)
              ? () => onSelectAccount(account.accountId)
              : null,
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
                      color:
                          isSelected ? Colors.white : const Color(0xFF9CA3AF),
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

  Widget _buildAccountDetails(ScenarioAccount account) {
    final isTarget = account.isTarget;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 22, 23, 24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 42, 44, 45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Details',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(12),
          Text(
            account.ownerName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(4),
          Text(
            'ID: ${account.accountId}',
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          ),
          const Gap(14),
          ...account.details.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      e.key,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Gap(12),
          if (issueResolved)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF059669)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: Color(0xFF34D399), size: 20),
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
          else if (allowResolve && isTarget)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onResolve,
                icon: const Icon(Icons.flash_on_rounded, size: 18),
                label: Text(_actionLabel(sector)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            )
          else if (!isTarget)
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
                  Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFFBBF24), size: 18),
                  Gap(8),
                  Expanded(
                    child: Text(
                      "This is not the customer's active account.",
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

  String _actionLabel(String sector) {
    final s = sector.toLowerCase();
    if (s.contains('finance')) return 'Resolve Transfer Issue';
    if (s.contains('health')) return 'Resolve Appointment Issue';
    if (s.contains('telco')) return 'Resolve Service Issue';
    return 'Mark as Resolved';
  }
}
