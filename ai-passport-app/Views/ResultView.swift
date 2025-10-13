// Views/ResultView.swift
import SwiftUI

struct ResultView: View {
    @ObservedObject var viewModel: QuizViewModel
    let onClose: () -> Void

    private var headerMessage: String {
        switch viewModel.accuracy {
        case 90...100: return "素晴らしい！"
        case 70..<90:  return "よくできました！"
        case 50..<70:  return "あと少し！"
        default:       return "ここから伸びる！"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(headerMessage)
                .font(.title2).bold()

            VStack(spacing: 8) {
                Text("正解数：\(viewModel.correctCount) / \(viewModel.totalCount)")
                Text("正答率：\(viewModel.accuracy)%")
            }
            .font(.headline)

            Button(action: onClose) {
                Text("トップに戻る")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor.opacity(0.15))
                    .cornerRadius(12)
            }
            .padding(.top, 8)

            Spacer()
        }
        .padding()
    }
}
