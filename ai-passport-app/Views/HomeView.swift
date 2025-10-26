import SwiftUI
import CoreImage.CIFilterBuiltins
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @StateObject private var progressViewModel: HomeProgressViewModel
    @EnvironmentObject private var mainViewState: MainViewState
    @Environment(\.scenePhase) private var scenePhase
    
    private let quickExamOffsets: [Int] = [0, 30, 60, 90]
    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _progressViewModel = StateObject(wrappedValue: viewModel.progressViewModel)
    }
    
    private var examDateBinding: Binding<Date> {
        Binding(
            get: { viewModel.examDate },
            set: { newDate in viewModel.updateExamDate(newDate) }
        )
    }
    
    private var progressSummaryText: String {
        if progressViewModel.totalQuestions > 0 {
            return "全\(progressViewModel.totalQuestions)問中\(progressViewModel.totalCorrect)問に正解"
        }
        
        if progressViewModel.totalAnswered > 0 {
            return "これまでに\(progressViewModel.totalAnswered)問に挑戦しました"
        }
        
        return progressViewModel.isLoading
        ? "学習データを取得しています"
        : "学習を始めると進捗がここに表示されます"
    }
    
    private var progressRingDetailText: String? {
        guard progressViewModel.totalQuestions > 0 else { return nil }
        return progressSummaryText
    }

    private var headerSummaryText: String? {
        progressRingDetailText == nil ? progressSummaryText : nil
    }

    private var completionPercentageValue: Int? {
        guard progressViewModel.totalQuestions > 0 else { return nil }
        
        return Int((progressViewModel.completionRate * 100).rounded())
    }
    
    private var completionPercentageDisplay: (value: String, label: String) {
        if let percentage = completionPercentageValue {
            return ("\(percentage)%", "達成度")
        }
        
        if progressViewModel.totalAnswered > 0 {
            return ("--%", "達成度")
        }
        
        return ("0%", "達成度")
    }
    
    private var correctProgressValue: Double {
        if completionPercentageValue == nil && progressViewModel.totalAnswered > 0 {
            return -1
        }
        
        return progressViewModel.completionRate
    }
    
    
    private var incorrectProgressValue: Double {
        if completionPercentageValue == nil && progressViewModel.totalAnswered > 0 {
            return -1
        }

        guard progressViewModel.totalQuestions > 0 else { return 0 }

        return min(
            max(Double(progressViewModel.totalIncorrect) / Double(progressViewModel.totalQuestions), 0),
            1
        )
    }
    
    private var unansweredCount: Int {
        max(progressViewModel.totalUnanswered, 0)
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
            HStack(alignment: .center, spacing: 12) {
                Label("学習進捗", systemImage: "chart.pie.fill")
                    .font(.headline)
                    .foregroundColor(.themeTextPrimary)
                
                Spacer()
                if let headerSummaryText {
                    Text(headerSummaryText)
                        .font(.subheadline)
                        .foregroundColor(.themeTextSecondary)
                }
                if progressViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.themeSecondary)
                }
            }
            

            VStack(spacing: 24) {
                ProgressRingView(
                    correctProgress: correctProgressValue,
                    incorrectProgress: incorrectProgressValue,
                    titleText: completionPercentageDisplay.label,
                    valueText: completionPercentageDisplay.value,
                    detailText: progressRingDetailText
                )

                HStack(spacing: 16) {
                    StatColumnView(color: .themeCorrect, label: "正解", value: progressViewModel.totalCorrect)
                    StatColumnView(color: .themeIncorrect, label: "不正解", value: progressViewModel.totalIncorrect)
                    StatColumnView(color: .gray, label: "未回答", value: unansweredCount)
                }
            }
            .frame(maxWidth: .infinity)

            Divider()
                .background(Color.gray.opacity(0.2))
            NavigationLink {
                AnswerHistoryView()
            } label: {
                HStack(spacing: 8) {
                    Text("回答履歴を見る")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.themeSecondary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.themeSecondary)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 4)
        .padding()
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

private struct ProgressRingView: View {
    let correctProgress: Double
    let incorrectProgress: Double
    let titleText: String
    let valueText: String
    let detailText: String?

    @State private var animatedCorrect: Double = 0
    @State private var animatedIncorrect: Double = 0

    private var clampedAnimatedCorrect: Double {
        max(0, min(animatedCorrect, 1))
    }

    private var clampedAnimatedIncorrect: Double {
        max(0, min(animatedIncorrect, 1))
    }

    private static func sanitize(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return max(0, min(value, 1))
    }

    private var isIndeterminate: Bool {
        correctProgress < 0 || incorrectProgress < 0
    }

    private var incorrectSegmentEnd: Double {
        let total = clampedAnimatedCorrect + clampedAnimatedIncorrect
        return min(total, 1)
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.themeTextSecondary.opacity(0.12), lineWidth: 14)

            if isIndeterminate {
                Circle()
                    .trim(from: 0, to: 0.85)
                    .stroke(
                        Color.themeTextSecondary.opacity(0.25),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round, dash: [1, 6])
                    )
                    .rotationEffect(.degrees(-90))
            } else {
                Circle()
                    .trim(from: 0, to: CGFloat(clampedAnimatedCorrect))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [Color.themeCorrect.opacity(0.9), Color.themeCorrect]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                Circle()
                    .trim(from: CGFloat(clampedAnimatedCorrect), to: CGFloat(incorrectSegmentEnd))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [Color.themeIncorrect.opacity(0.85), Color.themeIncorrect]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: 6) {
                Text(titleText)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.themeTextSecondary)
                Text(valueText)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.themeTextPrimary)
                if let detailText, !detailText.isEmpty {
                    Text(detailText)
                        .font(.caption)
                        .foregroundColor(.themeTextSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(width: 148, height: 148)
        .onAppear {
            animateToCurrentProgress()
        }
        .onChange(of: correctProgress) { _ in
            animateToCurrentProgress()
        }
        .onChange(of: incorrectProgress) { _ in
            animateToCurrentProgress()
        }
    }

    private func animateToCurrentProgress() {
        if isIndeterminate {
            withAnimation(.easeOut(duration: 0.5)) {
                animatedCorrect = 0
                animatedIncorrect = 0
            }
        } else {
            let sanitizedCorrect = Self.sanitize(correctProgress)
            let sanitizedIncorrect = Self.sanitize(incorrectProgress)
            withAnimation(.easeOut(duration: 0.8)) {
                animatedCorrect = sanitizedCorrect
                animatedIncorrect = sanitizedIncorrect
            }
        }
    }
}

private struct StatColumnView: View {
    let color: Color
    let label: String
    let value: Int

    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Text(label)
                .font(.caption)
                .foregroundColor(.themeTextSecondary)

            Text("\(value)問")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.themeTextPrimary)
        }
        .frame(maxWidth: .infinity)
    }
}
private struct PaperBackground: View {
    private let gradient = LinearGradient(
        colors: [
            Color.themeBase,
            Color(red: 0.96, green: 0.99, blue: 0.98),
            Color.themeSurfaceElevated
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
                    .opacity(0.04)
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
