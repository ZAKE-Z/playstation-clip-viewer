# SPEC.md — Project Specification

> **Status**: `FINALIZED`

## Vision

A cross-platform Flutter desktop app that lets PlayStation users view and download their gaming clips and screenshots. Users authenticate once via an embedded PlayStation login, then browse their media in a simple grid and download items using a native file picker.

## Goals

1. **Seamless authentication** — WebView-based PSN login that extracts the NPSSO token automatically; persist login across app launches
2. **Browse media** — Display clips and screenshots in a grid with thumbnails
3. **Download media** — Download any clip/screenshot via native file picker dialog
4. **View details** — Show metadata (game, date, duration) for each item

## Non-Goals (Out of Scope)

- Uploading clips (not possible via API)
- Editing or trimming clips
- Sorting, filtering, searching, or grouping
- Offline browsing
- Caching actual media files (only metadata)
- Sharing functionality

## Users

- Primary: The developer (personal use)
- Secondary: Other PlayStation gamers who want to manage their clips outside the console

## Constraints

- **Platform**: Windows is priority; macOS/Linux planned for later
- **Consistency**: App must look and function identically across all platforms
- **Auth**: Must use PSN's OAuth flow (NPSSO → code → tokens)
- **Media access**: Requires CloudFront signed cookies from PSN API

## Success Criteria

- [ ] User can sign in once and remain authenticated on subsequent launches
- [ ] User can view all their clips/screenshots in a grid
- [ ] User can see metadata for any item
- [ ] User can download any item to a location of their choice
- [ ] App runs on Windows with identical behavior planned for macOS/Linux
