import SwiftUI

/// 単元選択画面
struct UnitListView: View {

    @ObservedObject var viewModel: UnitListViewModel
    @Binding var selectedUnit: QuizMetadata?

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                if let metadata = viewModel.metadata {
                    ForEach(metadata.sorted(by: { $0.key < $1.key }), id: \.key) { key, unit in
                        Button(action: { selectedUnit = unit }) {
                            unitRowView(key: key, unit: unit)
                        }
                    }
                } else {
                    Text("データを読み込み中...").padding()
                }
            }
            .padding()
        }
        .background(Color(red: 240/255, green: 255/255, blue: 240/255))
        .onAppear { viewModel.fetchMetadata() }
    }

    private func unitRowView(key: String, unit: QuizMetadata) -> some View {
        let total = viewModel.quizCounts[key] ?? 0

        return HStack {
            Image(systemName: "chevron.right").foregroundColor(.gray)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(key). \(unit.title)").font(.system(size: 16, weight: .bold))
                Text(unit.subtitle).font(.system(size: 13)).italic().foregroundColor(.gray)
            }
            Spacer()
            ZStack {
                Circle().fill(Color.gray.opacity(0.3)).frame(width: 40, height: 40)
                Text("\(total)").font(.system(size: 12))
            }
        }
        .padding(10)
        .background(Color(white: 0.97))
        .cornerRadius(8)
    }
}
