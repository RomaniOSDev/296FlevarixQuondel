import SwiftUI

struct CategoriesManageView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var newName = ""
    @State private var newSymbol = "star.fill"
    @State private var renameTarget: TextureCategory?
    @State private var renameText = ""
    @State private var showRename = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                SoftCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("New Category")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                        TextField("Name", text: $newName)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(Color("AppBackground").opacity(0.55))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .foregroundStyle(Color("AppTextPrimary"))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(TextureCategory.symbolChoices, id: \.self) { symbol in
                                    Button {
                                        newSymbol = symbol
                                        HapticService.light()
                                    } label: {
                                        Image(systemName: symbol)
                                            .foregroundStyle(newSymbol == symbol ? Color.white : Color("AppTextPrimary"))
                                            .frame(width: 40, height: 40)
                                            .background(newSymbol == symbol ? Color("AppPrimary") : Color("AppBackground").opacity(0.55))
                                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Button("Add Category") {
                            store.addCategory(name: newName, symbol: newSymbol)
                            newName = ""
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .opacity(newName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                SoftCard {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Your Categories")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .padding(.bottom, 10)

                        ForEach(store.categories) { cat in
                            HStack(spacing: 12) {
                                Image(systemName: cat.symbol)
                                    .foregroundStyle(Color("AppPrimary"))
                                    .frame(width: 28)
                                Text(cat.name)
                                    .foregroundStyle(Color("AppTextPrimary"))
                                Spacer()
                                Button("Rename") {
                                    renameTarget = cat
                                    renameText = cat.name
                                    showRename = true
                                }
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color("AppPrimary"))
                                Button(role: .destructive) {
                                    store.deleteCategory(cat)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red.opacity(0.9))
                                }
                                .buttonStyle(.plain)
                            }
                            .frame(minHeight: 44)
                            if cat.id != store.categories.last?.id {
                                Divider().background(Color("AppTextSecondary").opacity(0.25))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(16)
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("AppSurface"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .screenBackground()
        .alert("Rename Category", isPresented: $showRename) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                if let target = renameTarget {
                    store.renameCategory(target, to: renameText)
                }
            }
        }
    }
}

struct CompareTexturesView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var leftId: UUID?
    @State private var rightId: UUID?

    private var left: TextureItem? {
        store.textures.first(where: { $0.id == leftId }) ?? store.textures.first
    }

    private var right: TextureItem? {
        if let rightId {
            return store.textures.first(where: { $0.id == rightId })
        }
        return store.textures.dropFirst().first ?? store.textures.first
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if store.textures.count < 2 {
                    Text("Save at least two textures to compare.")
                        .foregroundStyle(Color("AppTextSecondary"))
                        .padding()
                } else {
                    SoftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Left")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color("AppTextSecondary"))
                            Picker("Left", selection: Binding(
                                get: { leftId ?? store.textures[0].id },
                                set: { leftId = $0 }
                            )) {
                                ForEach(store.textures) { item in
                                    Text(item.name).tag(Optional(item.id))
                                }
                            }
                            .tint(Color("AppPrimary"))

                            Text("Right")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color("AppTextSecondary"))
                            Picker("Right", selection: Binding(
                                get: { rightId ?? (store.textures.dropFirst().first?.id ?? store.textures[0].id) },
                                set: { rightId = $0 }
                            )) {
                                ForEach(store.textures) { item in
                                    Text(item.name).tag(Optional(item.id))
                                }
                            }
                            .tint(Color("AppPrimary"))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack(spacing: 12) {
                        if let left {
                            comparePane(left, title: "A")
                        }
                        if let right {
                            comparePane(right, title: "B")
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Compare")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("AppSurface"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .screenBackground()
        .onAppear {
            leftId = store.textures.first?.id
            rightId = store.textures.dropFirst().first?.id
        }
    }

    private func comparePane(_ item: TextureItem, title: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("AppPrimary"))
            TextureCanvasView(item: item)
                .frame(height: 180)
            Text(item.name)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("AppTextPrimary"))
                .lineLimit(2)
            Text(item.patternKind.title)
                .font(.caption2)
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color("AppSurface"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct BlendTexturesView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var leftId: UUID?
    @State private var rightId: UUID?
    @State private var mix: Double = 0.5

    private var left: TextureItem? {
        store.textures.first(where: { $0.id == leftId }) ?? store.textures.first
    }

    private var right: TextureItem? {
        store.textures.first(where: { $0.id == rightId }) ?? store.textures.dropFirst().first
    }

    private var preview: TextureItem? {
        guard let left, let right else { return nil }
        return store.blendTextures(left, right, mix: mix)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if store.textures.count < 2 {
                    Text("Save at least two textures to blend.")
                        .foregroundStyle(Color("AppTextSecondary"))
                        .padding()
                } else {
                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Picker("Texture A", selection: Binding(
                                get: { leftId ?? store.textures[0].id },
                                set: { leftId = $0 }
                            )) {
                                ForEach(store.textures) { item in
                                    Text(item.name).tag(Optional(item.id))
                                }
                            }
                            .tint(Color("AppPrimary"))

                            Picker("Texture B", selection: Binding(
                                get: { rightId ?? (store.textures.dropFirst().first?.id ?? store.textures[0].id) },
                                set: { rightId = $0 }
                            )) {
                                ForEach(store.textures) { item in
                                    Text(item.name).tag(Optional(item.id))
                                }
                            }
                            .tint(Color("AppPrimary"))

                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Mix")
                                        .foregroundStyle(Color("AppTextSecondary"))
                                    Spacer()
                                    Text("\(Int(mix * 100))% B")
                                        .foregroundStyle(Color("AppTextPrimary"))
                                        .font(.caption.monospacedDigit())
                                }
                                Slider(value: $mix, in: 0...1)
                                    .tint(Color("AppPrimary"))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let preview {
                        SoftCard {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Blend Preview")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(Color("AppTextPrimary"))
                                TextureCanvasView(item: preview)
                                    .frame(height: 220)
                                Button("Save Blend") {
                                    store.saveTexture(preview, isNew: true)
                                    dismiss()
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .padding(16)
        }
        .navigationTitle("Blend")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color("AppSurface"), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .screenBackground()
        .onAppear {
            leftId = store.textures.first?.id
            rightId = store.textures.dropFirst().first?.id
        }
    }
}

struct TagsEditView: View {
    let item: TextureItem
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Comma-separated tags")
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                TextField("soft, weave, warm", text: $text)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(Color("AppBackground").opacity(0.55))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundStyle(Color("AppTextPrimary"))
                Button("Save Tags") {
                    let tags = text.split(separator: ",").map(String.init)
                    store.updateTags(item, tags: tags)
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle())
                Spacer()
            }
            .padding(16)
            .navigationTitle("Edit Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .screenBackground()
            .onAppear {
                text = item.tags.joined(separator: ", ")
            }
        }
    }
}
