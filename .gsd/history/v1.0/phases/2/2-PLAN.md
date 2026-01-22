---
phase: 2
plan: 2
wave: 1
---

# Plan 2.2: Login Screen UI

## Objective
Create the login screen with PlayStation branding and a "Sign in with PlayStation" button. When user is already authenticated, redirect to the main app.

## Context
- .gsd/SPEC.md
- lib/app.dart
- lib/features/auth/providers/auth_provider.dart

## Tasks

<task type="auto">
  <name>Create login screen widget</name>
  <files>lib/features/auth/presentation/login_screen.dart</files>
  <action>
    Create lib/features/auth/presentation/login_screen.dart:
    
    ```dart
    import 'package:flutter/material.dart';
    import 'package:flutter_riverpod/flutter_riverpod.dart';
    import '../providers/auth_provider.dart';
    import 'psn_login_webview.dart';
    
    class LoginScreen extends ConsumerWidget {
      const LoginScreen({super.key});
    
      @override
      Widget build(BuildContext context, WidgetRef ref) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0070D1), // PlayStation blue
                  Color(0xFF00439C),
                ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // PlayStation logo placeholder
                  const Icon(
                    Icons.gamepad,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'PS Clips',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'View and download your PlayStation clips',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton.icon(
                    onPressed: () => _signIn(context, ref),
                    icon: const Icon(Icons.login),
                    label: const Text('Sign in with PlayStation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0070D1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    
      void _signIn(BuildContext context, WidgetRef ref) {
        PsnLoginWebview.show(context, ref);
      }
    }
    ```
  </action>
  <verify>dart analyze lib/features/auth/presentation/login_screen.dart</verify>
  <done>login_screen.dart created with PlayStation-branded UI</done>
</task>

<task type="auto">
  <name>Create placeholder for PSN login webview</name>
  <files>lib/features/auth/presentation/psn_login_webview.dart</files>
  <action>
    Create lib/features/auth/presentation/psn_login_webview.dart as a placeholder:
    
    ```dart
    import 'package:flutter/material.dart';
    import 'package:flutter_riverpod/flutter_riverpod.dart';
    
    /// Helper to launch PSN login WebView
    class PsnLoginWebview {
      PsnLoginWebview._();
      
      /// Show the PSN login webview and handle authentication
      static Future<void> show(BuildContext context, WidgetRef ref) async {
        // TODO: Implement in Plan 2.3
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WebView login coming soon...')),
        );
      }
    }
    ```
    
    This will be fully implemented in Plan 2.3.
  </action>
  <verify>dart analyze lib/features/auth/presentation/psn_login_webview.dart</verify>
  <done>Placeholder psn_login_webview.dart created</done>
</task>

<task type="auto">
  <name>Update app.dart with auth routing</name>
  <files>lib/app.dart</files>
  <action>
    Update lib/app.dart to show LoginScreen or main content based on auth state:
    
    ```dart
    import 'package:flutter/material.dart';
    import 'package:flutter_riverpod/flutter_riverpod.dart';
    import 'features/auth/providers/auth_provider.dart';
    import 'features/auth/presentation/login_screen.dart';
    
    class PsClipsApp extends ConsumerWidget {
      const PsClipsApp({super.key});
    
      @override
      Widget build(BuildContext context, WidgetRef ref) {
        return MaterialApp(
          title: 'PS Clips',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0070D1),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: const _AuthWrapper(),
        );
      }
    }
    
    class _AuthWrapper extends ConsumerWidget {
      const _AuthWrapper();
    
      @override
      Widget build(BuildContext context, WidgetRef ref) {
        final authState = ref.watch(authProvider);
        
        return authState.when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stack) => Scaffold(
            body: Center(child: Text('Error: $error')),
          ),
          data: (state) {
            if (state is Authenticated) {
              // TODO: Show clips gallery (Phase 3)
              return Scaffold(
                appBar: AppBar(title: const Text('PS Clips')),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Logged in!'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(authProvider.notifier).logout(),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const LoginScreen();
          },
        );
      }
    }
    ```
  </action>
  <verify>dart analyze lib/app.dart</verify>
  <done>app.dart updated with auth routing</done>
</task>

## Success Criteria
- [ ] login_screen.dart with PlayStation branding
- [ ] psn_login_webview.dart placeholder
- [ ] app.dart routes based on auth state
- [ ] `dart analyze lib/` passes
