# Fenetta

iPad 専用の UVC (USB) カメラビューア。SwiftUI + AVFoundation。iOS 17 以上、iPad のみ (`TARGETED_DEVICE_FAMILY = 2`)。

## 操作

映像は常時全画面。UI はジェスチャで出す。

- シングルタップ: コントロール (カメラ選択・90 度回転・Fit/Fill) の表示トグル
- ダブルタップ: contain / cover 切り替え
- ピンチ: 1〜5 倍ズーム。ズーム中は 2 本指ドラッグでパン

ジェスチャは `GestureOverlay` (UIKit) に集約している。SwiftUI の DragGesture は指の本数を区別できない。
表示状態は `ViewerState` が持つ。パン上限の計算 (fit / 回転 / viewport 依存) を変えたら、
`swiftc -parse-as-library Fenetta/ViewerState.swift <ハーネス>` で macOS 向けにコンパイルして数値検証できる。

## プロジェクト構成

- `Fenetta.xcodeproj` は `project.yml` から `xcodegen generate` で生成する。pbxproj を直接編集しない。
  Xcode の GUI でビルド設定を変えても次の再生成で消えるので、設定は `project.yml` に書く。
- ソースは `Fenetta/*.swift`。ファイルを追加したら `xcodegen generate` を実行する。
- `Fenetta/Info.plist` は手書き (`GENERATE_INFOPLIST_FILE = NO`)。CFBundleIdentifier 等の標準キーは
  ビルド設定変数で書いてある。消すと devicectl が "not a valid bundle" でインストールを拒否する。
- ビルド成果物は `~build/` (gitignore 済み)。

## ビルド・実機インストール

`.jj-menu.yaml` に手順をまとめてある (`jj-menu` で選択実行)。手で打つ場合:

```shell
xcodegen generate
xcodebuild -project Fenetta.xcodeproj -scheme Fenetta \
  -destination 'generic/platform=iOS' -configuration Debug \
  -derivedDataPath '~build' -allowProvisioningUpdates build
xcrun devicectl list devices
xcrun devicectl device install app --device <UDID> '~build/Build/Products/Debug-iphoneos/Fenetta.app'
xcrun devicectl device process launch --device <UDID> com.ytyng.Fenetta
```

- 署名は Cyberneura K.K. (`DEVELOPMENT_TEAM = 2YN5TLNQ9J`) の Automatic。個人チーム GHB7FBR8UY は
  Xcode の Apple ID ログインが reject されるため使えない。
- 開発用 iPad は "Bartolome" (iPad mini A17 Pro)。devicectl で `unavailable` なら未接続。
- Claude Code の sandbox 内では xcodebuild / devicectl が動かない (xcrun キャッシュと CoreDevice XPC が
  ブロックされる)。`/sandbox` で解除して実行する。

## テスト

ユニットテストは無い。動作確認は実機に USB カメラを接続して行う。
