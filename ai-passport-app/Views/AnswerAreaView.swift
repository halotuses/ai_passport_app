import SwiftUI

/// 回答選択ボタン部
struct AnswerAreaView: View {

    let choices: [String]
    let selectAction: (Int) -> Void

    var body: some View {
        VStack(spacing: 12) {
            if choices.count > 0 {
                GeometryReader { geometry in
                    let totalWidth = geometry.size.width
                    let spacing: CGFloat = 10
                    let horizontalPadding: CGFloat = 16
                    let availableWidth = totalWidth - horizontalPadding * 2 - spacing * 3
                    let buttonWidth = availableWidth / 4

                    HStack(spacing: spacing) {
                        ForEach(Array(choices.enumerated()), id: \.offset) { index, _ in
                            Button(action: { selectAction(index) }) {
                                Text(label(for: index))
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .frame(width: buttonWidth, height: 50)
                                    .background(Color.themeAccent)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                }
                .frame(height: 70)
            }
        }
        .padding(.bottom, 0)
    }

    private func label(for index: Int) -> String {
        let labels = ["ア", "イ", "ウ", "エ"]
        return index < labels.count ? labels[index] : "？"
    }
}
