import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../routes/app_routes.dart';

/// Step 3 — select which discovered (mock) bank accounts to link.
/// TODO: replace static list with mock FIP data seeded via
/// Cloud Function `mockDiscoverAccounts`.
class SelectAccountsScreen extends StatefulWidget {
  const SelectAccountsScreen({super.key});

  @override
  State<SelectAccountsScreen> createState() => _SelectAccountsScreenState();
}

class _SelectAccountsScreenState extends State<SelectAccountsScreen> {
  final Map<String, bool> _selected = {
    'HDFC Bank · XXXX 4821': true,
    'SBI · XXXX 2201': false,
  };
  bool _isLoading = false;

  Future<void> _confirm() async {
    setState(() => _isLoading = true);
    // TODO: call Cloud Function `mockFetchFIData` for selected accounts,
    // write results to Firestore accounts/transactions collections.
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pushNamed(context, AppRoutes.consentSuccess);
    }
  }

  @override
  Widget build(BuildContext context) {
    final anySelected = _selected.values.any((v) => v);

    return Scaffold(
      appBar: AppBar(title: const Text('Select Accounts')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'We found these accounts. Choose which ones to link with FinFamily.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            ..._selected.keys.map((key) => _AccountCheckTile(
                  label: key,
                  value: _selected[key]!,
                  onChanged: (v) => setState(() => _selected[key] = v),
                )),
            const Spacer(),
            FFPrimaryButton(
              label: 'Link Selected Accounts',
              isLoading: _isLoading,
              onPressed: anySelected ? _confirm : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountCheckTile extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _AccountCheckTile({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: FFCard(
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
              color: value ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }
}
