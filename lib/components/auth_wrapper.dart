import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';
import '../screens/client_dashboard_screen.dart';
import '../screens/professional_dashboard_screen.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const AuthScreen();
        }

        // Get user type
        final userTypeAsync = ref.watch(userTypeProvider(user.uid));

        return userTypeAsync.when(
          data: (userType) {
            // If professional, show professional dashboard
            if (userType == UserType.professional) {
              return const ProfessionalDashboardScreen();
            }

            // If client, show bottom navigation with home and dashboard
            return Scaffold(
              body: const HomeScreen(),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: 0, // TODO: Implement navigation state
                onTap: (index) {
                  // TODO: Handle navigation
                },
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Начало',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Профил',
                  ),
                ],
              ),
            );
          },
          loading: () => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Възникна грешка'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(authServiceProvider).signOut();
                    },
                    child: const Text('Опитайте отново'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Възникна грешка при автентикация'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Refresh the auth state
                  ref.refresh(authStateProvider);
                },
                child: const Text('Опитайте отново'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Provider for managing bottom navigation state
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

// Provider for the current screen based on bottom navigation
final currentScreenProvider = Provider<Widget>((ref) {
  final index = ref.watch(bottomNavIndexProvider);
  
  switch (index) {
    case 0:
      return const HomeScreen();
    case 1:
      return const ClientDashboardScreen();
    default:
      return const HomeScreen();
  }
});
