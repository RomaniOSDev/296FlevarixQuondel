import SwiftUI
import UIKit

struct Feature1View: View {
    @EnvironmentObject private var store: AppDataStore

    @State private var draft = TextureItem.fresh()
    @State private var selectedColor = Color(hex: "FF0090")
    @State private var nameText = ""
    @State private var tagsText = ""
    @State private var shakeSave = 0
    @State private var showAppliedPulse = false
    @State private var showFullscreen = false
    @State private var undoStack: [DraftSnapshot] = []
    @State private var redoStack: [DraftSnapshot] = []

    private var challenge: DailyChallenge { DailyChallenge.today }

    private var previewItem: TextureItem {
        var item = draft
        item.red = ColorComponents.red(selectedColor)
        item.green = ColorComponents.green(selectedColor)
        item.blue = ColorComponents.blue(selectedColor)
        return item
    }

    private var designerSimilar: [TextureItem] {
        var probe = draft
        probe.red = ColorComponents.red(selectedColor)
        probe.green = ColorComponents.green(selectedColor)
        probe.blue = ColorComponents.blue(selectedColor)
        return store.similarTextures(to: probe, limit: 6)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    BannerImageCard(imageName: "img_banner", height: 110)

                    SoftCard {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Daily Challenge")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(Color("AppTextPrimary"))
                                Spacer()
                                Text(challenge.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color("AppPrimary"))
                                    .lineLimit(1)
                            }
                            Text(challenge.prompt)
                                .font(.subheadline)
                                .foregroundStyle(Color("AppTextSecondary"))
                                .fixedSize(horizontal: false, vertical: true)
                            Button("Apply Challenge") {
                                pushUndo()
                                applyChallenge()
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Canvas Preview")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(Color("AppTextPrimary"))
                                Spacer()
                                Button {
                                    HapticService.light()
                                    showFullscreen = true
                                } label: {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                        .foregroundStyle(Color("AppPrimary"))
                                }
                                .buttonStyle(.plain)
                            }

                            TextureCanvasView(
                                color: selectedColor,
                                grain: draft.grain,
                                opacity: draft.opacity,
                                patternScale: draft.patternScale,
                                patternKind: draft.patternKind,
                                patternAngle: draft.patternAngle,
                                patternDensity: draft.patternDensity,
                                patternThickness: draft.patternThickness
                            )
                            .frame(height: 220)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color("AppPrimary"), Color("AppAccent").opacity(0.4)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1.5
                                    )
                            )
                            .shadow(color: Color("AppPrimary").opacity(0.25), radius: showAppliedPulse ? 18 : 10, y: 6)
                            .scaleEffect(showAppliedPulse ? 1.02 : 1)
                            .animation(.easeInOut(duration: 0.28), value: showAppliedPulse)
                            .onTapGesture {
                                showFullscreen = true
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    SoftCard {
                        VStack(alignment: .leading, spacing: 14) {
                            TextField("Texture name", text: $nameText)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Color("AppBackground").opacity(0.55))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .foregroundStyle(Color("AppTextPrimary"))

                            TextField("Tags (comma separated)", text: $tagsText)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Color("AppBackground").opacity(0.55))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .foregroundStyle(Color("AppTextPrimary"))

                            ColorPicker("Base Color", selection: $selectedColor, supportsOpacity: false)
                                .foregroundStyle(Color("AppTextPrimary"))
                                .onChange(of: selectedColor) { _ in
                                    store.rememberColor(selectedColor.toHexString())
                                }

                            if !store.colorHistory.isEmpty {
                                Text("Recent Colors")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color("AppTextSecondary"))
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(store.colorHistory, id: \.self) { hex in
                                            Button {
                                                pushUndo()
                                                selectedColor = Color(hex: hex)
                                                HapticService.light()
                                            } label: {
                                                Circle()
                                                    .fill(Color(hex: hex))
                                                    .frame(width: 28, height: 28)
                                                    .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }

                            labeledSlider("Grain", value: $draft.grain)
                            labeledSlider("Opacity", value: $draft.opacity)
                            labeledSlider("Pattern Scale", value: $draft.patternScale)
                            labeledSlider("Angle", value: $draft.patternAngle)
                            labeledSlider("Density", value: $draft.patternDensity)
                            labeledSlider("Thickness", value: $draft.patternThickness)

                            Text("Pattern")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color("AppTextSecondary"))

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(PatternKind.allCases) { kind in
                                        Button {
                                            pushUndo()
                                            HapticService.light()
                                            draft.patternKind = kind
                                        } label: {
                                            Text(kind.title)
                                                .font(.caption.weight(.semibold))
                                                .foregroundStyle(draft.patternKind == kind ? Color.white : Color("AppTextPrimary"))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 8)
                                                .background(
                                                    draft.patternKind == kind
                                                    ? Color("AppPrimary")
                                                    : Color("AppBackground").opacity(0.55)
                                                )
                                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            Text("Category")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color("AppTextSecondary"))

                            Picker("Category", selection: $draft.categoryId) {
                                ForEach(store.categories) { cat in
                                    Text(cat.name).tag(cat.id)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(Color("AppPrimary"))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack(spacing: 10) {
                        Button("Inspire") {
                            pushUndo()
                            inspire()
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button("New") {
                            pushUndo()
                            HapticService.light()
                            resetDraft()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }

                    HStack(spacing: 10) {
                        Button("Apply") {
                            applyDraft()
                        }
                        .buttonStyle(PrimaryButtonStyle())

                        Button("Save") {
                            saveDraft()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .modifier(ShakeEffect(animatableData: CGFloat(shakeSave)))
                    }

                    if store.textures.isEmpty {
                        EmptyStateView(
                            symbol: "scribble.variable",
                            title: "No Textures Yet",
                            message: "Tune grain, opacity, and pattern scale, then save your first design.",
                            actionTitle: "Start Fresh"
                        ) {
                            resetDraft()
                        }
                        .frame(minHeight: 220)
                    } else {
                        SoftCard {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Recent Patterns")
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(Color("AppTextPrimary"))
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(store.userPatterns.prefix(8)) { pattern in
                                            Button {
                                                pushUndo()
                                                HapticService.light()
                                                draft.patternKind = pattern.patternKind
                                                draft.patternScale = pattern.patternScale
                                                draft.grain = pattern.grain
                                            } label: {
                                                VStack(spacing: 6) {
                                                    TextureCanvasView(
                                                        color: selectedColor,
                                                        grain: pattern.grain,
                                                        opacity: draft.opacity,
                                                        patternScale: pattern.patternScale,
                                                        patternKind: pattern.patternKind,
                                                        patternAngle: draft.patternAngle,
                                                        patternDensity: draft.patternDensity,
                                                        patternThickness: draft.patternThickness,
                                                        cornerRadius: 10
                                                    )
                                                    .frame(width: 64, height: 64)
                                                    Text(pattern.patternKind.title)
                                                        .font(.caption2)
                                                        .foregroundStyle(Color("AppTextSecondary"))
                                                        .lineLimit(1)
                                                }
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if !designerSimilar.isEmpty {
                            SoftCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Similar Ideas")
                                        .font(.headline.weight(.bold))
                                        .foregroundStyle(Color("AppTextPrimary"))
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 10) {
                                            ForEach(designerSimilar) { item in
                                                Button {
                                                    pushUndo()
                                                    loadItem(item)
                                                    HapticService.light()
                                                } label: {
                                                    VStack(spacing: 6) {
                                                        TextureThumbnail(item: item, size: 64)
                                                        Text(item.name)
                                                            .font(.caption2)
                                                            .foregroundStyle(Color("AppTextSecondary"))
                                                            .lineLimit(1)
                                                            .frame(width: 64)
                                                    }
                                                }
                                                .buttonStyle(.plain)
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
            .navigationTitle("Designer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        undo()
                    } label: {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .disabled(undoStack.isEmpty)

                    Button {
                        redo()
                    } label: {
                        Image(systemName: "arrow.uturn.forward")
                    }
                    .disabled(redoStack.isEmpty)
                }
            }
            .screenBackground()
            .fullScreenCover(isPresented: $showFullscreen) {
                FullscreenTexturePreview(item: previewItem)
            }
            .onAppear {
                selectedColor = store.lastUsedColor
                draft.grain = store.defaultGrain
                draft.red = ColorComponents.red(selectedColor)
                draft.green = ColorComponents.green(selectedColor)
                draft.blue = ColorComponents.blue(selectedColor)
            }
            .onReceive(NotificationCenter.default.publisher(for: .dataReset)) { _ in
                resetDraft()
                undoStack = []
                redoStack = []
            }
        }
    }

    private func labeledSlider(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
                Spacer()
                Text("\(Int(value.wrappedValue * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(Color("AppTextPrimary"))
            }
            Slider(value: value, in: 0.05...1)
                .tint(Color("AppPrimary"))
        }
    }

    private func syncColorIntoDraft(_ item: inout TextureItem) {
        item.red = ColorComponents.red(selectedColor)
        item.green = ColorComponents.green(selectedColor)
        item.blue = ColorComponents.blue(selectedColor)
        item.name = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
        if item.name.isEmpty {
            item.name = "\(item.patternKind.title) \(store.categoryName(for: item.categoryId))"
        }
        item.tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
    }

    private func syncColorIntoDraft() {
        syncColorIntoDraft(&draft)
    }

    private func currentSnapshot() -> DraftSnapshot {
        var item = draft
        syncColorIntoDraft(&item)
        return DraftSnapshot(item: item, nameText: nameText, tagsText: tagsText, colorHex: selectedColor.toHexString())
    }

    private func pushUndo() {
        undoStack.append(currentSnapshot())
        if undoStack.count > 40 { undoStack.removeFirst() }
        redoStack.removeAll()
    }

    private func applySnapshot(_ snap: DraftSnapshot) {
        draft = snap.item
        nameText = snap.nameText
        tagsText = snap.tagsText
        selectedColor = Color(hex: snap.colorHex)
    }

    private func undo() {
        guard let last = undoStack.popLast() else { return }
        redoStack.append(currentSnapshot())
        applySnapshot(last)
        HapticService.light()
    }

    private func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(currentSnapshot())
        applySnapshot(next)
        HapticService.light()
    }

    private func saveDraft() {
        let trimmed = nameText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty && store.textures.isEmpty == false {
            withAnimation { shakeSave += 1 }
        }
        syncColorIntoDraft()
        let isNew = store.textures.contains(where: { $0.id == draft.id }) == false
        store.saveTexture(draft, isNew: isNew)
        nameText = draft.name
        tagsText = draft.tags.joined(separator: ", ")
    }

    private func applyDraft() {
        syncColorIntoDraft()
        store.applyTexture(draft)
        if let updated = store.textures.first(where: { $0.id == draft.id }) {
            draft = updated
            nameText = updated.name
            tagsText = updated.tags.joined(separator: ", ")
        }
        withAnimation {
            showAppliedPulse = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            showAppliedPulse = false
        }
    }

    private func resetDraft() {
        draft = TextureItem.fresh(
            color: store.lastUsedColor,
            grain: store.defaultGrain
        )
        selectedColor = store.lastUsedColor
        nameText = ""
        tagsText = ""
    }

    private func inspire() {
        let inspired = InspirePresets.random()
        draft = inspired
        selectedColor = inspired.color
        nameText = ""
        tagsText = inspired.tags.joined(separator: ", ")
        HapticService.success()
        store.showBanner("Inspired look ready")
    }

    private func applyChallenge() {
        let c = challenge
        draft.patternKind = c.patternKind
        draft.categoryId = c.categoryId
        draft.grain = c.grain
        draft.patternScale = 0.45 + Double(abs(c.id.hashValue % 40)) / 100.0
        draft.patternAngle = 0.3 + Double(abs(c.id.hashValue % 50)) / 100.0
        draft.patternDensity = 0.4
        draft.patternThickness = 0.5
        selectedColor = Color(hex: c.colorHex)
        nameText = c.title
        tagsText = "challenge, \(c.patternKind.title.lowercased())"
        HapticService.success()
    }

    private func loadItem(_ item: TextureItem) {
        draft = item.duplicated(nameSuffix: "")
        draft.name = item.name
        draft.id = UUID()
        selectedColor = item.color
        nameText = item.name
        tagsText = item.tags.joined(separator: ", ")
    }
}

private struct DraftSnapshot {
    let item: TextureItem
    let nameText: String
    let tagsText: String
    let colorHex: String
}

private enum ColorComponents {
    static func red(_ color: Color) -> Double {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return Double(r)
    }

    static func green(_ color: Color) -> Double {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return Double(g)
    }

    static func blue(_ color: Color) -> Double {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return Double(b)
    }
}
