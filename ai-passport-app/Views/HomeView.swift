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
        GeometryReader { geometry in
            let layout = HomeLayout(availableSize: geometry.size)

            ScrollView(showsIndicators: false) {
                VStack(spacing: layout.sectionSpacing) {
                    progressCard(layout: layout)
                    VStack(spacing: layout.buttonSpacing) {
                        actionButton(title: "学習を始める", systemImage: "play.fill", isPrimary: true, layout: layout) {
                            mainViewState.enterUnitSelection()
                        }
                        actionButton(title: "復習を始める", systemImage: "arrow.triangle.2.circlepath", isPrimary: false, layout: layout) {
                            mainViewState.enterReview()
                        }
                    }
                }
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, layout.screenHorizontalPadding)
                .padding(.vertical, layout.screenVerticalPadding)
                .frame(minHeight: geometry.size.height, alignment: .top)
            }
            .background(PaperBackground().ignoresSafeArea())
        }
        .onAppear {
            mainViewState.enterHome()
            viewModel.refresh()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.refresh()
            }
        }
    }
    
    // MARK: - 学習進捗カード
    private func progressCard(layout: HomeLayout) -> some View {
        VStack(alignment: .leading, spacing: layout.cardSpacing) {
            // Apple Store のカードのように、補助ラベルと見出しを分けて情報に強弱を付ける。
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("LEARNING OVERVIEW")
                        .font(.caption2.weight(.bold))
                        .tracking(0.6)
                        .foregroundColor(.themeSecondary)
                    Text("学習進捗")
                        .font(.title3.weight(.bold))
                        .foregroundColor(.themeTextPrimary)
                }
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
            VStack(spacing: layout.cardSpacing) {
                ProgressRingView(
                    correctProgress: correctProgressValue,
                    incorrectProgress: incorrectProgressValue,
                    titleText: completionPercentageDisplay.label,
                    valueText: completionPercentageDisplay.value,
                    detailText: progressRingDetailText,
                    highlightValue: (completionPercentageValue ?? 0) == 100,
                    size: layout.ringSize,
                    lineWidth: layout.ringLineWidth
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
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.themeSecondary.opacity(0.07))
                    )
                }
            )
            .buttonStyle(.plain)
        }
        .padding(.horizontal, layout.cardHorizontalPadding)
        .padding(.vertical, layout.cardVerticalPadding)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color.themeSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(Color.black.opacity(0.05), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 10)
    }
    
    // MARK: - ホームアクションボタン
    private func actionButton(
        title: String,
        systemImage: String,
        isPrimary: Bool,
        layout: HomeLayout,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                action()
            }
        } label: {
            ZStack {
                HStack(spacing: 12) {
                    Image(systemName: systemImage).font(.headline)
                    Text(title).font(.headline)
                }
                .frame(maxWidth: .infinity)
                HStack {
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.headline)
                }
            }
            .foregroundColor(isPrimary ? .white : .themeSecondary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: layout.buttonHeight + 2)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(isPrimary ? Color.themeSecondary : Color.themeSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(isPrimary ? Color.clear : Color.themeSecondary.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: isPrimary ? Color.themeSecondary.opacity(0.18) : Color.black.opacity(0.04), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

}

/// 端末の表示領域からホーム固有の余白と部品サイズを算出する。
/// 固定値を各Viewへ散らさず、狭い端末では密度を上げ、広い端末では窮屈さを防ぐ。
private struct HomeLayout {
    let availableSize: CGSize

    private var isCompactHeight: Bool { availableSize.height < 680 }
    private var contentWidth: CGFloat {
        min(availableSize.width - screenHorizontalPadding * 2, 520)
    }

    var screenHorizontalPadding: CGFloat { availableSize.width < 390 ? 14 : 20 }
    var screenVerticalPadding: CGFloat { isCompactHeight ? 16 : 24 }
    var sectionSpacing: CGFloat { isCompactHeight ? 18 : 24 }
    var buttonSpacing: CGFloat { isCompactHeight ? 12 : 14 }
    var cardHorizontalPadding: CGFloat { contentWidth < 350 ? 16 : 20 }
    var cardVerticalPadding: CGFloat { isCompactHeight ? 16 : 20 }
    var cardSpacing: CGFloat { isCompactHeight ? 14 : 18 }
    var buttonHeight: CGFloat { isCompactHeight ? 54 : 60 }
    var ringSize: CGFloat {
        min(max(contentWidth * 0.54, 160), isCompactHeight ? 176 : 204)
    }
    var ringLineWidth: CGFloat { min(max(ringSize * 0.095, 15), 20) }
}

// MARK: - 円グラフコンポーネント
private struct ProgressRingView: View {
    let correctProgress: Double
    let incorrectProgress: Double
    let titleText: String
    let valueText: String
    let detailText: String?
    let highlightValue: Bool
    let size: CGFloat
    let lineWidth: CGFloat
    
    @State private var animatedCorrect: Double = 0
    @State private var animatedIncorrect: Double = 0
    
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
            Circle().stroke(Color.themeTextSecondary.opacity(0.12), lineWidth: lineWidth)
            
            if isIndeterminate {
                // データ未確定時（点線アニメーション）
                Circle()
                    .trim(from: 0, to: 0.85)
                    .stroke(
                        Color.themeTextSecondary.opacity(0.25),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, dash: [1, 6])
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
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
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
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
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
        .frame(width: size, height: size)
        .onAppear { animateToCurrentProgress() }
        .onChange(of: correctProgress) { _, _ in animateToCurrentProgress() }
        .onChange(of: incorrectProgress) { _, _ in animateToCurrentProgress() }
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
        VStack(spacing: 7) {
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
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.themeSurfaceAlt)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.themeTextSecondary.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - 背景グラデーション＋ノイズ
private struct PaperBackground: View {
    private let gradient = LinearGradient(
        colors: [Color.themeBase, Color.themeBase, Color.themeSurfaceAlt],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    var body: some View {
        Rectangle()
            .fill(gradient)
            .overlay(
                NoiseTextureView()
                    .blendMode(.softLight)
                    .opacity(0.015)
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
