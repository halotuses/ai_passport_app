import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject private var mainViewState: MainViewState
    @Environment(\.scenePhase) private var scenePhase

    private var examDateBinding: Binding<Date> {
        Binding(
            get: { viewModel.examDate },
            set: { newDate in viewModel.updateExamDate(newDate) }
        )
    }

    private var progressText: String {
        if viewModel.totalQuestions > 0 {
            return "正解数 \(viewModel.totalCorrect) / \(viewModel.totalQuestions) 問"
        }

        return viewModel.isLoading
            ? "学習データを取得しています"
            : "正解数 \(viewModel.totalCorrect) 問"
    }

    private var completionPercentageText: String {
        let percentage = Int((viewModel.completionRate * 100).rounded())
        return "進捗率 \(percentage)%"
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

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                progressCard
                examCountdownCard
                mascotCard
                startLearningButton
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 32)
        }
        .background(
            LinearGradient(
                colors: [Color.themeBase, Color.themeSurfaceAlt.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
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
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("学習進捗", systemImage: "chart.bar.fill")
                    .font(.headline)
                    .foregroundColor(.themeTextPrimary)
                Spacer()
                if viewModel.isLoading {
                    ProgressView().scaleEffect(0.7)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.themeButtonSecondary.opacity(0.6))
                            .frame(height: 14)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.themeMain, Color.themeSecondary],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(viewModel.completionRate), height: 14)
                            .animation(.easeInOut(duration: 0.6), value: viewModel.completionRate)
                    }
                }
                .frame(height: 14)

                HStack {
                    Text(progressText)
                        .font(.subheadline)
                        .foregroundColor(.themeTextSecondary)
                    Spacer()
                    Text(completionPercentageText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.themeTextPrimary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.themeSurface)
                .shadow(color: Color.themeShadowSoft, radius: 16, x: 0, y: 10)
        )
    }

    private var examCountdownCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("試験日カウントダウン", systemImage: "calendar.badge.clock")
                .font(.headline)
                .foregroundColor(.themeTextPrimary)

            VStack(alignment: .leading, spacing: 8) {
                Text(countdownText)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.themeTextPrimary)
                Text(viewModel.examDate, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.themeTextSecondary)
            }

            DatePicker("試験日", selection: examDateBinding, displayedComponents: .date)
                .datePickerStyle(.compact)
                .accentColor(.themeMain)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.themeSurfaceElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.themeMain.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Color.themeShadowSoft, radius: 14, x: 0, y: 8)
        )
    }

    private var mascotCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.themeMain.opacity(0.25), Color.themeSecondary.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 96, height: 96)
                Text("ゆる")
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundColor(.themeSecondary)
            }

            VStack(spacing: 8) {
                Text("ゆるキャラ応援団")
                    .font(.headline)
                    .foregroundColor(.themeTextPrimary)
                Text(viewModel.encouragementMessage)
                    .font(.body)
                    .foregroundColor(.themeTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 26)
                .fill(Color.themeSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: 26)
                        .stroke(Color.themeSecondary.opacity(0.18), lineWidth: 1)
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
            HStack {
                Spacer()
                Text("単元を選んで学習する")
                    .font(.headline)
                    .foregroundColor(.white)
                Image(systemName: "arrow.right")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding()
            .background(
                LinearGradient(
                    colors: [Color.themeSecondary, Color.themeMain],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(18)
            .shadow(color: Color.themeSecondary.opacity(0.25), radius: 12, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }
}
