# Bookmarks & History

Persistent storage, sync coordination, and cross-platform data models for browsing data.

## Overview

Bookmarks and history are fundamental features of the DuckDuckGo browser, providing users with ways to save and revisit their favorite sites and track their browsing activity. Both systems are built on Core Data, support cross-platform synchronization via Sync, and implement encryption for privacy protection.

The architecture separates concerns between the macOS-specific UI and interaction layers (`BookmarkManager`, `HistoryCoordinator`) and the shared cross-platform data models and sync logic (in `SharedPackages`). This design enables code reuse between macOS and iOS while allowing platform-specific optimizations and UI patterns.

## Architecture

### Bookmarks Architecture

```
macOS UI Layer
├── BookmarkManager (protocol & LocalBookmarkManager)
├── BookmarkListViewController
└── BookmarkDragDropManager
    ↓
Storage Layer (SharedPackages/Bookmarks)
├── LocalBookmarkStore
├── BookmarkDatabase (CoreData)
└── Bookmark/BookmarkFolder models
    ↓
Sync Layer (SharedPackages/BrowserServicesKit)
├── BookmarksProvider (SyncDataProvider)
├── BookmarksResponseHandler
└── Sync encryption & conflict resolution
```

### History Architecture

```
macOS UI Layer
├── HistoryCoordinator (coordinator protocol)
└── History views & controllers
    ↓
Coordinator Layer (SharedPackages/BrowserServicesKit)
└── HistoryCoordinator
    ├── historyDictionary (in-memory cache)
    └── BrowsingHistory (structured output)
        ↓
Storage Layer (SharedPackages/BrowserServicesKit or macOS)
├── HistoryStoring protocol
├── EncryptedHistoryStore (macOS) or HistoryStore (iOS)
└── BrowsingHistoryEntryManagedObject (CoreData)
```

### Cross-Platform Data Models

Both bookmarks and history use shared data models defined in `SharedPackages`:

- **Bookmark**: Core bookmark entity with URL, title, favorite status
- **BookmarkFolder**: Hierarchical folder structure
- **HistoryEntry**: URL visit with metadata and tracking info
- **Visit**: Individual page visit with timestamp

## Key Files

### Bookmarks - macOS Implementation

- **`BookmarkManager.swift`** (`macOS/DuckDuckGo/Bookmarks/Model/BookmarkManager.swift`)
  - `BookmarkManager` protocol defining CRUD operations
  - `LocalBookmarkManager` concrete implementation
  - Sync request coordination
  - Search and query operations

- **`BookmarkListViewController.swift`** (`macOS/DuckDuckGo/Bookmarks/View/BookmarkListViewController.swift`)
  - Main bookmarks sidebar UI
  - Drag & drop support
  - Context menu actions

- **`BookmarkDragDropManager.swift`** (`macOS/DuckDuckGo/Bookmarks/Services/BookmarkDragDropManager.swift`)
  - Drag and drop coordination
  - Pasteboard integration

### Bookmarks - Shared Components

- **`LocalBookmarkStore.swift`** (`SharedPackages/Bookmarks/Sources/Bookmarks/LocalBookmarkStore.swift`)
  - Core Data operations
  - Transaction management
  - Validation and constraints

- **`BookmarkDatabase.swift`** (`SharedPackages/Bookmarks/Sources/Bookmarks/BookmarkDatabase.swift`)
  - Core Data stack setup
  - Migration management

- **`BookmarksProvider.swift`** (`SharedPackages/BrowserServicesKit/Sources/SyncDataProviders/Bookmarks/BookmarksProvider.swift`)
  - Sync integration
  - Conflict resolution
  - Response handling

### History - macOS Implementation

- **`HistoryCoordinator.swift`** (`macOS/DuckDuckGo/History/Model/HistoryCoordinator.swift` or `SharedPackages/BrowserServicesKit/Sources/History/HistoryCoordinator.swift`)
  - In-memory history dictionary management
  - Visit tracking and updating
  - Periodic cleaning of old entries
  - Published history updates via Combine

- **`EncryptedHistoryStore.swift`** (`macOS/DuckDuckGo/History/Services/EncryptedHistoryStore.swift`)
  - macOS-specific encrypted storage
  - Core Data context management
  - Encryption/decryption of URLs and titles

### History - Shared Components

- **`HistoryStoring.swift`** (`SharedPackages/BrowserServicesKit/Sources/History/HistoryStore.swift`)
  - History storage protocol
  - Core Data operations
  - Visit persistence

- **`HistoryEntry.swift`** (`SharedPackages/BrowserServicesKit/Sources/History/HistoryEntry.swift`)
  - History entry model
  - Visit tracking
  - Tracker statistics

### Tab Extensions

- **`HistoryTabExtension.swift`** (`macOS/DuckDuckGo/Tab/TabExtensions/HistoryTabExtension.swift`)
  - Per-tab history tracking
  - Integration with HistoryCoordinator
  - Navigation event handling

