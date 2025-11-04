import SwiftUI

struct ReviewQuestionListView: View {
    let unit: ReviewUnitListViewModel.ReviewUnit
    let onSelect: (ReviewUnitListViewModel.ReviewChapter) -> Void
    let onClose: () -> Void

    @EnvironmentObject private var mainViewState: MainViewState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                ForEach(unit.chapters) { chapter in
                    Button {
                        SoundManager.shared.play(.tap)
                        onSelect(chapter)
                    } label: {
                        chapterRow(chapter)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
        }
        .background(Color.themeBase)
        .onAppear {
            let backButton = MainViewState.HeaderBackButton(
                title: "◀ 復習",
                destination: .custom,
                action: {
                    dismiss()
                    onClose()
                }
            )
            mainViewState.setHeader(title: unit.unit.title, backButton: backButton)
        }
    }
}

private extension ReviewQuestionListView {
    func chapterRow(_ chapter: ReviewUnitListViewModel.ReviewChapter) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.themeMain, Color.themeSecondary],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(chapter.chapter.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.themeTextPrimary)
                Text("復習対象 \(chapter.reviewCount) 問")
                    .font(.system(size: 13))
                    .foregroundColor(.themeTextSecondary)
            }
            Spacer()
            countBubble(total: chapter.reviewCount)
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

    func countBubble(total: Int) -> some View {
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
}
