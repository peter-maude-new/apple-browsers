---
alwaysApply: true
title: "Anti-patterns and Common Mistakes"
description: "Anti-patterns to avoid and common mistakes to prevent in DuckDuckGo browser development including singleton misuse, memory leaks, and performance issues"
keywords: ["anti-patterns", "common mistakes", "singletons", "memory leaks", "async/await", "error handling", "performance", "testing"]
---

# Anti-patterns and Common Mistakes to Avoid

## Singleton Anti-patterns

### ❌ NEVER: .shared Singletons Without DI
```swift
// ❌ WRONG
FeatureManager.shared.performAction()

// ✅ CORRECT - Use dependency injection
final class ViewModel {
    private let featureManager: FeatureManagerProtocol
    init(dependencies: DependencyProvider = AppDependencyProvider.shared) {
        self.featureManager = dependencies.featureManager
    }
}
```

### ❌ NEVER: Global State
Use injected dependencies, not global variables.

## Async/Await Anti-patterns

### ❌ NEVER: UI Updates Without @MainActor
```swift
// ❌ WRONG
class ViewModel: ObservableObject {
    @Published var isLoading = false
    func loadData() async { isLoading = true }  // May crash
}

// ✅ CORRECT
@MainActor
class ViewModel: ObservableObject {
    @Published var isLoading = false
    func loadData() async { isLoading = true }  // Safe
}
```

### ❌ NEVER: Unhandled Async Errors
```swift
// ❌ WRONG: Swallow errors
try? await networkService.getData()

// ✅ CORRECT: Handle errors
do {
    try await networkService.getData()
} catch {
    logger.error("Failed: \(error)")
    await showError(error)
}
```

### ❌ NEVER: Block Main Thread
Use `async`/`await`, not synchronous operations on @MainActor.

## Memory Management

### ❌ NEVER: Strong Reference Cycles
```swift
// ❌ WRONG
Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
    self.updateUI()  // Cycle - ViewController never deallocates
}

// ✅ CORRECT
Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
    self?.updateUI()
}
```

### ❌ NEVER: Cache View Controllers
Cache view models, not view controllers (they contain stale data and strong references).

## Error Handling

### ❌ NEVER: Force Unwrap
```swift
// ❌ WRONG
let user = getCurrentUser()!
let name = user.name!

// ✅ CORRECT
guard let user = getCurrentUser(), let name = user.name else {
    showErrorMessage("User information unavailable")
    return
}
```

### ❌ NEVER: Generic Errors
```swift
// ❌ WRONG
print("Something went wrong")

// ✅ CORRECT
enum NetworkError: LocalizedError {
    case noConnection, timeout, unauthorized, serverError(Int)
    var errorDescription: String? {
        // Specific user-friendly messages
    }
}
```

## SwiftUI Anti-patterns

### ❌ NEVER: Heavy Computation in View Body
```swift
// ❌ WRONG - Computed every view update
var body: some View {
    Text(expensiveProcessing(item))
}

// ✅ CORRECT - Pre-compute in ViewModel
var body: some View {
    Text(viewModel.processedItems[index].displayText)
}
```

### ❌ NEVER: Direct State Mutation in View
Use ViewModel for state management, not direct @State manipulation.

## Design System

### ❌ NEVER: Hardcoded Colors/Icons
```swift
// ❌ WRONG
Image(systemName: "star").foregroundColor(.blue)
Text("Title").foregroundColor(.black)

// ✅ CORRECT
Image(uiImage: DesignSystemImages.Color.Size16.star)
    .foregroundColor(Color(designSystemColor: .accent))
Text("Title")
    .foregroundColor(Color(designSystemColor: .textPrimary))
```

## Network & API

### ❌ NEVER: Hardcoded URLs/Keys
```swift
// ❌ WRONG
let url = URL(string: "https://api.example.com/data")!
let apiKey = "abc123xyz"

// ✅ CORRECT - Use configuration
struct APIConfiguration {
    let baseURL: URL
    let apiKey: String
    static let production = APIConfiguration(
        baseURL: URL(string: "https://api.duckduckgo.com")!,
        apiKey: Bundle.main.object(forInfoDictionaryKey: "API_KEY") as! String
    )
}
```

## Testing

### ❌ NEVER: Test Implementation Details
Test public behavior, not private methods.

### ❌ NEVER: Meaningless Tests
```swift
// ❌ WRONG
func testInitialization() {
    let viewModel = ViewModel()
    // No assertions
}

// ✅ CORRECT
func testInitializationSetsDefaultState() {
    let viewModel = ViewModel()
    XCTAssertEqual(viewModel.state, .idle)
    XCTAssertTrue(viewModel.items.isEmpty)
}
```

## Performance

### ❌ NEVER: Sync Operations on Main Thread
```swift
// ❌ WRONG
@MainActor
func processLargeDataSet() {
    let result = heavyComputation()  // Blocks UI
}

// ✅ CORRECT
@MainActor
func processLargeDataSet() async {
    let result = await Task.detached { heavyComputation() }.value
}
```

## Communication

### ❌ NEVER: Celebrate Partial Results
```
❌ "✅ MISSION ACCOMPLISHED!" (when tests failing)
❌ "🎯 Outstanding Achievement:" (when incomplete)
✅ "7 tests still failing. Continuing to fix."
✅ "Progress made but incomplete. Working on remaining issues."
```

**Never celebrate when:**
- Tests failing
- Tasks incomplete
- Work in progress

**Only summarize when:**
- ALL tests pass (100%)
- Task completely finished
- No work remaining

## Quick Reference

| Anti-Pattern | Correct Approach |
|--------------|-----------------|
| `.shared` singleton | Dependency injection via AppDependencyProvider |
| Global state | Injected dependencies |
| UI updates without @MainActor | Mark ViewModel with @MainActor |
| Strong self in closures | `[weak self]` |
| Force unwrap `!` | `guard let` or optional binding |
| `print()` statements | `Logger.general/network/ui` |
| Hardcoded colors/icons | DesignResourcesKit |
| Hardcoded URLs/keys | Configuration/environment |
| Heavy computation in view | Pre-compute in ViewModel |
| Sync on main thread | `async`/`await` |
