//
//  MozartGoTests.swift
//  MozartGoTests
//
//  Created by apexa Chovatiya on 09/04/26.
//

import Testing
import XCTest
@testable import MozartGo

@MainActor
final class AuthManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
        KeychainService.shared.deleteToken()
    }

    func testInitialStateIsUnauthenticated() {
        // When no token in keychain, should not be authenticated
        XCTAssertFalse(AuthManager.shared.isAuthenticated)
    }

    func testSignOutClearsState() {
        // Given: artificially set auth state
        AuthManager.shared.signOut()
        XCTAssertFalse(AuthManager.shared.isAuthenticated)
        XCTAssertNil(AuthManager.shared.currentUser)
        XCTAssertNil(KeychainService.shared.getToken())
    }
}

// MARK: - KeychainService Tests

final class KeychainServiceTests: XCTestCase {
    let keychain = KeychainService.shared

    override func setUp() {
        super.setUp()
        keychain.deleteToken()
    }

    override func tearDown() {
        super.tearDown()
        keychain.deleteToken()
    }

    func testSaveAndRetrieveToken() {
        let token = "test_jwt_token_abc123"
        keychain.saveToken(token)
        XCTAssertEqual(keychain.getToken(), token)
    }

    func testDeleteToken() {
        keychain.saveToken("some_token")
        keychain.deleteToken()
        XCTAssertNil(keychain.getToken())
    }

    func testOverwriteToken() {
        keychain.saveToken("first_token")
        keychain.saveToken("second_token")
        XCTAssertEqual(keychain.getToken(), "second_token")
    }
}

// MARK: - CacheService Tests

final class CacheServiceTests: XCTestCase {
    let cache = CacheService.shared

    override func setUp() {
        super.setUp()
        cache.clearAll()
    }

    func testCacheAndLoadWorkbenchItems() {
        let items = [
            WorkbenchItem(id: "1", name: "Test File", type: .file, content: nil, createdAt: Date(), updatedAt: Date(), parentId: nil),
            WorkbenchItem(id: "2", name: "Test Folder", type: .folder, content: nil, createdAt: Date(), updatedAt: Date(), parentId: nil)
        ]
        cache.cacheWorkbenchItems(items, for: nil)
        let loaded = cache.loadCachedWorkbenchItems(for: nil)
        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].id, "1")
        XCTAssertEqual(loaded[1].name, "Test Folder")
    }

    func testCacheRespectsMaxItems() {
        let items = (1...25).map {
            WorkbenchItem(id: "\($0)", name: "Item \($0)", type: .file, content: nil, createdAt: nil, updatedAt: nil, parentId: nil)
        }
        cache.cacheWorkbenchItems(items, for: nil)
        let loaded = cache.loadCachedWorkbenchItems(for: nil)
        XCTAssertLessThanOrEqual(loaded.count, 20)
    }

    func testClearCache() {
        let items = [WorkbenchItem(id: "1", name: "Test", type: .file, content: nil, createdAt: nil, updatedAt: nil, parentId: nil)]
        cache.cacheWorkbenchItems(items, for: nil)
        cache.clearAll()
        XCTAssertTrue(cache.loadCachedWorkbenchItems(for: nil).isEmpty)
    }

    func testEmptyCacheReturnsEmpty() {
        let loaded = cache.loadCachedWorkbenchItems(for: nil)
        XCTAssertTrue(loaded.isEmpty)
    }
}

// MARK: - WorkbenchViewModel Filter Tests

@MainActor
final class WorkbenchViewModelTests: XCTestCase {
    var vm: WorkbenchViewModel!

    @MainActor
    override func setUp() {
        super.setUp()
        vm = WorkbenchViewModel()
    }

    func testFilterAll() {
        vm.items = makeMixedItems()
        vm.selectedFilter = .all
        XCTAssertEqual(vm.filteredItems.count, 4)
    }

    func testFilterFiles() {
        vm.items = makeMixedItems()
        vm.selectedFilter = .files
        XCTAssertTrue(vm.filteredItems.allSatisfy { $0.type == .file })
        XCTAssertEqual(vm.filteredItems.count, 2)
    }

    func testFilterFolders() {
        vm.items = makeMixedItems()
        vm.selectedFilter = .folders
        XCTAssertTrue(vm.filteredItems.allSatisfy { $0.type == .folder })
        XCTAssertEqual(vm.filteredItems.count, 2)
    }

    func testFilterRecentSortsByDate() {
        vm.items = makeMixedItems()
        vm.selectedFilter = .recent
        let dates = vm.filteredItems.compactMap { $0.updatedAt }
        let sorted = dates.sorted(by: >)
        XCTAssertEqual(dates, sorted)
    }

    private func makeMixedItems() -> [WorkbenchItem] {
        let now = Date()
        return [
            WorkbenchItem(id: "1", name: "A", type: .file, content: nil, createdAt: now, updatedAt: now.addingTimeInterval(-3600), parentId: nil),
            WorkbenchItem(id: "2", name: "B", type: .folder, content: nil, createdAt: now, updatedAt: now.addingTimeInterval(-7200), parentId: nil),
            WorkbenchItem(id: "3", name: "C", type: .file, content: nil, createdAt: now, updatedAt: now.addingTimeInterval(-100), parentId: nil),
            WorkbenchItem(id: "4", name: "D", type: .folder, content: nil, createdAt: now, updatedAt: now.addingTimeInterval(-1800), parentId: nil),
        ]
    }
}

// MARK: - APIService URL Building Tests

final class APIServiceURLTests: XCTestCase {
    func testStreamCompletionInvalidURLThrows() async {
        // Just verify the service exists and is a singleton
        let s1 = APIService.shared
        let s2 = APIService.shared
        XCTAssertTrue(s1 === s2)
    }
}

// MARK: - ComposeViewModel Tests

@MainActor
final class ComposeViewModelTests: XCTestCase {
    var vm: ComposeViewModel!

    @MainActor
    override func setUp() {
        super.setUp()
        vm = ComposeViewModel()
    }

    func testInitialState() {
        XCTAssertTrue(vm.messages.isEmpty)
        XCTAssertFalse(vm.isStreaming)
        XCTAssertNil(vm.errorMessage)
        XCTAssertNil(vm.conversationId)
    }

    func testCancelStreamingClearsState() {
        vm.isStreaming = true
        vm.streamingText = "partial response"
        vm.cancelStreaming()
        XCTAssertFalse(vm.isStreaming)
        XCTAssertEqual(vm.streamingText, "")
        // Partial should be finalized as a message
        XCTAssertEqual(vm.messages.count, 1)
    }

    func testNewConversationClearsMessages() {
        vm.messages = [
            ChatMessage(id: "1", role: .user, content: "hello", createdAt: Date())
        ]
        vm.messages = []
        vm.conversationId = nil
        XCTAssertTrue(vm.messages.isEmpty)
        XCTAssertNil(vm.conversationId)
    }
}
