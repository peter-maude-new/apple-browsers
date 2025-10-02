---
alwaysApply: true
title: "DuckDuckGo Browser Development Overview"
description: "General project overview and development guidelines for DuckDuckGo browser development across iOS and macOS platforms"
keywords: ["Swift", "iOS", "macOS", "MVVM", "SwiftUI", "privacy", "architecture", "dependency injection", "design system"]
---

# DuckDuckGo Browser Development Overview

## 🛑 STOP Protocol

**When user says**: "stop", "wtf", "u doing wrong", "what u doing now", "why [action]"
**Action**: IMMEDIATELY STOP. Don't continue, explain, or fix. Acknowledge briefly and wait.

## 📝 Documentation Rules

### Editing Documentation
- **ALWAYS** edit markdown files directly using file editing tools
- **NEVER** use MCP tools to create/update documentation

### Lookup Protocol (MANDATORY)
1. Call `doc_bot()` FIRST (non-negotiable)
2. Call `get_document_index()` to see available docs with filenames
3. Use `read_specific_document("exact-filename.md")` with exact filename
4. NEVER use search snippets alone - read full documents

## 🚨 Git & Testing Workflow

**NEVER execute without EXPLICIT permission:**
- `git add`, `git commit`, `git push`, branch operations
- `swift test`, `xcodebuild test`, any test commands

**Process**: Make changes → STOP → ASK user → WAIT for permission → Execute

## Project Context

**Directories**: `iOS/` (UIKit+SwiftUI), `macOS/` (AppKit+SwiftUI), `SharedPackages/` (cross-platform), `doc-bot/` (rules)
**Architecture**: MVVM + Coordinators + Dependency Injection
**UI**: SwiftUI preferred, UIKit/AppKit for legacy
**Storage**: Core Data + GRDB + Keychain
**Design**: DesignResourcesKit (MANDATORY)
**Testing**: >80% coverage

## Critical Rules

### Always Forbidden
- ❌ `.shared` singletons (use DI)
- ❌ Hardcoded colors/icons (use DesignResourcesKit)
- ❌ UI updates without @MainActor
- ❌ `print()` statements (use Logger.general/network/ui)
- ❌ Force unwrap without justification
- ❌ Privacy violations

### Always Required
- ✅ DesignResourcesKit: `Color(designSystemColor: .textPrimary)`, `DesignSystemImages.Color.Size24.bookmark`
- ✅ Logger: `Logger.general.debug()`, `Logger.network.info()`, `Logger.ui.debug()`
- ✅ Dependency Injection: `init(dependencies: DependencyProvider = AppDependencyProvider.shared)`

## Documentation Index

**Core**: `anti-patterns.md`, `code-style.md`, `privacy-security.md`
**Architecture**: `architecture.md`, `ios-architecture.md`, `macos-window-management.md`, `macos-system-integration.md`
**UI**: `swiftui-style.md`, `swiftui-advanced.md`, `design-system-designresourceskit.md`, `webkit-browser.md`
**Development**: `testing.md`, `ui-testing.md`, `development-commands.md`, `performance-optimization.md`, `shared-packages.md`
**Features**: `feature-flags.md`, `analytics-patterns.md`, `subscription-architecture.md`, `user-defaults-storage.md`

## When to Consult Rules

| Task | Read These |
|------|-----------|
| ViewModels | `architecture.md` + `swiftui-style.md` + `anti-patterns.md` |
| Network calls | `performance-optimization.md` + `privacy-security.md` |
| Settings | Platform-specific + `user-defaults-storage.md` |
| Analytics | `analytics-patterns.md` + `privacy-security.md` |
| Testing | `testing.md` + `anti-patterns.md` |
| UI Testing | `ui-testing.md` + `testing.md` |
| WebView | `webkit-browser.md` + `anti-patterns.md` |
| macOS features | `macos-system-integration.md` + platform rules |

## Pre-Code Checklist

- [ ] Read `privacy-security.md` (privacy is non-negotiable)
- [ ] Check platform rules (`ios-architecture.md` or `macos-window-management.md`)
- [ ] Review `anti-patterns.md`
- [ ] DesignResourcesKit for all UI
- [ ] Dependency injection pattern
- [ ] Logger for all logging

## Communication Style

- Concise, focused responses
- Avoid excessive enthusiasm/praise
- Focus on what changed, not how great it is
