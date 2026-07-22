import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../routes/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser;

  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (_user == null) {
      setState(() {
        _isLoading = false;
        _error = 'No signed-in user.';
      });
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(_user.uid).get();
      setState(() {
        _profileData = doc.data();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Could not load profile.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.accentRed)))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final fullName = _profileData?['fullName'] ?? 'Unnamed';
    final username = _profileData?['username'] ?? '';
    final email = _user?.email ?? '';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        FFCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fullName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      if (username.isNotEmpty)
                        Text('@$username',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),
                      Text(email,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                  onPressed: () async {
                    final updated = await Navigator.pushNamed(context, AppRoutes.editProfile);
                    if (updated == true) _loadProfile();
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ProfileTile(
          icon: Icons.link_rounded,
          label: 'Linked Accounts',
          onTap: () => Navigator.pushNamed(context, AppRoutes.consentIntro),
        ),
        _ProfileTile(icon: Icons.family_restroom_rounded, label: 'Family Members', onTap: () {}),
        _ProfileTile(
          icon: Icons.lock_outline_rounded,
          label: 'Change Password',
          onTap: () => Navigator.pushNamed(context, AppRoutes.changePassword),
        ),
        _ProfileTile(icon: Icons.security_rounded, label: 'Privacy & Consent', onTap: () {}),
        _ProfileTile(
          icon: Icons.logout_rounded,
          label: 'Log out',
          onTap: () async {
            await FirebaseAuth.instance.signOut();
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(context, AppRoutes.auth, (route) => false);
            }
          },
        ),
      ],
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