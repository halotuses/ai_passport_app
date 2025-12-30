import SwiftUI
import CoreImage.CIFilterBuiltins
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - ホーム画面ビュー
struct HomeView: View {
    // ViewModel（進捗とホーム全体の状態管理）
    @StateObject private var viewModel: HomeViewModel
    @StateObject private var progressViewModel: HomeProgressViewModel
    
    // 画面遷移やタブ管理用のEnvironmentオブジェクト
    @EnvironmentObject private var mainViewState: MainViewState
    
    // アプリがアクティブ／バックグラウンドになるのを監視
    @Environment(\.scenePhase) private var scenePhase
    
    // クイック試験用の日数プリセット
    private let quickExamOffsets: [Int] = [0, 30, 60, 90]
    
    // 初期化処理：HomeViewModelを受け取り、その中のprogressViewModelもセット
    init(viewModel: HomeViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _progressViewModel = StateObject(wrappedValue: viewModel.progressViewModel)
    }
    
    // MARK: - 試験日バインディング
    private var examDateBinding: Binding<Date> {
        Binding(
            get: { viewModel.examDate },
            set: { newDate in viewModel.updateExamDate(newDate) }
        )
    }
    
    // MARK: - 学習進捗テキスト
    private var progressSummaryText: String {
        if progressViewModel.totalQuestions > 0 {
            return "全\(progressViewModel.totalQuestions)問中\(progressViewModel.totalAnswered)問に回答済"
        }
        if progressViewModel.totalAnswered > 0 {
            return "これまでに\(progressViewModel.totalAnswered)問に挑戦しました"
        }
        return progressViewModel.isLoading
        ? "学習データを取得しています"
        : "学習を始めると進捗がここに表示されます"
    }
    
    // 円グラフ下に表示する詳細テキスト
    private var progressRingDetailText: String? {
        guard progressViewModel.totalQuestions > 0 else { return nil }
        return progressSummaryText
    }

    // タイトル下に表示する概要文（問題がない場合のみ）
    private var headerSummaryText: String? {
        progressRingDetailText == nil ? progressSummaryText : nil
    }

    // 達成度（%）計算
    private var completionPercentageValue: Int? {
        guard progressViewModel.totalQuestions > 0 else { return nil }
        return Int((progressViewModel.completionRate * 100).rounded())
    }
    
    // 達成度表示用（数値＋ラベル）
    private var completionPercentageDisplay: (value: String, label: String) {
        if let percentage = completionPercentageValue {
            return ("\(percentage)%", "達成度")
        }
        if progressViewModel.totalAnswered > 0 {
            return ("--%", "達成度")
        }
        return ("0%", "達成度")
    }
    
    // 正解割合（グラフ用）
    private var correctProgressValue: Double {
        if progressViewModel.totalQuestions > 0 {
            return progressViewModel.completionRate
        }
        let answered = progressViewModel.totalAnswered
        guard answered > 0 else { return 0 }

        return min(max(Double(progressViewModel.totalCorrect) / Double(answered), 0), 1)
    }
    
    // 不正解割合（グラフ用）
    private var incorrectProgressValue: Double {
        if progressViewModel.totalQuestions > 0 {
            return min(
                max(Double(progressViewModel.totalIncorrect) / Double(progressViewModel.totalQuestions), 0),
                1
            )
        }
        let answered = progressViewModel.totalAnswered
        guard answered > 0 else { return 0 }

        return min(max(Double(progressViewModel.totalIncorrect) / Double(answered), 0), 1)
    }
    
    // 未回答数
    private var unansweredCount: Int {
        max(progressViewModel.totalUnanswered, 0)
    }
    
    // 試験日までのカウントダウンテキスト
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
    
    // メッセージタイトル
    private var encouragementTitle: String {
        viewModel.daysUntilExam == nil ? "今日のひとこと" : "いまのあなたへのメッセージ"
    }
    
