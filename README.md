# Fenetta

iPad 専用の UVC (USB) カメラビューア。USB 接続したカメラの映像を全画面表示し、ピンチでズームできる。

## 必要なもの

- Xcode 16 以上
- [xcodegen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- iOS 17 以上の iPad (USB-C で UVC カメラを接続)

## ビルド

```shell
xcodegen generate
open Fenetta.xcodeproj
```

Xcode で実機を選んで Run する。コマンドラインからの手順は `AGENTS.md` と `.j-menu.yaml` を参照。
