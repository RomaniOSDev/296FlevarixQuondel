import SwiftUI

struct Feature2View: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var selectedCategoryId: String = "all"
    @State private var searchText = ""
    @State private var patternFilter: PatternKind?
    @State private var favoritesOnly = false
    @State private var renameTarget: TextureItem?
    @State private var renameText = ""
    @State private var showRenameAlert = false
    @State private var tagsTarget: TextureItem?
    @State private var suggestSource: TextureItem?

    private var filtered: [TextureItem] {
        store.sortedTextures.filter { item in
            if selectedCategoryId != "all", item.categoryId != selectedCategoryId { return false }
            if favoritesOnly, !item.isFavorite { return false }
            if let patternFilter, item.patternKind != patternFilter { return false }
            let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            if q.isEmpty { return true }
            let haystack = ([item.name, store.categoryName(for: item.categoryId), item.patternKind.title] + item.tags)
                .joined(separator: " ")
                .lowercased()
            return haystack.contains(q.lowercased())
        }
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        Group {
            if store.textures.isEmpty {
                EmptyStateView(
                    symbol: "paintbrush",
                    title: "Library is Empty",
                    message: "Saved textures appear here by category. Create one in Designer to begin organizing.",
                    actionTitle: "Open Designer"
                ) {
                    store.selectedTab = 0
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        Image("img_card")
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 100)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color("AppAccent").opacity(0.35), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.35), radius: 10, y: 6)

                        SoftCard {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 10) {
                                    NavigationLink {
                                        CompareTexturesView()
                                    } label: {
                                        Label("Compare", systemImage: "rectangle.split.2x1")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(Color("AppPrimary"))
                                    }
                                    NavigationLink {
                                        BlendTexturesView()
                                    } label: {
                                        Label("Blend", systemImage: "circle.lefthalf.filled")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(Color("AppPrimary"))
                                    }
                                    Spacer()
                                }

                                TextField("Search name, tag, pattern…", text: $searchText)
                                    .textFieldStyle(.plain)
                                    .padding(10)
                                    .background(Color("AppBackground").opacity(0.55))
                                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .foregroundStyle(Color("AppTextPrimary"))

                                HStack {
                                    Text("Sort")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color("AppTextSecondary"))
                                    Spacer()
                                    Picker("Sort", selection: $store.sortOrder) {
                                        ForEach(TextureSortOrder.allCases) { order in
                                            Text(order.title).tag(order)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(Color("AppPrimary"))
                                }

                                Toggle(isOn: $favoritesOnly) {
                                    Label("Favorites only", systemImage: "heart.fill")
                                        .foregroundStyle(Color("AppTextPrimary"))
                                }
                                .tint(Color("AppPrimary"))

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        patternChip(nil, title: "Any Pattern")
                                        ForEach(PatternKind.allCases) { kind in
                                            patternChip(kind, title: kind.title)
                                        }
                                    }
                                }

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        categoryChip(id: "all", title: "All", symbol: "square.grid.2x2.fill")
                                        ForEach(store.categories) { cat in
                                            categoryChip(id: cat.id, title: cat.name, symbol: cat.symbol)
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if filtered.isEmpty {
                            Text("No textures match your filters.")
                                .font(.subheadline)
                                .foregroundStyle(Color("AppTextSecondary"))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                        } else {
                            LazyVGrid(columns: columns, spacing: 12) {
                                ForEach(filtered) { item in
                                    SwipeableTextureCard(
                                        item: item,
                                        categoryName: store.categoryName(for: item.categoryId),
                                        onApply: { store.applyTexture(item) },
                                        onRename: {
                                            renameTarget = item
                                            renameText = item.name
                                            showRenameAlert = true
                                        },
                                        onDelete: { store.deleteTexture(item) },
                                        onFavorite: { store.toggleFavorite(item) },
                                        onDuplicate: { store.duplicateTexture(item) },
                                        onTags: { tagsTarget = item },
                                        onSuggest: { suggestSource = item }
                                    )
                                }
                            }
                        }

                        if let source = suggestSource ?? store.textures.first {
                            let similar = store.similarTextures(to: source, limit: 6)
                            if !similar.isEmpty {
                                SoftCard {
                                    VStack(alignment: .leading, spacing: 10) {
                                        HStack {
                                            Text("Similar to \(source.name)")
                                                .font(.headline.weight(.bold))
                                                .foregroundStyle(Color("AppTextPrimary"))
                                                .lineLimit(1)
                                            Spacer()
                                            if suggestSource != nil {
                                                Button("Clear") {
                                                    suggestSource = nil
                                                }
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(Color("AppPrimary"))
                                            }
                                        }
                                        ScrollView(.horizontal, showsIndicators: false) {
                                            HStack(spacing: 10) {
                                                ForEach(similar) { item in
                                                    VStack(spacing: 6) {
                                                        TextureThumbnail(item: item, size: 68)
                                                        Text(item.name)
                                                            .font(.caption2)
                                                            .foregroundStyle(Color("AppTextSecondary"))
                                                            .lineLimit(1)
                                                            .frame(width: 68)
                                                        Button("Apply") {
                                                            store.applyTexture(item)
                                                        }
                                                        .font(.caption2.weight(.semibold))
                                                        .foregroundStyle(Color("AppPrimary"))
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 24)
                }
            }
        }
        .alert("Rename Texture", isPresented: $showRenameAlert) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                if let target = renameTarget {
                    store.renameTexture(target, to: renameText)
                }
            }
        } message: {
            Text("Choose a clear name for this texture.")
        }
        .sheet(item: $tagsTarget) { item in
            TagsEditView(item: item)
                .environmentObject(store)
        }
    }

    private func categoryChip(id: String, title: String, symbol: String) -> some View {
        let selected = selectedCategoryId == id
        return Button {
            HapticService.light()
            selectedCategoryId = id
        } label: {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.caption)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(selected ? Color.white : Color("AppTextPrimary"))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(selected ? Color("AppPrimary") : Color("AppBackground").opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func patternChip(_ kind: PatternKind?, title: String) -> some View {
        let selected = patternFilter == kind
        return Button {
            HapticService.light()
            patternFilter = kind
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(selected ? Color.white : Color("AppTextPrimary"))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selected ? Color("AppAccent") : Color("AppBackground").opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct SwipeableTextureCard: View {
    let item: TextureItem
    let categoryName: String
    var onApply: () -> Void
    var onRename: () -> Void
    var onDelete: () -> Void
    var onFavorite: () -> Void
    var onDuplicate: () -> Void
    var onTags: () -> Void
    var onSuggest: () -> Void

    @State private var offset: CGFloat = 0
    @State private var showFullscreen = false
    private let actionWidth: CGFloat = 132

    var body: some View {
        ZStack(alignment: .trailing) {
            HStack(spacing: 0) {
                Spacer()
                Button {
                    HapticService.light()
                    withAnimation(.easeOut(duration: 0.2)) { offset = 0 }
                    onRename()
                } label: {
                    Image(systemName: "pencil")
                        .foregroundStyle(.white)
                        .frame(width: 66, height: 66)
                        .background(Color("AppPrimary"))
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.easeOut(duration: 0.2)) { offset = 0 }
                    onDelete()
                } label: {
                    Image(systemName: "trash.fill")
                        .foregroundStyle(.white)
                        .frame(width: 66, height: 66)
                        .background(Color.red.opacity(0.9))
                }
                .buttonStyle(.plain)
            }
            .frame(maxHeight: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            cardContent
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 12)
                        .onChanged { value in
                            let next = min(0, max(-actionWidth, value.translation.width))
                            offset = next
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
                                offset = value.translation.width < -50 ? -actionWidth : 0
                            }
                        }
                )
        }
        .contextMenu {
            Button(action: onFavorite) {
                Label(item.isFavorite ? "Unfavorite" : "Favorite", systemImage: item.isFavorite ? "heart.slash" : "heart")
            }
            Button(action: onDuplicate) { Label("Duplicate", systemImage: "plus.square.on.square") }
            Button(action: onTags) { Label("Edit Tags", systemImage: "tag") }
            Button(action: onSuggest) { Label("Find Similar", systemImage: "sparkle.magnifyingglass") }
            Button(action: onRename) { Label("Rename", systemImage: "pencil") }
            Button(action: onApply) { Label("Apply", systemImage: "checkmark.circle") }
            Button(role: .destructive, action: onDelete) { Label("Delete", systemImage: "trash") }
        }
        .fullScreenCover(isPresented: $showFullscreen) {
            FullscreenTexturePreview(item: item)
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                TextureCanvasView(item: item, cornerRadius: 14)
                    .frame(height: 110)
                    .shadow(color: .black.opacity(0.28), radius: 8, y: 4)
                    .onTapGesture {
                        showFullscreen = true
                    }

                Button(action: onFavorite) {
                    Image(systemName: item.isFavorite ? "heart.fill" : "heart")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(item.isFavorite ? Color("AppPrimary") : .white)
                        .padding(6)
                        .background(Color.black.opacity(0.35))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(6)
            }

            Text(item.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("AppTextPrimary"))
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            if !item.tags.isEmpty {
                Text(item.tags.prefix(3).joined(separator: " · "))
                    .font(.caption2)
                    .foregroundStyle(Color("AppAccent"))
                    .lineLimit(1)
            }

            HStack {
                Text(categoryName)
                    .font(.caption2)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .lineLimit(1)
                Spacer()
                Button(action: onDuplicate) {
                    Image(systemName: "plus.square.on.square")
                        .foregroundStyle(Color("AppTextSecondary"))
                }
                .buttonStyle(.plain)
                Button(action: onApply) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color("AppPrimary"))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(
            LinearGradient(
                colors: [Color("AppSurface"), Color("AppSurface").opacity(0.85)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(item.isFavorite ? Color("AppPrimary").opacity(0.55) : Color("AppAccent").opacity(0.28), lineWidth: 1)
        )
    }
}
