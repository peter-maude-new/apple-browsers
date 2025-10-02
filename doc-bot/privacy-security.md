---
alwaysApply: true
title: "Privacy & Security Guidelines"
description: "Privacy and security guidelines for DuckDuckGo browser development with privacy-by-design principles"
keywords: ["privacy", "security", "keychain", "data protection", "HTTPS", "authentication", "content blocking", "cookies"]
---

# Privacy & Security Guidelines

## Core Principles

- **Privacy by Design**: Never collect/transmit data without consent, default to most private option, implement data minimization
- **Secure Storage**: Use Keychain for sensitive data, encrypted Core Data for persistent data
- **Network Security**: HTTPS only, certificate pinning for critical endpoints, validate all external inputs
- **Secure Defaults**: Block trackers by default, HTTPS everywhere, no diagnostics, no history

## Data Classification & Handling

| Type | Examples | Requirements |
|------|----------|--------------|
| **Sensitive** | Passwords, credentials | Keychain only, never log, clear on logout |
| **Private** | History, bookmarks, settings | Local encrypted storage, respect fireproofing |
| **Anonymous** | Crash reports, usage stats | User consent required, strip PII, differential privacy |

```swift
// ✅ Secure storage examples
KeychainService().store(password, for: account)  // Sensitive data
container.setOption(FileProtectionType.complete, forKey: NSPersistentStoreFileProtectionKey)  // Encrypted data
```

## Critical Security Rules

### Network & Data
- HTTPS only: `guard url.scheme == "https" else { throw NetworkError.insecureConnection }`
- Certificate pinning for critical endpoints
- Validate all external inputs before use
- No hardcoded secrets or API keys

### Authentication & Storage
- Use `LAContext` for biometric authentication
- Use `ASPasswordCredential` for credential management
- Never store passwords in plain text

### Error Handling & Logging
```swift
// ❌ NEVER: Expose sensitive data
throw NetworkError.authenticationFailed(username: user.email)

// ✅ CORRECT: Generic errors
throw NetworkError.authenticationFailed
Logger.log(.error, "Auth failed", parameters: ["userId": user.anonymizedId])
```

### Input Validation
```swift
extension String {
    var sanitizedForWeb: String {
        return self.replacingOccurrences(of: "<", with: "&lt;")
                   .replacingOccurrences(of: ">", with: "&gt;")
    }
}
```

## Content Blocking & Cookies

```swift
// Tracker blocking
let contentBlocker = ContentBlocker(trackerDataSet: TrackerDataSet(data: trackerData))
webView.configuration.userContentController.add(contentBlocker.makeBlockingRules())

// Cookie management
HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
// Preserve cookies only for fireproofed domains
```

## Pre-Commit Checklist

- [ ] No hardcoded secrets/API keys
- [ ] User data properly classified & encrypted
- [ ] HTTPS for all network requests
- [ ] Input validation implemented
- [ ] No sensitive data in errors/logs
- [ ] Data clearing mechanisms tested
- [ ] Privacy impact assessed
