# DECISIONS.md — Architecture Decision Records

> Log of significant technical and design decisions.

## Format

```
### ADR-XXX: Title
**Date**: YYYY-MM-DD
**Status**: Proposed | Accepted | Deprecated | Superseded
**Context**: What prompted this decision?
**Decision**: What was decided?
**Consequences**: What are the implications?
```

---

### ADR-001: State Management — Riverpod
**Date**: 2026-01-20  
**Status**: Accepted  
**Context**: Need state management for auth state, clips data, and download progress.  
**Decision**: Use Riverpod (flutter_riverpod) for all state management.  
**Consequences**: Modern async support, good testability, user is already familiar with it.

---

### ADR-002: Folder Structure — Feature-First
**Date**: 2026-01-20  
**Status**: Accepted  
**Context**: Need to organize code in a scalable, maintainable way.  
**Decision**: Use feature-first structure: `lib/features/auth/`, `lib/features/clips/`, etc. with shared code in `lib/core/`.  
**Consequences**: Each feature is self-contained, easier to navigate and maintain.

---

### ADR-003: WebView Package — desktop_webview_window
**Date**: 2026-01-20  
**Status**: Accepted  
**Context**: Need WebView for PSN login with cookie access on desktop platforms.  
**Decision**: Use `desktop_webview_window` package.  
**Consequences**: Compatible with Windows, macOS, and Linux. Supports cookie extraction.

---

### ADR-004: Token Refresh Strategy — Proactive
**Date**: 2026-01-20  
**Status**: Accepted  
**Context**: Need to handle OAuth token expiration gracefully.  
**Decision**: Use industry best practice: proactively refresh tokens before expiry (when ~80% of TTL has elapsed), plus reactive refresh on 401 responses.  
**Consequences**: Smoother UX, fewer failed requests, but slightly more complexity in token management.

---

### ADR-005: Phase 1 Scope — Service Layer Only
**Date**: 2026-01-20  
**Status**: Accepted  
**Context**: Clarifying boundary between Phase 1 (Foundation) and Phase 2 (Auth UI).  
**Decision**: Phase 1 builds the PSNAuthService with all auth flow logic (NPSSO → code → tokens, refresh). Phase 2 wires it to the WebView UI.  
**Consequences**: Clean separation, Phase 1 can be tested independently.
