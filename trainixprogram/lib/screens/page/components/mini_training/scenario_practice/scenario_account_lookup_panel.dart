import 'package:flutter/material.dart';
import 'package:trainixprogram/components/app_colors.dart';
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
            _buildSearchInput(context),
            const Gap(20),
            if (!accountsRevealed)
              _buildSearchPrompt(context)
            else ...[
              _buildAccountsListHeader(context),
              const Gap(12),
              _buildAccountsList(context),
              const Gap(24),
              if (_selected != null) _buildAccountDetails(context, _selected!),
            ],
            if (allowSearch && onConfirmSearch != null) ...[
              const Gap(16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary(context),
                    foregroundColor: AppColors.onPrimary(context),
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
                    backgroundColor: AppColors.primary(context),
                    foregroundColor: AppColors.onPrimary(context),
                  ),
                  onPressed: selectedAccountId == null ? null : onConfirmSelect,
                  child: Text('Confirm Selected Account'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSearchInput(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: flashError
            ? AppColors.elevated(context)
            : flashSuccess
                ? AppColors.nextTint(context)
                : AppColors.card(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: flashError
              ? AppColors.errorText()
              : flashSuccess
                  ? AppColors.primary(context)
                  : AppColors.border(context),
          width: (flashError || flashSuccess) ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.search_rounded,
              color: AppColors.textMuted(context), size: 22),
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
              style: TextStyle(
                  color: AppColors.textPrimary(context), fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by account ID or customer name...',
                hintStyle: TextStyle(
                  color: AppColors.textMuted(context),
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
              child: Icon(
                Icons.close_rounded,
                color: AppColors.textMuted(context),
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchPrompt(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.panel(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Icon(Icons.search_rounded,
              color: AppColors.textMuted(context), size: 36),
          Gap(12),
          Text(
            'Search for an account',
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Gap(8),
          Text(
            'Type a customer name or account ID, then confirm search. Matching accounts will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted(context),
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsListHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.badge_outlined,
                color: AppColors.secondaryText(), size: 20),
            Gap(8),
            Text(
              'Customer Accounts',
              style: TextStyle(
                color: AppColors.textPrimary(context),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.elevated(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${_filtered.length} found',
            style: TextStyle(
              color: AppColors.textMuted(context),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountsList(BuildContext context) {
    final filtered = _filtered;
    if (filtered.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderStrong(context)),
        ),
        child: Text(
          'No matching accounts found.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary(context),
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
                  ? AppColors.elevated(context)
                  : AppColors.card(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppColors.secondaryText()
                    : AppColors.border(context),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: isSelected
                      ? AppColors.secondaryText()
                      : AppColors.chipBg(context),
                  child: Text(
                    account.ownerName.isNotEmpty
                        ? account.ownerName[0].toUpperCase()
                        : 'A',
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.onSecondary(context)
                          : AppColors.textMuted(context),
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
                        style: TextStyle(
                          color: AppColors.textPrimary(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(2),
                      Text(
                        'ID: ${account.accountId}',
                        style: TextStyle(
                          color: AppColors.textMuted(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.secondaryText(),
                    size: 22,
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted(context),
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccountDetails(BuildContext context, ScenarioAccount account) {
    final isTarget = account.isTarget;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 22, 23, 24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Details',
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Gap(12),
          Text(
            account.ownerName,
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Gap(4),
          Text(
            'ID: ${account.accountId}',
            style: TextStyle(color: AppColors.textMuted(context), fontSize: 13),
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
                      style: TextStyle(
                        color: AppColors.textMuted(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      e.value,
                      style: TextStyle(
                        color: AppColors.textPrimary(context),
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
                color: AppColors.nextTint(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryText()),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.successText(), size: 20),
                  Gap(8),
                  Text(
                    'Issue Resolved in System',
                    style: TextStyle(
                      color: AppColors.successText(),
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
                  backgroundColor: AppColors.secondaryText(),
                  foregroundColor: AppColors.onPrimary(context),
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
                color: AppColors.warningWash(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warningText()),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppColors.warningText(), size: 18),
                  Gap(8),
                  Expanded(
                    child: Text(
                      "This is not the customer's active account.",
                      style: TextStyle(
                        color: AppColors.warningText(),
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
