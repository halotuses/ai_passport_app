import SwiftUI

struct TermsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("この利用規約は、AI Passport アプリのご利用にあたり適用される条件を定めています。アプリを使用することで、本規約に同意したものとみなされます。")
                Text("アプリの提供内容は予告なく変更される場合があります。変更があった際には最新の情報をアプリ内でお知らせいたしますので、定期的にご確認ください。")
                Text("利用者による不正なアクセスや著作権等の侵害行為が確認された場合、当社は必要な措置を講じることがあります。また、アプリの利用に関連して生じたトラブルについては、利用者自身の責任において解決するものとします。")
                Text("その他詳細な条件については、正式リリース時に提供予定の公式ドキュメントをご確認ください。")
            }
            .font(.body)
            .foregroundColor(.themeTextPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Color.themeBase.ignoresSafeArea())
        .navigationTitle("利用規約")
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("本プライバシーポリシーは、AI Passport アプリにおける個人情報の取り扱い方針を定めたものです。当社は、利用目的の達成に必要な範囲で個人情報を取得し、適切に管理します。")
                Text("収集した個人情報は、サービスの提供・改善、ユーザーサポート、重要なお知らせの配信などに利用されます。これらの利用目的以外で第三者に提供することはありません。")
                Text("利用者は、当社が保有する自身の個人情報の開示、訂正、削除を求めることができます。ご要望がある場合は、お問い合わせ窓口までご連絡ください。")
                Text("プライバシーポリシーの内容は予告なく改訂される場合があります。最新の内容は正式リリース時に公開予定の公式ページでご確認いただけます。")
            }
            .font(.body)
            .foregroundColor(.themeTextPrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Color.themeBase.ignoresSafeArea())
        .navigationTitle("プライバシーポリシー")
    }
}

struct TermsPrivacyViews_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TermsView()
        }
        NavigationStack {
            PrivacyPolicyView()
        }
    }
}
