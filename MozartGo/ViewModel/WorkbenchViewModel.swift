import Foundation
import Combine

enum WorkbenchFilter: String, CaseIterable {
    case all = "All"
    case files = "Files"
    case folders = "Folders"
    case recent = "Recent"
}

@MainActor
final class WorkbenchViewModel: ObservableObject {

    @Published var items: [WorkbenchItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedFilter: WorkbenchFilter = .all
    @Published var currentFolderId: String? = nil
    @Published var folderPath: [FolderBreadcrumb] = []

    private let apiService: APIServiceProtocol
    private let cacheService: CacheService

    init(
        apiService: APIServiceProtocol = MockAPIService(),
        cacheService: CacheService = .shared
    ) {
        self.apiService = apiService
        self.cacheService = cacheService
    }

    // MARK: - Filtered Items

    var filteredItems: [WorkbenchItem] {
        let base: [WorkbenchItem]

        switch selectedFilter {
        case .all:
            base = items

        case .files:
            base = items.filter { $0.type == .file }

        case .folders:
            base = items.filter { $0.type == .folder }

        case .recent:
            base = items.sorted {
                ($0.updatedAt ?? .distantPast) > ($1.updatedAt ?? .distantPast)
            }
        }

        // ✅ Always keep folders first (better UX)
        return base.sorted {
            if $0.type == $1.type {
                return $0.name.lowercased() < $1.name.lowercased()
            }
            return $0.type == .folder
        }
    }

    // MARK: - Load Contents

    func loadContents(folderId: String? = nil) async {
        isLoading = true
        errorMessage = nil

        do {
            let fetched = try await apiService.getFolderContents(folderId: folderId)

            // ✅ Ensure main thread safety (already @MainActor but explicit clarity)
            items = fetched

            // ✅ Cache per folder (important improvement)
            cacheService.cacheWorkbenchItems(fetched, for: folderId)

        } catch let error as URLError where error.code == .notConnectedToInternet {

            let cached = cacheService.loadCachedWorkbenchItems(for: folderId)

            if cached.isEmpty {
                errorMessage = "Offline — no cached data available."
            } else {
                items = cached
                errorMessage = "Offline — showing cached data."
            }

        } catch {

            let cached = cacheService.loadCachedWorkbenchItems(for: folderId)

            if !cached.isEmpty {
                items = cached
                errorMessage = "Network error — showing cached data."
            } else {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    // MARK: - Refresh

    func refresh() async {
        await loadContents(folderId: currentFolderId)
    }

    // MARK: - Navigation

    func navigateInto(folder: WorkbenchItem) async {
        guard folder.type == .folder else { return }

        folderPath.append(
            FolderBreadcrumb(id: folder.id, name: folder.name)
        )

        currentFolderId = folder.id

        await loadContents(folderId: folder.id)
    }

    func navigateBack() async {
        guard !folderPath.isEmpty else { return }

        folderPath.removeLast()
        currentFolderId = folderPath.last?.id

        await loadContents(folderId: currentFolderId)
    }

    // MARK: - Delete

    func deleteItem(_ item: WorkbenchItem) async {
        do {
            switch item.type {
            case .file:
                try await apiService.deleteFile(id: item.id)

            case .folder:
                try await apiService.deleteFolder(id: item.id)
            }

            // ✅ Optimistic UI
            items.removeAll { $0.id == item.id }

            // ✅ Update cache for current folder
            cacheService.cacheWorkbenchItems(items, for: currentFolderId)

        } catch {
            errorMessage = "Delete failed: \(error.localizedDescription)"
        }
    }

    // MARK: - Reset / Root

    func goToRoot() async {
        folderPath.removeAll()
        currentFolderId = nil
        await loadContents(folderId: nil)
    }

    // MARK: - Cache

    func clearCache() {
        cacheService.clearWorkbenchCache()
    }
}
struct FolderBreadcrumb: Identifiable {
    let id: String
    let name: String
}
