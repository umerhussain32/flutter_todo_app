import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/todo_store.dart';
import 'dashboard_screen.dart';
import 'welcome_screen.dart';

/// First screen. Shows the logo briefly, starts the data store in the
/// background, then ALWAYS moves on — to the welcome flow on first run, or
/// straight to the dashboard afterwards. Navigation is timer-driven and
/// independent of any service, so this screen can never be a dead end.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  @override
  void initState() {
    super.initState();
    TodoStore.instance.start();
    _decide();
  }

  Future<void> _decide() async {
    var loggedIn = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      loggedIn = prefs.getBool('IS_LOGED_IN') ?? false;
    } catch (_) {
      loggedIn = false;
    }
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            loggedIn ? const DashboardScreen() : const WelcomeScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', width: 110, height: 110),
            const SizedBox(height: 18),
            Text(
              'Do it now',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D1D1F),
                  ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ],
        ),
      ),
    );
  }
}
