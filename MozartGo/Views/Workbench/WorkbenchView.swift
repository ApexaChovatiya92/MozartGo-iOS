import SwiftUI

struct WorkbenchView: View {
    @StateObject private var vm = WorkbenchViewModel()
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @State private var selectedItem: WorkbenchItem?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "#0A0A0F").ignoresSafeArea()

                VStack(spacing: 0) {
                    // Offline banner
                    if !networkMonitor.isConnected {
                        OfflineBanner(message: "Offline — read-only cached view")
                    }

                    // Breadcrumb
                    if !vm.folderPath.isEmpty {
                        BreadcrumbBar(path: vm.folderPath) {
                            Task { await vm.navigateBack() }
                        }
                    }

                    // Filter pills
                    FilterPillsBar(selected: $vm.selectedFilter)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)

                    Divider().background(Color.white.opacity(0.06))

                    // Content
                    if vm.isLoading && vm.items.isEmpty {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#9B6FF5")))
                            .scaleEffect(1.2)
                        Spacer()
                    } else if vm.filteredItems.isEmpty && !vm.isLoading {
                        EmptyWorkbenchState()
                    } else {
                        List {
                            ForEach(vm.filteredItems) { item in
                                NavigationLink(destination: WorkbenchDetailView(item: item)) {
                                    WorkbenchRow(item: item)
                                }
                                .listRowBackground(Color.white.opacity(0.04))
                                .listRowSeparatorTint(Color.white.opacity(0.06))
                                .swipeActions(edge: .trailing) {
                                    if networkMonitor.isConnected {
                                        Button(role: .destructive) {
                                            Task { await vm.deleteItem(item) }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .refreshable {
                            await vm.refresh()
                        }
                    }

                    // Error banner
                    if let error = vm.errorMessage {
                        ErrorBanner(message: error) {
                            vm.errorMessage = nil
                        }
                    }
                }
            }
            .navigationTitle("Workbench")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(hex: "#0E0E16"), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await vm.refresh() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(networkMonitor.isConnected ? Color(hex: "#9B6FF5") : Color.white.opacity(0.3))
                    }
                    .disabled(!networkMonitor.isConnected)
                }
            }
        }
        .task { await vm.loadContents() }
    }
}

// MARK: - Breadcrumb

struct BreadcrumbBar: View {
    let path: [FolderBreadcrumb]
    let onBack: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                Button { onBack() } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "#9B6FF5"))
                }

                Text("Root")
                    .font(.system(size: 12))
                    .foregroundColor(Color.white.opacity(0.4))

                ForEach(path) { crumb in
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(Color.white.opacity(0.25))
                    Text(crumb.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(crumb.id == path.last?.id ? .white : Color.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color.white.opacity(0.04))
    }
}

// MARK: - Filter Pills

struct FilterPillsBar: View {
    @Binding var selected: WorkbenchFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(WorkbenchFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation(.spring(response: 0.3)) { selected = filter }
                    } label: {
                        Text(filter.rawValue)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(selected == filter ? .white : Color.white.opacity(0.5))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                selected == filter
                                ? Color(hex: "#7C4FE4")
                                : Color.white.opacity(0.07)
                            )
                            .cornerRadius(20)
                    }
                }
            }
        }
    }
}

// MARK: - Row

struct WorkbenchRow: View {
    let item: WorkbenchItem

    var icon: String {
        switch item.type {
        case .folder: return "folder.fill"
        case .file:
            guard let ext = item.name.split(separator: ".").last else { return "doc.fill" }
            switch ext.lowercased() {
            case "pdf": return "doc.richtext.fill"
            case "png", "jpg", "jpeg": return "photo.fill"
            case "md", "txt": return "doc.text.fill"
            default: return "doc.fill"
            }
        }
    }

    var iconColor: Color {
        item.type == .folder ? Color(hex: "#F5A623") : Color(hex: "#9B6FF5")
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(item.type.rawValue.capitalized)
                        .font(.system(size: 11))
                        .foregroundColor(iconColor.opacity(0.8))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(iconColor.opacity(0.1))
                        .cornerRadius(4)

                    if let date = item.updatedAt {
                        Text(date.formatted(.relative(presentation: .named)))
                            .font(.system(size: 11))
                            .foregroundColor(Color.white.opacity(0.3))
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(Color.white.opacity(0.2))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty State

struct EmptyWorkbenchState: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color(hex: "#F5A623").opacity(0.08))
                    .frame(width: 80, height: 80)
                Image(systemName: "folder")
                    .font(.system(size: 32))
                    .foregroundColor(Color(hex: "#F5A623").opacity(0.6))
            }

            Text("No items here")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.7))

            Text("Pull to refresh or create items\nin the web app.")
                .font(.system(size: 14))
                .foregroundColor(Color.white.opacity(0.35))
                .multilineTextAlignment(.center)
            Spacer()
        }
    }
}

// MARK: - Detail View

struct WorkbenchDetailView: View {
    let item: WorkbenchItem
    @EnvironmentObject var networkMonitor: NetworkMonitor

    var body: some View {
        ZStack {
            Color(hex: "#0A0A0F").ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header card
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(itemColor.opacity(0.15))
                                .frame(width: 60, height: 60)
                            Image(systemName: item.type == .folder ? "folder.fill" : "doc.fill")
                                .font(.system(size: 26))
                                .foregroundColor(itemColor)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            Text(item.type.rawValue.capitalized)
                                .font(.system(size: 13))
                                .foregroundColor(Color.white.opacity(0.45))
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(16)

                    // Metadata
                    VStack(alignment: .leading, spacing: 0) {
                        metaRow(label: "ID", value: item.id)
                        Divider().background(Color.white.opacity(0.06))
                        if let date = item.createdAt {
                            metaRow(label: "Created", value: date.formatted(date: .long, time: .shortened))
                            Divider().background(Color.white.opacity(0.06))
                        }
                        if let date = item.updatedAt {
                            metaRow(label: "Modified", value: date.formatted(date: .long, time: .shortened))
                            Divider().background(Color.white.opacity(0.06))
                        }
                        metaRow(label: "Status", value: networkMonitor.isConnected ? "Online" : "Cached")
                    }
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(14)

                    // Content preview (if file has content)
                    if let content = item.content, !content.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Content")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Color.white.opacity(0.5))
                                .textCase(.uppercase)
                                .tracking(0.8)

                            Text(content)
                                .font(.system(size: 14, design: .monospaced))
                                .foregroundColor(Color.white.opacity(0.75))
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.04))
                                .cornerRadius(12)
                        }
                    }

                    if !networkMonitor.isConnected {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(Color(hex: "#E87B3C"))
                            Text("Read-only mode while offline. Changes require a connection.")
                                .font(.system(size: 13))
                                .foregroundColor(Color.white.opacity(0.5))
                        }
                        .padding(14)
                        .background(Color(hex: "#E87B3C").opacity(0.08))
                        .cornerRadius(12)
                    }
                }
                .padding(16)
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(hex: "#0E0E16"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    var itemColor: Color {
        item.type == .folder ? Color(hex: "#F5A623") : Color(hex: "#9B6FF5")
    }

    func metaRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color.white.opacity(0.4))
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.system(size: 13))
                .foregroundColor(Color.white.opacity(0.8))
                .lineLimit(2)
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
