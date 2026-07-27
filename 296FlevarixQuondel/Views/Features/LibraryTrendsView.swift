import SwiftUI

struct LibraryTrendsView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var segment = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Section", selection: $segment) {
                    Text("Library").tag(0)
                    Text("Trends").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Group {
                    if segment == 0 {
                        Feature2View()
                    } else {
                        Feature3View()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle(segment == 0 ? "Library" : "Trends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color("AppSurface"), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .screenBackground()
        }
    }
}
