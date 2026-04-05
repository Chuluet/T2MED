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
import 'package:t2med/pages/pastillero_page.dart';
import 'package:t2med/widgets/login/decorative_background.dart';

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
      backgroundColor: const Color(0xFFEAEFF5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A2A3A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          const DecorativeBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo T2MED (solo título, sin avatar)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.medication_outlined,
                          color: Color(0xFF1E88E5), size: 22),
                      SizedBox(width: 8),
                      Text(
                        'T2MED',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E88E5),
                          letterSpacing: 3,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.calendar_month_outlined,
                          color: Color(0xFF1E88E5), size: 22),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Perfil',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2A3A),
                    ),
                  ),

                  const SizedBox(height: 14),

                  ProfileHeader(
                    name: profile?['name'] ?? user?.displayName ?? 'Usuario',
                    email: user?.email ?? '',
                  ),

                  const SizedBox(height: 16),

                  ProfileSectionCard(
                    children: [
                      ProfileOptionTile(
                        icon: Icons.history,
                        title: 'Historial de medicamentos',
                        subtitle: 'Ver historial de tomas',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const HistoryPage()),
                        ),
                      ),
                      ProfileOptionTile(
                        icon: Icons.medication_outlined,
                        title: 'Mi pastillero',
                        subtitle: 'Gestiona tu inventario',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PastilleroPage()),
                        ),
                      ),
                      ProfileOptionTile(
                        icon: Icons.favorite_border,
                        title: 'Condiciones médicas',
                        subtitle: 'Ver condiciones médicas',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MedicalConditionsPage()),
                        ),
                      ),
                      ProfileOptionTile(
                        icon: Icons.logout,
                        title: 'Cerrar sesión',
                        subtitle: 'Cerrar tu sesión',
                        isDestructive: true,
                        onTap: () async {
                          await FirebaseAuth.instance.signOut();
                          if (!context.mounted) return;
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginPage()),
                            (_) => false,
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Más',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A2A3A),
                    ),
                  ),

                  const SizedBox(height: 12),

                  ProfileSectionCard(
                    children: [
                      ProfileOptionTile(
                        icon: Icons.help_outline,
                        title: 'Ayuda y soporte',
                        subtitle: 'Obtener ayuda',
                        onTap: () {},
                      ),
                      ProfileOptionTile(
                        icon: Icons.info_outline,
                        title: 'Acerca de la app',
                        subtitle: 'Información de la aplicación',
                        onTap: () {},
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
