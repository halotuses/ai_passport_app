import SwiftUI

struct CreatePageView<Content: View>: View {
    private let title: String
    private let description: String
    private let isNextButtonDisabled: Bool
    private let nextButtonTitle: String
    private let nextButtonAction: () -> Void
    private let content: Content

    init<ViewModel: ObservableObject>(
        title: String,
        description: String,
        viewModel: ViewModel,
        isNextButtonDisabled: Bool,
        nextButtonTitle: String = "次へ",
        @ViewBuilder content: () -> Content,
        nextButtonAction: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.isNextButtonDisabled = isNextButtonDisabled
        self.nextButtonTitle = nextButtonTitle
        self.content = content()
        self.nextButtonAction = nextButtonAction
        _ = viewModel
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 32) {
                header
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 0)
                primaryButton
            }
            .padding(.vertical, 32)
            .padding(.horizontal, 20)
        }
        .background(
            Color.themeSurface
                .ignoresSafeArea()
        )
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.themeTextPrimary)
                .multilineTextAlignment(.leading)

            if !description.isEmpty {
                Text(description)
                    .font(.body)
                    .foregroundColor(.themeTextSecondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }

    private var primaryButton: some View {
        Button(action: {
            nextButtonAction()
        }) {
            Text(nextButtonTitle)
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.themeMain)
                )
        }
        .buttonStyle(.plain)
        .disabled(isNextButtonDisabled)
        .opacity(isNextButtonDisabled ? 0.5 : 1.0)
    }
}
