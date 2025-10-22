# iOS 15以上をサポート
platform :ios, '15.0'

use_frameworks!
use_modular_headers!

target 'ai-passport-app' do
  # RealmSwift の最新版（v10.54系）を使用
  pod 'RealmSwift', '~> 10.54'

  # iOS17 / Xcode16 系での安定ビルド対応
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        # モジュール安定性（Realm含む Swift ライブラリ対策）
        config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'

        # Apple Silicon (arm64) シミュレータ対応
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'

        # Swift 6ビルド時の警告回避（安全設定）
        config.build_settings['SWIFT_STRICT_CONCURRENCY'] = 'complete'
      end
    end
  end

  target 'ai-passport-appTests' do
    inherit! :search_paths
  end

  target 'ai-passport-appUITests' do
  end
end