## Common Tasks

### Using BookmarkManager (Package API)

The `BookmarkManager` protocol provides bookmark management operations:

```swift
// Add a bookmark
bookmarkManager.makeBookmark(
    for: url,
    title: "Title",
    isFavorite: false,
    index: nil,
    parent: nil
) { error in
    // Handle result
}

// Other operations
let isBookmarked = bookmarkManager.isUrlBookmarked(url: url)
bookmarkManager.makeFolder(named: "Folder", parent: nil) { result in }
bookmarkManager.move(objectUUIDs: uuids, toIndex: 0, withinParentFolder: .root) { error in }
let results = bookmarkManager.search(by: "query")
```

Refer to the `BookmarkManager` protocol for the complete API.

### Using HistoryCoordinator (Package API)

The `HistoryCoordinator` protocol provides history tracking operations:

```swift
// Add a visit
let visit = historyCoordinator.addVisit(of: url, at: Date())

// Track privacy information
historyCoordinator.addBlockedTracker(entityName: "Tracker", on: url)
historyCoordinator.updateTitleIfNeeded(title: "Title", url: url)

// Query history
let history = historyCoordinator.history
let allVisits = historyCoordinator.allHistoryVisits
```

Refer to the `HistoryCoordinating` protocol for the complete API.

## Patterns & Best Practices

### Sync Integration

Both bookmarks and history trigger sync after modifications. The `BookmarkManager` calls `requestSync()` after successful operations, which notifies the sync service. Best practices:
- Always call sync after successful data modifications
- Let the sync scheduler decide when to actually sync
- Handle sync conflicts at the data provider level (`BookmarksProvider`)
- Use timestamps to resolve conflicts (last-write-wins for most fields)

### Undo Support

Bookmarks support undo/redo operations. Pass an `UndoManager` to mutation methods like `remove(bookmark:undoManager:)` and `restore(_:undoManager:)`. The manager registers undo operations with entity snapshots.

### Core Data Threading

Both systems use Core Data with proper concurrency:
- Use `.privateQueueConcurrencyType` for background operations
- Always call `context.perform()` or `context.performAndWait()`
- Don't pass managed objects between threads - use object IDs

See `LocalBookmarkStore` and `HistoryStore` for implementation patterns.

### History Memory Management

`HistoryCoordinator` maintains an in-memory dictionary for performance (O(1) lookup) and reactive updates via Combine. Subscribe to `historyDictionaryPublisher` for change notifications. The coordinator handles periodic persistence to Core Data and regular cleaning.

### Encryption (macOS History)

History is encrypted at rest on macOS via `EncryptedHistoryStore`. Encryption happens transparently in the store layer using system keychain-managed keys and Core Data transformers.

## Data Models

Data models are defined in SharedPackages:

- **`Bookmark`** - URL, title, favorite status (inherits from `BaseBookmarkEntity`)
- **`BookmarkFolder`** - Hierarchical folder with children array
- **`HistoryEntry`** - URL visit with metadata, tracker statistics, and visits array
- **`Visit`** - Individual page visit with timestamp

Refer to `Bookmark.swift`, `BookmarkFolder.swift`, `HistoryEntry.swift`, and `Visit.swift` in SharedPackages for complete definitions.

## Sync Coordination

### Bookmark Sync Flow

1. **Local Change**: User adds/modifies/deletes bookmark
2. **Persist to Core Data**: `LocalBookmarkStore` saves change
3. **Request Sync**: `BookmarkManager.requestSync()` notifies sync service
4. **Sync Scheduler**: Determines when to sync (debounces rapid changes)
5. **BookmarksProvider**: Prepares syncable entities
6. **Encryption**: Sensitive data encrypted before transmission
7. **Server Communication**: Sync engine sends/receives data
8. **Response Handling**: `BookmarksResponseHandler` processes server response
9. **Conflict Resolution**: Merge conflicts using timestamps and rules
10. **Apply Changes**: Update local Core Data with merged state

### Conflict Resolution Strategy

- **Bookmarks**: Last-write-wins based on `modifiedAt` timestamp
- **Deletions**: Tombstones prevent resurrection of deleted items
- **Favorites**: User intent (favorite toggle) takes precedence
- **Folders**: Structural changes reconciled carefully to maintain hierarchy

## Testing

Test bookmarks and history using mock implementations of `BookmarkStore` and `HistoryStoring` to verify data persistence and retrieval.

## Related Topics

- <doc:TabManagement> - How tabs track history via HistoryTabExtension
- ``BookmarkManager`` - Bookmark management protocol
- ``HistoryCoordinating`` - History coordination protocol
- ``LocalBookmarkStore`` - Bookmark persistence
- ``EncryptedHistoryStore`` - Encrypted history storage
- **Sync Documentation** - Cross-platform sync architecture

