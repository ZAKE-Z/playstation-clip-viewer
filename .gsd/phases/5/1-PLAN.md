---
phase: 5
plan: 1
wave: 1
---

# Plan 5.1: UI Polish & Error Handling

## Objective
Enhance the user experience with proper loading states, empty states, and robust error handling across the app.

## Context
- .gsd/SPEC.md
- lib/features/clips/presentation/gallery_screen.dart
- lib/features/auth/presentation/login_screen.dart

## Tasks

<task type="auto">
  <name>Implement Empty States</name>
  <files>lib/features/clips/presentation/gallery_screen.dart</files>
  <action>
    Add empty state handling to `GalleryScreen`:
    - Display friendly message and icon when `state.items` is empty.
    - Suggest refreshing.
  </action>
  <verify>Manual verification (clear data or mock empty response)</verify>
  <done>Empty state visible when no clips exist</done>
</task>

<task type="auto">
  <name>Enhance Error Handling</name>
  <files>lib/features/clips/presentation/gallery_screen.dart</files>
  <action>
    Improve error presentation in `GalleryScreen`:
    - Replace generic error text with user-friendly `SnackBar` or centered error widget.
    - Add "Retry" button for failed loads.
    - Ensure network errors are clearly distinguished from empty states.
  </action>
  <verify>Manual verification (disconnect network)</verify>
  <done>Errors are clear and actionable</done>
</task>

<task type="auto">
  <name>Refine Loading Indicators</name>
  <files>lib/features/clips/presentation/gallery_screen.dart</files>
  <action>
    Review and refine loading indicators:
    - Ensure initial load shows a centered `CircularProgressIndicator` or skeleton loader.
    - Ensure refresh action shows proper indicator (RefreshIndicator is already used, verify behavior).
  </action>
  <verify>Manual verification of load flow</verify>
  <done>Loading states are smooth and visible</done>
</task>

## Success Criteria
- [ ] Empty gallery shows a helpful message
- [ ] Network errors allow user to retry
- [ ] App never looks "frozen" (always shows loading or content)
