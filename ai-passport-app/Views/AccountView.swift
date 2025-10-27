import SwiftUI

struct AccountView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 64))
                .foregroundColor(.themeMain)
            Text("アカウント機能は近日公開予定です。")
                .font(.body)
                .foregroundColor(.themeTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.themeBase.ignoresSafeArea())
        .navigationTitle("アカウント")
    }
}

struct AccountView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AccountView()
        }
    }
}
