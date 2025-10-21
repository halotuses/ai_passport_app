platform :ios, '15.0'

use_frameworks!
use_modular_headers!

target 'ai-passport-app' do
  # RealmSwift の安定バージョン指定
  pod 'RealmSwift', '~> 10.47.0'

  # iOS17以降でのビルド高速化・安定化オプション
  post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        # Module stability 確保（Swift/Realm周りのビルドエラー対策）
        config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'YES'
        # 新しいアーキテクチャ対応（Apple Silicon対策）
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      end
    end
  end

  target 'ai-passport-appTests' do
    inherit! :search_paths
  end

  target 'ai-passport-appUITests' do
  end
end
