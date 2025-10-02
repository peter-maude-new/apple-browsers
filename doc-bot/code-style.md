---
alwaysApply: true
title: "Swift Code Style Guide"
description: "Swift code style and conventions for DuckDuckGo browser development including naming, formatting, and best practices"
keywords: ["Swift", "code style", "naming conventions", "formatting", "best practices", "async/await", "property wrappers", "SwiftLint"]
---

# Swift Code Style Guide

**Line margin**: 150 characters | **Indentation**: 4 spaces | **SwiftLint**: Enforced

## Naming

| Type | Convention | Examples |
|------|-----------|----------|
| Types/Protocols | UpperCamelCase | `UserAuthenticationManager`, `DataSourceProtocol` |
| Variables/Functions | lowerCamelCase | `maximumRetryCount`, `fetchUserData()` |
| Booleans | Assertions | `isEnabled`, `hasCompleted`, `canDelete` |
| Protocols (capability) | -able, -ible, -ing | `Loadable`, `Refreshable`, `UserAuthenticating` |
| Factory methods | make... | `makeLocationManager()` |
| Mutating methods | verb (no suffix) | `sort()`, `append()` |
| Non-mutating | -ed, -ing | `sorted()`, `appending()` |

### Delegate Methods
```swift
// ✅ CORRECT - unnamed first parameter is delegate source
func namePickerView(_ namePickerView: NamePickerView, didSelectName name: String)

// ❌ WRONG
func didSelectName(namePicker: NamePickerViewController, name: String)
```

## Code Organization

```swift
// 1. Imports (minimal)
import UIKit

// 2. Protocols
protocol FeatureDelegate: AnyObject { }

// 3. Main type
class FeatureViewController: UIViewController {
    // Properties, lifecycle, private methods
}

// 4. Extensions for protocol conformance
// MARK: - UITableViewDataSource
extension FeatureViewController: UITableViewDataSource { }
```

## Formatting

### Spacing
```swift
// ✅ Colons: no space left, one right
class TestDatabase: Database {
    var data: [String: CGFloat] = ["A": 1.2]
}

// ✅ Braces: open same line, close new line
if user.isHappy {
    // Do something
} else {
    // Do something else
}
```

### Function Declarations
```swift
// ✅ Short: one line
func reticulateSplines(spline: [Double]) -> Bool { }

// ✅ Long: each parameter on new line
func reticulateSplines(spline: [Double],
                      adjustmentFactor: Double,
                      translateConstant: Int) -> Bool { }
```

### Closures
```swift
// ✅ Trailing closure: single closure at end only
UIView.animate(withDuration: 1.0) {
    self.myView.alpha = 0
}

// ✅ Multiple closures: no trailing closure
UIView.animate(withDuration: 1.0, animations: {
    self.myView.alpha = 0
}, completion: { finished in
    self.myView.removeFromSuperview()
})
```

## Types & Constants

### Core Rules
- Use Swift native types (`String`, `Double` not `NSString`, `NSNumber`)
- Use `let` by default, `var` only when needed
- Prefer type inference: `let message = "text"` not `let message: String = "text"`
- Empty collections need type: `var names: [String] = []` not `var names = [String]()`
- Use syntactic sugar: `[String]` not `Array<String>`

### Constants
```swift
// ✅ CORRECT - Type properties
enum Math {
    static let e = 2.718281828459045235360287
}

// ❌ WRONG - Global constants
let e = 2.718281828459045235360287
```

## Optionals

```swift
// ✅ Shadow original names
if let subview = subview, let volume = volume { }

// ✅ Optional chaining for single access
textContainer?.textLabel?.setNeedsDisplay()

// ✅ Optional binding for multiple operations
if let textContainer = textContainer {
    // Multiple operations
}

// ❌ WRONG
if let unwrappedSubview = optionalSubview { }
```

## Memory Management

