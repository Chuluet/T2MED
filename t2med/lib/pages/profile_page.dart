import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/profile/profile_header.dart';
import '../widgets/profile/profile_option_tile.dart';
import '../widgets/profile/profile_section_card.dart';
import 'history_page.dart';
import 'login_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profile',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),
            const ProfileHeader(),

            const SizedBox(height: 24),

            ProfileSectionCard(
              children: [
                ProfileOptionTile(
                  icon: Icons.person_outline,
                  title: 'My Account',
                  subtitle: 'Make changes to your account',
                  trailing: Icons.warning_amber_rounded,
                  onTap: () {},
                ),
                const Divider(height: 1),
                ProfileOptionTile(
                  icon: Icons.history,
                  title: 'Medication History',
                  subtitle: 'View medication intake history',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HistoryPage()),
                    );
                  },
                ),
                const Divider(height: 1),
                ProfileOptionTile(
                  icon: Icons.logout,
                  title: 'Log out',
                  subtitle: 'Close your session',
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (_) => false,
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              'More',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            ProfileSectionCard(
              children: [
                ProfileOptionTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'Get help',
                  onTap: () {},
                ),
                const Divider(height: 1),
                ProfileOptionTile(
                  icon: Icons.info_outline,
                  title: 'About App',
                  subtitle: 'App information',
                  onTap: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
