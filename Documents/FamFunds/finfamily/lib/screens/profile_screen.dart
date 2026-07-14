import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../routes/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          FFCard(
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(Icons.person, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Aarushi', // TODO: pull from FirebaseAuth user
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    Text('Self · The Sharma Family',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ProfileTile(
            icon: Icons.link_rounded,
            label: 'Linked Accounts',
            onTap: () => Navigator.pushNamed(context, AppRoutes.consentIntro),
          ),
          _ProfileTile(icon: Icons.family_restroom_rounded, label: 'Family Members', onTap: () {}),
          _ProfileTile(icon: Icons.security_rounded, label: 'Privacy & Consent', onTap: () {}),
          _ProfileTile(icon: Icons.logout_rounded, label: 'Log out', onTap: () {}),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ProfileTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}