    // MARK: - メインビュー構築
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 28) {
                progressCard         // 学習進捗カード
                VStack(spacing: 16) {
                    startLearningButton  // 学習開始ボタン
                    startReviewButton   // 復習開始ボタン
                }
            }
            .frame(maxWidth: 520)
            .padding(.horizontal, 24)
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
    
    // MARK: - 学習進捗カード
    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // タイトル行
            HStack(alignment: .center, spacing: 12) {
                Label("学習進捗", systemImage: "chart.pie.fill")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.themeTextPrimary)
                Spacer()
                if let headerSummaryText {
                    Text(headerSummaryText)
                        .font(.footnote.weight(.medium))
                        .foregroundColor(.themeTextSecondary)
                }
                if progressViewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.themeSecondary)
                }
            }
            
            // 円グラフ＋統計3列
            VStack(spacing: 20) {
                ProgressRingView(
                    correctProgress: correctProgressValue,
                    incorrectProgress: incorrectProgressValue,
                    titleText: completionPercentageDisplay.label,
                    valueText: completionPercentageDisplay.value,
                    detailText: progressRingDetailText,
                    highlightValue: (completionPercentageValue ?? 0) == 100
                )
                HStack(spacing: 8) {
                    StatColumnView(color: .themeCorrect, label: "正解", value: progressViewModel.totalCorrect)
                    StatColumnView(color: .themeIncorrect, label: "不正解", value: progressViewModel.totalIncorrect)
                    StatColumnView(color: .gray, label: "未回答", value: unansweredCount)
                }
            }
            .frame(maxWidth: .infinity)

            Divider().background(Color.gray.opacity(0.2))
            
            // 回答履歴リンク
            NavigationLink(
                isActive: $mainViewState.isShowingAnswerHistory,
                destination: {
                    AnswerHistoryView()
                },
                label: {
                    HStack(spacing: 12) {
                        Text("回答履歴を見る")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.themeSecondary)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundColor(.themeSecondary)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.themeButtonSecondary.opacity(0.14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.themeSecondary.opacity(0.12), lineWidth: 1)
                            )
                    )
                }
            )
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.96),
                            Color.white.opacity(0.86)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.45), lineWidth: 1)
                        .blendMode(.overlay)
                )
        )
        .shadow(color: Color.themeSecondary.opacity(0.14), radius: 20, x: 0, y: 14)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    // MARK: - 学習開始ボタン
    private var startLearningButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                mainViewState.enterUnitSelection()
            }
        } label: {
            ZStack {
                HStack(spacing: 12) {
                    Image(systemName: "play.fill").font(.headline)
                    Text("学習を始める").font(.headline)
                }
                .frame(maxWidth: .infinity)
                HStack {
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .foregroundColor(.white)
            .padding(.vertical, 20)
            .padding(.horizontal, 28)
            .frame(maxWidth: 360)
            .background(
                LinearGradient(
                    colors: [
                        Color.themeSecondary,
                        Color.themeMain,
                        Color.themeAccent.opacity(0.9)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(24)
            .shadow(color: Color.themeSecondary.opacity(0.35), radius: 18, x: 0, y: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    private var startReviewButton: some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                mainViewState.enterReview()
            }
        } label: {
            ZStack {
                HStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.2.circlepath").font(.headline)
                    Text("復習を始める").font(.headline)
                }
                .frame(maxWidth: .infinity)
                HStack {
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .foregroundColor(.white)
            .padding(.vertical, 20)
            .padding(.horizontal, 28)
            .frame(maxWidth: 360)
            .background(
                LinearGradient(
                    colors: [
                        Color.themeSecondary,
                        Color.themeMain,
                        Color.themeAccent.opacity(0.9)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(24)
            .shadow(color: Color.themeSecondary.opacity(0.35), radius: 18, x: 0, y: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 円グラフコンポーネント
private struct ProgressRingView: View {
    let correctProgress: Double
    let incorrectProgress: Double
    let titleText: String
    let valueText: String
    let detailText: String?
    let highlightValue: Bool
    
    @State private var animatedCorrect: Double = 0
    @State private var animatedIncorrect: Double = 0
    
    private let ringLineWidth: CGFloat = 20
    private let ringSize: CGFloat = 188
    
    private var clampedAnimatedCorrect: Double { max(0, min(animatedCorrect, 1)) }
    private var clampedAnimatedIncorrect: Double { max(0, min(animatedIncorrect, 1)) }
    
    private static func sanitize(_ value: Double) -> Double {
        guard value.isFinite else { return 0 }
        return max(0, min(value, 1))
    }
    
    private var isIndeterminate: Bool {
        correctProgress < 0 || incorrectProgress < 0
    }
    
    private var incorrectSegmentRange: ClosedRange<Double>? {
        let end = min(clampedAnimatedIncorrect, 1)
        guard end > 0 else { return nil }
        return 0...end
    }

    private var correctSegmentRange: ClosedRange<Double>? {
        let start = min(clampedAnimatedIncorrect, 1)
        let end = min(start + clampedAnimatedCorrect, 1)
        guard end > start else { return nil }
        return start...end
    }
    
    @ViewBuilder
    private var valueTextView: some View {
        if highlightValue {
            Text(valueText)
                .font(.title.weight(.bold))
                .foregroundStyle(LinearGradient.crownGold)
        } else {
            Text(valueText)
                .font(.title.weight(.bold))
                .foregroundColor(.themeTextPrimary)
        }
    }
    
    private var shouldUseCrownGradientForCorrectSegment: Bool {
        guard !isIndeterminate else { return false }
        return Self.sanitize(correctProgress) >= 1 && Self.sanitize(incorrectProgress) <= 0
    }

    private var correctSegmentGradient: AngularGradient {
        if shouldUseCrownGradientForCorrectSegment {
            return AngularGradient(gradient: .crownGold, center: .center)
        } else {
            return AngularGradient(
                gradient: Gradient(colors: [Color.themeCorrect.opacity(0.9), Color.themeCorrect]),
                center: .center
            )
        }
    }
    
    var body: some View {
        ZStack {
            // ベースリング（グレー背景）
            Circle().stroke(Color.themeTextSecondary.opacity(0.12), lineWidth: ringLineWidth)
            
            if isIndeterminate {
                // データ未確定時（点線アニメーション）
                Circle()
                    .trim(from: 0, to: 0.85)
                    .stroke(
                        Color.themeTextSecondary.opacity(0.25),
                        style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round, dash: [1, 6])
                    )
                    .rotationEffect(.degrees(-90))
            } else {
                if let incorrectSegmentRange {
                    // 不正解部分（先に描画して背面に配置）
                    Circle()
                        .trim(
                            from: CGFloat(incorrectSegmentRange.lowerBound),
                            to: CGFloat(incorrectSegmentRange.upperBound)
                        )
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [Color.themeIncorrect.opacity(0.85), Color.themeIncorrect]),
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }

                if let correctSegmentRange {
                    // 正解部分（最後に描画して最前面に配置）
                    Circle()
                        .trim(
                            from: CGFloat(correctSegmentRange.lowerBound),
                            to: CGFloat(correctSegmentRange.upperBound)
                        )
                        .stroke(
                            correctSegmentGradient,
                            style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                }
            }
            
            // 中央テキスト
            VStack(spacing: 6) {
                Text(titleText)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.themeTextSecondary)
                valueTextView
                if let detailText, !detailText.isEmpty {
                    Text(detailText)
                        .font(.footnote)
                        .foregroundColor(.themeTextSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(width: ringSize, height: ringSize)
        .onAppear { animateToCurrentProgress() }
        .onChange(of: correctProgress) { _ in animateToCurrentProgress() }
        .onChange(of: incorrectProgress) { _ in animateToCurrentProgress() }
    }
    
    // アニメーション更新
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


// MARK: - 統計小コンポーネント
private struct StatColumnView: View {
    let color: Color
    let label: String
    let value: Int
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(.caption)
                .foregroundColor(.themeTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text("\(value)問")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.themeTextPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.75))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.themeTextSecondary.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - 背景グラデーション＋ノイズ
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

// MARK: - ノイズテクスチャ（粒子風背景）
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
            noiseImage.resizable().scaledToFill().clipped()
        } else {
            Color.clear
        }
    }
}
