import SwiftUI

struct ResultView: View {
    let correctCount: Int
    let totalCount: Int
    let onRestart: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 24)

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: [Color.themeMain.opacity(0.25), Color.themeAccent.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 160, height: 160)
                Circle()
                    .fill(Color.themeSurface)
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.themeMain.opacity(0.2), radius: 18, x: 0, y: 10)

                Image(systemName: resultIconName)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(Color.themeAccent)
            }

            VStack(spacing: 16) {
                Text(resultMessage)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.themeTextPrimary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 8) {
                    Text("正解数")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.themeTextSecondary)
                    Text("\(correctCount) / \(totalCount)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.themeTextPrimary)
                }

                VStack(spacing: 12) {
                    HStack {
                        Text("正答率")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.themeTextSecondary)
                        Spacer()
                        Text("\(accuracyPercentage)%")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.themeAccent)
                    }

                    ProgressView(value: accuracy)
                        .progressViewStyle(LinearProgressViewStyle(tint: Color.themeAccent))
                        .frame(height: 8)
                        .clipShape(Capsule())
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.themeSurface)
                    .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 12)
            )
            .padding(.horizontal)

            VStack(spacing: 16) {
                Button(action: onRestart) {
                    HStack {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.headline)
                        Text("トップに戻る")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(colors: [Color.themeMain, Color.themeAccent], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
                .shadow(color: Color.themeMainHover.opacity(0.3), radius: 16, x: 0, y: 10)

                Text(encouragementMessage)
                    .font(.footnote)
                    .foregroundColor(.themeTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.vertical, 20)
        .navigationBarBackButtonHidden(true)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [Color.themeBase, Color.themeMain.opacity(0.08)], startPoint: .top, endPoint: .bottom)
        )
    }

    private var resultMessage: String {
        let rate = Double(correctCount) / Double(totalCount)
        switch rate {
        case 1.0:
            return "完璧です！"
        case 0.7...:
            return "よくできました！"
        case 0.4...:
            return "あと少し！"
        default:
            return "もう一度チャレンジ！"
        }
    }
    
    private var encouragementMessage: String {
        let rate = accuracy
        switch rate {
        case 1.0:
            return "次のチャレンジもこの調子で頑張りましょう！"
        case 0.7...:
            return "あと少しで満点です。復習してさらにレベルアップ！"
        case 0.4...:
            return "苦手な部分を振り返って、次回の正解率アップを目指しましょう。"
        default:
            return "焦らずに、解説を見ながら理解を深めていきましょう。"
        }
    }

    private var accuracy: Double {
        guard totalCount > 0 else { return 0 }
        return Double(correctCount) / Double(totalCount)
    }

    private var accuracyPercentage: Int {
        Int((accuracy * 100).rounded())
    }

    private var resultIconName: String {
        let rate = accuracy
        switch rate {
        case 1.0:
            return "crown.fill"
        case 0.7...:
            return "star.fill"
        case 0.4...:
            return "flame.fill"
        default:
            return "leaf.fill"
        }
    }
}
