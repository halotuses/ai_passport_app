import SwiftUI
import CoreImage.CIFilterBuiltins
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

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
            return "全\(viewModel.totalQuestions)問中\(viewModel.totalCorrect)問に正解"
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
    
    private var completionPercentageDisplay: (value: String, label: String) {
        if let percentage = completionPercentageValue {
            return ("\(percentage)%", "達成度")
        }
        
        if viewModel.totalAnswered > 0 {
            return ("--%", "達成度")
        }
        
        return ("0%", "達成度")
    }
    
    private var completionPercentageValue: Int? {
        guard viewModel.totalQuestions > 0 else { return nil }
        
        return Int((viewModel.completionRate * 100).rounded())
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
        let denominator = progressPercentageDenominator
        
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
    
    private var progressPercentageDenominator: Int? {
        if viewModel.totalQuestions > 0 {
            return viewModel.totalQuestions
        }
        
        let total = viewModel.totalAnswered + max(viewModel.totalUnanswered, 0)
        return total > 0 ? total : nil
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
                startLearningButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 32)
        }
        .background(
            PaperBackground()
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
                        Text(completionPercentageDisplay.value)
                            .font(.system(size: 36, weight: .black, design: .rounded))
                            .foregroundColor(.themeTextPrimary)
                        Text(completionPercentageDisplay.label)
                            .font(.caption.weight(.semibold))
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
                    VStack(spacing: 12) {
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
    
    private var startLearningButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                mainViewState.enterUnitSelection()
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.headline)
                Text("学習を始める")
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
        HStack(spacing: 14) {
            Circle()
                .fill(item.color)
                .frame(width: 12, height: 12)
                .opacity(item.count == 0 ? 0.4 : 1)

            VStack(alignment: .leading, spacing: 4) {
                
                Text(item.label)
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.themeTextPrimary)

                Text("\(item.count)問")
                    .font(.footnote)
                    .foregroundColor(.themeTextSecondary)
            }

            Spacer()

            if let percentageText = item.percentageText {
                Text(percentageText)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(item.count == 0 ? .themeTextSecondary : item.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(item.color.opacity(0.18))
                    )
            }

        }
        .padding(.vertical, 14)
        .padding(.horizontal, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.65), lineWidth: 0.6)
                )
                .shadow(color: Color.themeShadowSoft.opacity(0.35), radius: 14, x: 0, y: 6)
        )
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
                        LinearGradient(
                            colors: isSelected
                            ? [Color.themeMain, Color.themeSecondary]
                            : Array(repeating: Color.themeButtonSecondary.opacity(0.6), count: 2),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
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
private struct PaperBackground: View {
    private let gradient = LinearGradient(
        colors: [
            Color(red: 0.99, green: 0.98, blue: 0.96),
            Color(red: 0.97, green: 0.94, blue: 0.89),
            Color(red: 1.0, green: 0.98, blue: 0.94)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        Rectangle()
            .fill(gradient)
            .overlay(
                NoiseTextureView()
                    .blendMode(.softLight)
                    .opacity(0.08)
            )
    }
}

private struct NoiseTextureView: View {
    private static let noiseImage: Image? = {
        let context = CIContext()
        let filter = CIFilter.randomGenerator()
        let size = CGSize(width: 512, height: 512)
        
        guard
            let outputImage = filter.outputImage?.cropped(to: CGRect(origin: .zero, size: size)),
            let cgImage = context.createCGImage(outputImage, from: CGRect(origin: .zero, size: size))
        else {
            return nil
        }
        
#if canImport(UIKit)
        return Image(uiImage: UIImage(cgImage: cgImage))
#elseif canImport(AppKit)
        return Image(nsImage: NSImage(cgImage: cgImage, size: size))
#else
        return Image(decorative: cgImage, scale: 1.0)
#endif
    }()
    
    var body: some View {
        if let noiseImage = Self.noiseImage {
            noiseImage
                .resizable()
                .scaledToFill()
                .clipped()
        } else {
            Color.clear
        }
    }
}
