import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:t2med/pages/medical_conditions_page.dart';
import '../services/user_service.dart';
import '../widgets/profile/profile_header.dart';
import '../widgets/profile/profile_option_tile.dart';
import '../widgets/profile/profile_section_card.dart';
import 'history_page.dart';
import 'login_page.dart';
import 'edit_user_page.dart';
import 'package:t2med/pages/pastillero_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userService = context.read<UserService>();
      await userService.getUserProfile(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userService = context.watch<UserService>();
    final profile = userService.currentUserProfile;
    final user = FirebaseAuth.instance.currentUser;

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

            // Usar ProfileHeader con los datos actuales
            ProfileHeader(
              name: profile?['name'] ?? user?.displayName ?? 'Usuario',
              email: user?.email ?? '',
              
            ),

            const SizedBox(height: 24),

            ProfileSectionCard(
              children: [
               
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
                ProfileOptionTile(
                  icon: Icons.medication,
                  title: 'My Pillbox',
                  subtitle: 'Manage your medication inventory',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PastilleroPage()),
                   );
                  },
                ),
                const Divider(height: 1),
                ProfileOptionTile(
                  icon: Icons.heart_broken_sharp,
                  title: 'Medical Conditions',
                  subtitle: 'View medical conditions',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MedicalConditionsPage()),
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