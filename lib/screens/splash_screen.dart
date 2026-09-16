import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/contact_provider.dart';
import '../services/permission_service.dart';
import '../services/supabase_service.dart';
import '../widgets/permission_dialog.dart';
import 'main_navigation_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  String _statusMessage = 'Initializing CRM services...';
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 600));

    // 1. Check Internet Connection
    setState(() => _statusMessage = 'Checking internet connection...');
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasNoInternet = connectivityResult.contains(ConnectivityResult.none);
      if (hasNoInternet) {
        setState(() => _statusMessage = 'Offline mode (Cached data available)');
      }
    } catch (_) {
      // Continue even if connectivity check errors
    }

    // 2. Initialize Supabase
    setState(() => _statusMessage = 'Connecting to Supabase...');
    await SupabaseService.instance.initialize();

    // 3. Check and request required permissions
    setState(() => _statusMessage = 'Checking permissions...');
    await _checkPermissionsAndProceed();
  }

  Future<void> _checkPermissionsAndProceed() async {
    final result = await PermissionService.instance.requestAllPermissions();

    if (!result.isAllGranted) {
      if (mounted) {
        setState(() => _statusMessage = 'Permissions required');
        final proceed = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const PermissionExplanationDialog(),
        );

        // If user returned from settings or dismissed dialog, re-check or proceed to home
        if (proceed == true) {
          final recheck = await PermissionService.instance.hasAllRequiredPermissions();
          if (!recheck && mounted) {
            // Informative fallback
          }
        }
      }
    }

    // 4. Preload cached contacts into provider
    if (mounted) {
      setState(() => _statusMessage = 'Loading CRM contacts...');
      await context.read<ContactProvider>().loadContacts();

      // Navigate to Home
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, anim, secAnim) => const MainNavigationScreen(),
          transitionsBuilder: (context, anim, secAnim, child) {
            return FadeTransition(opacity: anim, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Logo Animation
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryGreen, AppColors.primaryGreenDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withOpacity(0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.phone_in_talk_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // App Title
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      const Text(
                        'CRM Call Sample',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Enterprise Customer Communication',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // Loading Animation & Status Indicator
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.8,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                    backgroundColor: AppColors.primaryGreenLight.withOpacity(0.5),
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
