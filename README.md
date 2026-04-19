# 課題トラッカー — iOS PWA デプロイ手順

講義ごとの課題管理 PWA。App Store 配信を Mac 不要で行うためのセットアップ手順。

---

## フォルダ構成

```
kadai-tracker/
├── index.html              # アプリ本体
├── manifest.webmanifest    # PWA マニフェスト
├── sw.js                   # Service Worker (オフライン対応)
├── generate-icons.html     # アイコン PNG 生成ツール (ローカルで1回実行)
├── .nojekyll               # GitHub Pages 用
├── README.md               # このファイル
└── icons/
    ├── icon.svg            # ソースアイコン
    ├── icon-192.png        # ↓ generate-icons.html で生成
    ├── icon-512.png
    ├── icon-maskable-512.png
    └── apple-touch-icon.png
```

---

## STEP 0: アイコン PNG を生成

1. `generate-icons.html` をブラウザでダブルクリックで開く
2. **「💾 全て保存」** をクリック → 4つの PNG がダウンロードされる
   - ブラウザの「複数ファイルダウンロード許可」を押す
3. ダウンロードした 4ファイルを `icons/` フォルダに移動

これで必須ファイルが揃います。

---

## STEP 1: GitHub Pages で公開 (無料)

### 1-1. GitHub リポジトリ作成

1. https://github.com で新規リポジトリを作成（例: `kadai-tracker`、Public）
2. 作成後、「uploading an existing file」リンクからこのフォルダ内の全ファイルをアップロード
   - `.nojekyll` も忘れずに（隠しファイル表示を有効に）

### 1-2. GitHub Pages 有効化

1. リポジトリの **Settings** → **Pages**
2. Source: `Deploy from a branch` / Branch: `main` / Folder: `/ (root)` → Save
3. 1〜2分待つと `https://<username>.github.io/kadai-tracker/` で公開される

### 1-3. iPhone で動作確認

1. iPhone Safari で公開 URL を開く
2. 共有ボタン → **「ホーム画面に追加」**
3. ホーム画面にアイコンが並ぶ → タップで全画面アプリとして起動

ここまでで **個人利用なら完了**。以下は App Store 配信用。

---

## STEP 2: App Store 配信 (PWABuilder 経由)

Mac 不要ルート。Apple Developer Program (年 $99) への加入が必要。

### 2-1. Apple Developer Program 登録

1. https://developer.apple.com/programs/ にアクセス
2. Apple ID でサインイン → Enroll
3. **個人 (Individual)** を選択、年 $99 支払い
4. 承認に 24〜48 時間

### 2-2. PWABuilder で iOS パッケージ生成

1. https://www.pwabuilder.com/ にアクセス
2. STEP 1-2 で公開した URL を入力
3. スコアが表示される → 各項目の警告を確認（概ね問題ないはず）
4. **Package For Stores** → **iOS** → Generate Package
5. Bundle ID (例: `com.あなたのドメイン.kadaitracker`) を入力
6. ZIP ファイルをダウンロード（Xcode プロジェクトが入っている）

### 2-3. Xcode ビルド (Mac 不要ルート)

Mac 無しでビルドするには以下のいずれか:

**A) Codemagic (推奨・初回無料)**
1. https://codemagic.io にサインアップ
2. GitHub に PWABuilder が生成したプロジェクトをアップロード
3. Codemagic で iOS workflow を作成、自動ビルド
4. App Store Connect API キー (STEP 2-4 で取得) を登録
5. ビルド成果物が App Store Connect へ自動アップロード

**B) GitHub Actions (無料枠内)**
- macOS runner + fastlane でビルド & アップロード
- テンプレ: PWABuilder 公式が GitHub Actions ワークフローも提供

### 2-4. App Store Connect で申請

1. https://appstoreconnect.apple.com/ にサインイン
2. 新規 App 作成 → Bundle ID を STEP 2-2 と揃える
3. アプリ名、説明、スクリーンショット (iPhone 6.7"/6.5"/5.5" それぞれ必要)、アイコン、プライバシーポリシー URL を登録
4. ビルドが上がるのを待つ → 提出 → Apple 審査 (通常 1〜3 日)

---

## ローカルでサーバー経由で試す (PC で動作確認)

Service Worker は `file://` では動かないため、簡易サーバーが必要:

```bash
# Python
cd kadai-tracker
python -m http.server 8000
# → http://localhost:8000/ を開く
```

または `npx serve` / VS Code Live Server 拡張など。

---

## トラブルシューティング

**Q: iPhone でホーム画面に追加してもアイコンがぼやける**
→ `icons/apple-touch-icon.png` が配置されているか、GitHub Pages で 404 になっていないか確認

**Q: PWABuilder のスコアが低い**
→ HTTPS で公開されているか、manifest.webmanifest の全フィールドが埋まっているか確認

**Q: App Store 審査で reject**
→ 単純な PWA ラッパーは近年審査が厳しい傾向。ネイティブ機能の活用 (プッシュ通知、ウィジェット、Sign in with Apple など) を足すと通りやすい
