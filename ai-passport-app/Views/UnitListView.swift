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
            mainViewState.setHeader(title: "学習アプリ")
            viewModel.refreshIfNeeded()
        }
    }

    private func unitRowView(key: String, unit: QuizMetadata) -> some View {
        let total = viewModel.quizCounts[key] ?? 0

        return HStack {
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.themeMain)
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
                    .fill(Color.themeMain.opacity(0.18))
                    .frame(width: 40, height: 40)
                Text("\(total)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.themeTextPrimary)
            }
        }
        .padding(12)
        .background(Color.themeSurfaceElevated)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.themeMain.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}
