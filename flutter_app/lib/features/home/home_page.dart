import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/app_routes.dart';
import '../profile/widgets/bottom_nav_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // For demo, change this to 'proctor' to test proctor profile
    const role = 'proctor'; // Change to 'proctor' for testing proctor UI

    return Scaffold(
      appBar: AppBar(
        title: Text(role == 'proctor' ? 'Proctor Dashboard' : 'Student Dashboard'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              role == 'proctor' ? 'Proctor Homepage' : 'Student Homepage',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (role == 'proctor') {
                  context.go(AppRoutes.proctorProfile);
                } else {
                  context.go(AppRoutes.profile);
                }
              },
              child: const Text('Open Profile'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}


