# JOURNAL.md — Development Journal

> Session notes, insights, and context for future reference.

---

## 2026-01-20 — Project Initialization

**Session focus**: `/new-project` workflow

### Key decisions from questioning:
- Windows is priority platform; macOS/Linux later with identical look/function
- v1.0 scope: download clips/screenshots only
- No sorting, filtering, or grouping — simple grid
- Persistent login required (sign in once)
- Native file picker for each download
- Metadata caching OK, but no offline mode

### Notes:
- User has prior work on a FastAPI proxy server for PSN auth
- WebView approach for login is preferred over manual NPSSO entry
- Implementation plan already drafted in `j:\Projects\psn-clips\implementation_plan.md`
