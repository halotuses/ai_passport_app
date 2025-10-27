import SwiftUI

/// 単元選択画面
struct UnitListView: View {

    @ObservedObject var viewModel: UnitListViewModel
    @Binding var selectedUnit: QuizMetadata?
    @EnvironmentObject private var mainViewState: MainViewState
    
    

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                if viewModel.isLoading {
                    ProgressView().padding()
                } else if let metadata = viewModel.metadata {
                    ForEach(metadata.sorted(by: { $0.key < $1.key }), id: \.key) { key, unit in
                        Button(action: {
                            SoundManager.shared.play(.tap)
                            mainViewState.selectedUnitKey = key
                            selectedUnit = unit
                        }) {
                            unitRowView(key: key, unit: unit)
                        }
                    }
                } else {
                    Text("データを読み込み中...").padding()
                }
            }
            .padding()
        }
        .background(Color.themeBase)
        .onAppear {
            mainViewState.enterUnitSelection()
            viewModel.refreshIfNeeded()
        }
    }

    private func unitRowView(key: String, unit: QuizMetadata) -> some View {
        let total = viewModel.quizCounts[key] ?? 0

        return HStack {
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.themeMain, Color.themeSecondary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            VStack(alignment: .leading, spacing: 4) {
                Text("\(key). \(unit.title)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.themeTextPrimary)
                Text(unit.subtitle)
                    .font(.system(size: 13))
                    .italic()
                    .foregroundColor(.themeTextSecondary)
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.themeSecondary.opacity(0.3), Color.themeMain.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                Text("\(total)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.themeTextPrimary)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [Color.themeSurfaceElevated, Color.themeSurfaceAlt],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.themeMain.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.themeShadowSoft, radius: 12, x: 0, y: 6)
    }
}
