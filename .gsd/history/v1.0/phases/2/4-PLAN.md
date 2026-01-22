---
phase: 2
plan: 4
wave: 2
---

# Plan 2.4: End-to-End Testing & Polish

## Objective
Verify the complete login flow works end-to-end and add error handling for edge cases.

## Context
- lib/features/auth/presentation/psn_login_webview.dart
- lib/features/auth/providers/auth_provider.dart
- lib/app.dart

## Tasks

<task type="auto">
  <name>Add error handling to login flow</name>
  <files>lib/features/auth/presentation/login_screen.dart</files>
  <action>
    Update login_screen.dart to show auth errors:
    
    Add error display for AuthError state. Update the _signIn method to handle potential errors gracefully.
    
    Also add a loading state while authentication is in progress.
  </action>
  <verify>dart analyze lib/features/auth/presentation/login_screen.dart</verify>
  <done>login_screen.dart has error handling and loading states</done>
</task>

<task type="checkpoint:human-verify">
  <name>Test complete login flow</name>
  <files>N/A</files>
  <action>
    Run the app and test the login flow:
    1. App starts and shows login screen
    2. Click "Sign in with PlayStation"
    3. WebView opens to PlayStation login
    4. User logs in with PSN credentials
    5. NPSSO cookie is extracted
    6. WebView closes
    7. App shows "Logged in!" screen
    8. Logout button works
    9. Re-launch app shows logged in (token persisted)
    
    Run: `flutter run -d windows`
  </action>
  <verify>Manual verification by user</verify>
  <done>User confirms login flow works end-to-end</done>
</task>

## Success Criteria
- [ ] App launches without errors
- [ ] Login button opens WebView
- [ ] User can log in with PSN credentials
- [ ] App shows authenticated state after login
- [ ] Token persistence works (survives app restart)
