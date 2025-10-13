// Services/Constants.swift
import Foundation

enum Constants {
    /// すべてのコンテンツのベースURL（末尾スラッシュ付き）
    static let BASE_URL = "https://ai-passport-app.s3.ap-northeast-3.amazonaws.com/"

    /// 相対パス（例: "path/to/file.json"）からフルURL文字列を生成
    /// すでに "http" で始まる場合はそのまま返す
    static func url(_ path: String) -> String {
        guard !path.lowercased().hasPrefix("http") else { return path }
        if BASE_URL.hasSuffix("/") {
            return BASE_URL + path
        } else {
            return BASE_URL + "/" + path
        }
    }
}
