import SwiftUI

struct ReviewChapterListView: View {

    let unit: ReviewUnitListViewModel.ReviewUnit
    private let headerTitle: String
    private let onSelect: @Sendable (ReviewUnitSelection) -> Void
    private let onClose: () -> Void

    @EnvironmentObject private var mainViewState: MainViewState
    @Environment(\.dismiss) private var dismiss

    init(
        unit: ReviewUnitListViewModel.ReviewUnit,
        headerTitle: String,
        onSelect: @escaping @Sendable (ReviewUnitSelection) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.unit = unit
        self.headerTitle = headerTitle
        self.onSelect = onSelect
        self.onClose = onClose
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                unitSummary

                VStack(spacing: 12) {
                    ForEach(unit.chapters) { chapter in
                        Button {
                            SoundManager.shared.play(.tap)
                            handleSelection(chapter)
                        } label: {
                            chapterRow(chapter)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Color.themeBase)
        .navigationBarBackButtonHidden(true)
        .onAppear(perform: configureHeader)
    }
}

private extension ReviewChapterListView {
    func configureHeader() {
        let backButton = MainViewState.HeaderBackButton(
            title: "戻る",
            destination: .custom
        ) {
            dismiss()
            onClose()
        }
        let title = "\(headerTitle) / \(unit.unit.title)"
        mainViewState.setHeader(title: title, backButton: backButton)
    }

    var unitSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(unit.unitId). \(unit.unit.title)")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.themeTextPrimary)
                if !unit.unit.subtitle.isEmpty {
                    Text(unit.unit.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.themeTextSecondary)
                }
            }

            HStack(spacing: 12) {
                summaryCapsule(
                    title: "章", value: "\(unit.chapterCount)", systemImage: "list.number"
                )
                summaryCapsule(
                    title: "復習対象", value: "\(unit.reviewCount) 問", systemImage: "doc.text"
                )
                Spacer(minLength: 0)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.themeSurfaceElevated, Color.themeSurfaceAlt],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.themeMain.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: Color.themeShadowSoft, radius: 14, x: 0, y: 10)
    }

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
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        colors: [Color.themeSurface, Color.themeSurfaceAlt.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.themeMain.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.themeShadowSoft.opacity(0.8), radius: 10, x: 0, y: 6)
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

    func summaryCapsule(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .semibold))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
            }
        }
        .foregroundColor(.themeTextSecondary)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.themeSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.themeMain.opacity(0.1), lineWidth: 1)
                )
        )
    }

    func handleSelection(_ chapter: ReviewUnitListViewModel.ReviewChapter) {
        let selection = ReviewUnitSelection(
            unitId: unit.unitId,
            unit: unit.unit,
            chapter: chapter.chapter,
            initialQuestionIndex: chapter.initialQuestionIndex,
            questions: chapter.questions
        )
        onSelect(selection)
    }
}
