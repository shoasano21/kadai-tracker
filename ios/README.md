# kadai-tracker-ios

課題トラッカー iOS アプリ版（PWA ラッパー）。Mac 不要で Codemagic 経由 App Store へリリースするための Xcode プロジェクト。

- **本体（Web/PWA）**: https://github.com/shoasano21/kadai-tracker
- **ライブ URL**: https://shoasano21.github.io/kadai-tracker/
- **Bundle ID**: `com.shoasano21.kadaitracker`

## 変更履歴（PWABuilder 出力からのカスタマイズ）

- Firebase Cloud Messaging を完全除去（サーバプッシュ不使用）
- Microphone / Camera / Location 権限要求を削除
- Background Mode から `remote-notification` を削除
- `gcmMessageIDKey` を削除、`rootUrl` に trailing slash 追加
- GoogleService-Info.plist の中身を空化（Firebase SDK 撤去後の参照漏れ防止）

## ビルドフロー（Codemagic）

1. Apple Developer Program 承認を確認
2. App Store Connect で新規 App レコードを作成（Bundle ID: `com.shoasano21.kadaitracker`）
3. App Store Connect で API キーを発行 → Codemagic の Integrations に登録
4. Codemagic で本リポジトリを接続
5. `codemagic.yaml` 内の `APP_STORE_APPLE_ID` を、App Store Connect の App ID（数字）に置換
6. `main` ブランチへ push → 自動で TestFlight までビルド & 配信

## ローカル確認（Mac 環境）

```bash
cd src
pod install
open 課題トラッカー.xcworkspace
```

## Windows での取扱い

本リポジトリは Windows からも編集・Git 操作は可能。ビルドのみ Mac（もしくは Codemagic の macOS ランナー）が必要。
