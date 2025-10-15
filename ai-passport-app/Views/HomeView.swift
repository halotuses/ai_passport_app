import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject private var mainViewState: MainViewState
    @Environment(\.scenePhase) private var scenePhase

    private let quickExamOffsets: [Int] = [0, 30, 60, 90]
    
    private var examDateBinding: Binding<Date> {
        Binding(
            get: { viewModel.examDate },
            set: { newDate in viewModel.updateExamDate(newDate) }
        )
    }

    private var progressSummaryText: String {
        if viewModel.totalQuestions > 0 {
            return "全\(viewModel.totalQuestions)問中\(viewModel.totalAnswered)問をクリア"
        }

        if viewModel.totalAnswered > 0 {
            return "これまでに\(viewModel.totalAnswered)問に挑戦しました"
        }

        return viewModel.isLoading
            ? "学習データを取得しています"
        : "学習を始めると進捗がここに表示されます"
}

private var progressDetailsText: String? {
    let unanswered = max(viewModel.totalUnanswered, 0)
    guard viewModel.totalAnswered > 0 || unanswered > 0 else { return nil }

    return "正解\(viewModel.totalCorrect)問 / 不正解\(viewModel.totalIncorrect)問 / 未回答\(unanswered)問"
    }

    private var completionPercentageText: String {
        guard viewModel.totalQuestions > 0 else {
            return viewModel.totalAnswered > 0 ? "進捗率 --" : "進捗率 0%"
        }
        
        let percentage = Int((viewModel.completionRate * 100).rounded())
        return "進捗率 \(percentage)%"
    }
    
    private var accuracyText: String {
        guard viewModel.totalAnswered > 0 else {
            return "正答率 --"
        }

        let accuracy = Double(viewModel.totalCorrect) / Double(viewModel.totalAnswered)
        let percentage = Int((accuracy * 100).rounded())
        return "正答率 \(percentage)%"
    }

    private var progressLegendItems: [LegendItem] {
        let unanswered = max(viewModel.totalUnanswered, 0)
        let denominator = viewModel.totalQuestions > 0 ? viewModel.totalQuestions : nil

        func percentageText(for count: Int) -> String? {
            guard let denominator, denominator > 0 else { return nil }
            let value = percentage(for: count, total: denominator)
            return "\(value)%"
        }

        return [
            LegendItem(kind: .correct, label: "正解", count: viewModel.totalCorrect, color: .themeCorrect, percentageText: percentageText(for: viewModel.totalCorrect)),
            LegendItem(kind: .incorrect, label: "不正解", count: viewModel.totalIncorrect, color: .themeIncorrect, percentageText: percentageText(for: viewModel.totalIncorrect)),
            LegendItem(kind: .unanswered, label: "未回答", count: unanswered, color: Color.themeButtonSecondary, percentageText: percentageText(for: unanswered))
        ]
    }

    private var progressSegments: [ProgressSegment] {
        let unanswered = max(viewModel.totalUnanswered, 0)
        let segments = [
            ProgressSegment(kind: .correct, value: Double(viewModel.totalCorrect), color: .themeCorrect, count: viewModel.totalCorrect),
            ProgressSegment(kind: .incorrect, value: Double(viewModel.totalIncorrect), color: .themeIncorrect, count: viewModel.totalIncorrect),
            ProgressSegment(kind: .unanswered, value: Double(unanswered), color: Color.themeButtonSecondary, count: unanswered)
        ]

        let activeSegments = segments.filter { $0.value > 0 }
        if activeSegments.isEmpty {
            return [ProgressSegment(kind: .placeholder, value: 1, color: Color.themeButtonSecondary.opacity(0.35), count: 0)]
        }

        return activeSegments
    }

    private var progressTotalValue: Double {
        progressSegments.reduce(0) { $0 + $1.value }
    }

    private var progressSlices: [SegmentSlice] {
        guard progressTotalValue > 0 else { return [] }

        var start: Double = 0
        return progressSegments.map { segment in
            let end = start + segment.value
            defer { start = end }
            return SegmentSlice(segment: segment, start: start / progressTotalValue, end: end / progressTotalValue)
        }
    }

    private var countdownText: String {
        guard let days = viewModel.daysUntilExam else {
            return "試験日を設定してください"
        }

        if days < 0 {
            return "試験日は \(abs(days)) 日前に終了しました"
        } else if days == 0 {
            return "いよいよ本番の日です！"
        } else if days == 1 {
            return "試験まであと 1 日"
        } else {
            return "試験まであと \(days) 日"
        }
    }

    private var encouragementTitle: String {
        viewModel.daysUntilExam == nil ? "今日のひとこと" : "いまのあなたへのメッセージ"
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                progressCard
                examCountdownCard
                motivationCard
                startLearningButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 32)
        }
        .background(
            LinearGradient(
                colors: [
                    Color.themeBase,
                    Color.themeSurfaceAlt.opacity(0.85),
                    Color.themeSurfaceElevated.opacity(0.9)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onAppear {
            mainViewState.enterHome()
            viewModel.refresh()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                viewModel.refresh()
            }
        }
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 12) {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.themeSecondary)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(Color.themeSecondary.opacity(0.15))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("学習進捗")
                        .font(.headline)
                        .foregroundColor(.themeTextPrimary)
                    Text(progressSummaryText)
                        .font(.subheadline)
                        .foregroundColor(.themeTextSecondary)
                }

                Spacer()
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.themeSecondary)
                }
            }

            HStack(alignment: .center, spacing: 28) {
                MultiSegmentDonutChart(slices: progressSlices) {
                    VStack(spacing: 4) {
                        Text(completionPercentageText)
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundColor(.themeTextPrimary)
                        Text("達成度")
                            .font(.caption)
                            .foregroundColor(.themeTextSecondary)
                    }
                }
                .frame(width: 140, height: 140)

                VStack(alignment: .leading, spacing: 12) {
                    Text(accuracyText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.themeTextPrimary)
                    
                    if let details = progressDetailsText {
                        Text(details)
                            .font(.footnote)
                            .foregroundColor(.themeTextSecondary)
                    }

                    Divider()
                        .background(Color.themeButtonSecondary.opacity(0.4))

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(progressLegendItems) { item in
                            legendRow(for: item)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(
                    LinearGradient(
                        colors: [Color.themeSurface, Color.white.opacity(0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(Color.white.opacity(0.7), lineWidth: 0.6)
                )
                .shadow(color: Color.themeShadowSoft, radius: 18, x: 0, y: 12)
        )
    }

    private var examCountdownCard: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.themeMain)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(Color.themeMain.opacity(0.18))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("試験日カウントダウン")
                        .font(.headline)
                        .foregroundColor(.themeTextPrimary)
                    Text("日付を選んで目標日をセットできます")
                        .font(.subheadline)
                        .foregroundColor(.themeTextSecondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(countdownText)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.themeTextPrimary)
                Text(viewModel.examDate, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.themeTextSecondary)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("ワンタップで設定")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.themeTextSecondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 10)], spacing: 10) {
                    ForEach(quickExamOffsets, id: \.self) { offset in
                        quickExamButton(daysFromNow: offset)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("カスタム日付")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.themeTextSecondary)

                DatePicker("試験日", selection: examDateBinding, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .accentColor(.themeMain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.themeButtonSecondary.opacity(0.35))
                    )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(
                    LinearGradient(
                        colors: [Color.themeSurfaceElevated, Color.themeSurface],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(Color.themeMain.opacity(0.25), lineWidth: 1)
                )
                .shadow(color: Color.themeShadowSoft, radius: 16, x: 0, y: 10)
        )
    }

    private var motivationCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.themeSecondary)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(Color.themeSecondary.opacity(0.18))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(encouragementTitle)
                        .font(.headline)
                        .foregroundColor(.themeTextPrimary)
                    Text("気分を上げて学習を続けましょう")
                        .font(.subheadline)
                        .foregroundColor(.themeTextSecondary)
                }
            }

            Text(viewModel.encouragementMessage)
                .font(.body)
                .foregroundColor(.themeTextPrimary)
                .multilineTextAlignment(.leading)

            Divider()
                .background(Color.themeButtonSecondary.opacity(0.4))

            HStack(spacing: 12) {
                Image(systemName: "bolt.heart.fill")
                    .foregroundColor(.themeSecondary)
                Text("小さな積み重ねが大きな力に。今日も1問チャレンジ！")
                    .font(.footnote)
                    .foregroundColor(.themeTextSecondary)

            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(
                    LinearGradient(
                        colors: [Color.themeSurface, Color.themeSurfaceAlt.opacity(0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(Color.themeSecondary.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.themeSecondary.opacity(0.18), radius: 18, x: 0, y: 12)
        )
    }

    private var startLearningButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                mainViewState.enterUnitSelection()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.headline)
                Text("単元を選んで学習する")
                    .font(.headline)
                    .textCase(.none)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical, 18)
            .padding(.horizontal, 24)
            .background(
                LinearGradient(
                    colors: [Color.themeSecondary, Color.themeMain, Color.themeAccent],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
            .shadow(color: Color.themeSecondary.opacity(0.35), radius: 16, x: 0, y: 10)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func percentage(for count: Int, total: Int) -> Int {
        guard total > 0 else { return 0 }
        return Int((Double(count) / Double(total) * 100).rounded())
    }

    private func legendRow(for item: LegendItem) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(item.color)
                .frame(width: 12, height: 12)
                .opacity(item.count == 0 ? 0.4 : 1)

            Text(item.label)
                .font(.footnote.weight(.semibold))
                .foregroundColor(.themeTextPrimary)

            Spacer()

            HStack(spacing: 6) {
                Text("\(item.count)問")
                    .font(.footnote)
                    .foregroundColor(.themeTextSecondary)

                if let percentageText = item.percentageText {
                    Text(percentageText)
                        .font(.caption)
                        .foregroundColor(item.count == 0 ? .themeTextSecondary : item.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(item.color.opacity(0.15))
                        )
                }
            }
        }
    }

    private func quickExamButton(daysFromNow offset: Int) -> some View {
        let targetDate = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
        let isSelected = Calendar.current.isDate(viewModel.examDate, inSameDayAs: targetDate)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                viewModel.updateExamDate(targetDate)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "calendar")
                    .font(.caption)
                Text(offset == 0 ? "今日" : "あと\(offset)日")
                    .font(.caption.weight(.semibold))
            }
            .foregroundColor(isSelected ? .white : .themeTextPrimary)
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(
                Capsule()
                    .fill(
                        isSelected
                        ? LinearGradient(colors: [Color.themeMain, Color.themeSecondary], startPoint: .leading, endPoint: .trailing)
                        : Color.themeButtonSecondary.opacity(0.6)
                    )
            )
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.white.opacity(0.6) : Color.themeButtonSecondary.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: isSelected ? Color.themeMain.opacity(0.25) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