```swift
// ✅ CORRECT - Weak self pattern
resource.request().onComplete { [weak self] response in
    guard let self = self else { return }
    let model = self.updateModel(response)
    self.updateUI(model)
}

// ❌ WRONG - Strong self (reference cycle)
resource.request().onComplete { response in
    self.updateUI()
}

// ❌ WRONG - unowned (may crash)
resource.request().onComplete { [unowned self] response in
    self.updateUI()
}
```

## Access Control

- Order: access control first, except for `static` and attributes
- Prefer `private` to `fileprivate` (use `fileprivate` only when compiler requires)

```swift
// ✅ CORRECT
private let message = "text"
static private let timeConstant = 88.0
@IBAction private func activate() { }
```

## Control Flow

### Loops
```swift
// ✅ CORRECT - for-in style
for _ in 0..<3 {
    print("Hello")
}

// ❌ WRONG - while style
var i = 0
while i < 3 { i += 1 }
```

### Golden Path (Guard)
```swift
// ✅ CORRECT - Use guard for early exit
func computeFFT(context: Context?, inputData: InputData?) throws -> Frequencies {
    guard let context = context else { throw FFTError.noContext }
    guard let inputData = inputData else { throw FFTError.noInputData }
    return frequencies
}

// ❌ WRONG - Nested if
if let context = context {
    if let inputData = inputData {
        // Nested code
    }
}
```

### Ternary Operator
Use only when it increases clarity. Avoid complex nested ternaries.

## Classes & Structs

### Core Rules
- Use `final` when inheritance not intended
- Avoid `self` unless required by compiler
- Omit `get` clause for read-only computed properties

```swift
final class Circle: Shape {
    var radius: Double
    var diameter: Double { radius * 2 }  // Implicit get

    init(radius: Double) {
        self.radius = radius  // self required
    }

    func area() -> Double {
        Double.pi * radius * radius  // self not needed
    }
}
```

## DuckDuckGo Patterns

### Design System (MANDATORY)
```swift
// ✅ REQUIRED
label.textColor = UIColor(designSystemColor: .textPrimary)
Text("Title").daxBody()

// ❌ FORBIDDEN
label.textColor = .black
Text("Title").font(.title)
```

### Dependency Injection
```swift
// ✅ REQUIRED
init(dependencies: DependencyProvider = AppDependencyProvider.shared) {
    self.service = dependencies.featureService
}
```

### Logging
```swift
// ✅ REQUIRED
Logger.general.debug("State changed")
Logger.network.info("Request completed")

// ❌ FORBIDDEN
print("Debug message")
```

## Prohibited

| ❌ Forbidden | ✅ Correct |
|-------------|-----------|
| Emoji in code | Clear text names |
| `#colorLiteral`, `#imageLiteral` | Explicit constructors / DesignResourcesKit |
| Parentheses around conditionals | `if name == "Hello"` |
| Semicolons | Omit them |
| `print()` statements | `Logger` extensions |

## Logging & Testing

### Logging
```swift
import os

private let logger = Logger(subsystem: "com.duckduckgo.browser", category: "FeatureManager")

func performAction() {
    logger.debug("Starting action: \(parameter, privacy: .public)")
    logger.info("Action completed")
    logger.error("Action failed: \(error.localizedDescription, privacy: .public)")
}
```

### Test Naming
```swift
// ✅ CORRECT - when/then convention
func testWhenUrlIsNotATrackerThenMatchesIsFalse() { }
func testWhenUserTapsBookmarkButtonThenBookmarkIsAdded() { }
```

## Quick Reference

**Naming**: UpperCamelCase types, lowerCamelCase variables, assertion booleans
**Spacing**: 4 spaces, 150 char line, colons (no space left, one right)
**Types**: Native Swift, `let` default, type inference, `[String]` not `Array<String>`
**Optionals**: Shadow names, optional chaining for single access
**Memory**: `[weak self]` in closures, avoid `unowned`
**Control**: `for-in` loops, `guard` for golden path
**DRK**: `Color(designSystemColor:)`, `.daxBody()`, `Logger` not `print()`