private extension HomeView {
    struct ProgressSegment {
        enum Kind: Hashable {
            case correct
            case incorrect
            case unanswered
            case placeholder
        }

        let kind: Kind
        let value: Double
        let color: Color
        let count: Int
    }

    struct SegmentSlice: Identifiable {
        let segment: ProgressSegment
        let start: Double
        let end: Double

        var id: ProgressSegment.Kind { segment.kind }
    }

    struct LegendItem: Identifiable {
        let kind: ProgressSegment.Kind
        let label: String
        let count: Int
        let color: Color
        let percentageText: String?

        var id: ProgressSegment.Kind { kind }
    }

    struct MultiSegmentDonutChart<CenterContent: View>: View {
        let slices: [SegmentSlice]
        let lineWidth: CGFloat
        private let centerContent: () -> CenterContent

        init(slices: [SegmentSlice], lineWidth: CGFloat = 18, @ViewBuilder centerContent: @escaping () -> CenterContent) {
            self.slices = slices
            self.lineWidth = lineWidth
            self.centerContent = centerContent
        }

        var body: some View {
            ZStack {
                Circle()
                    .stroke(Color.themeButtonSecondary.opacity(0.3), style: StrokeStyle(lineWidth: lineWidth))

                ForEach(slices) { slice in
                    Circle()
                        .trim(from: slice.start, to: slice.end)
                        .stroke(slice.segment.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }

                centerContent()
            }
        }
    }
}
