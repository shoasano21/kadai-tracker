# App Store Connect 申請用アセット集

App Store Connect の入力欄に**このファイルからコピペするだけ**で埋められるようにまとめた。

---

## 🆔 Bundle ID

```
com.shoasano21.kadaitracker
```

PWABuilder / Xcode プロジェクトで使う。ドメイン所有者として `github.io` の逆順 + アプリ名にしてある。

---

## 📛 アプリ基本情報

| 項目 | 値 |
|---|---|
| App Name (App Store 表示名) | `課題トラッカー` |
| Subtitle (30文字以内) | `講義別の課題管理をシンプルに` |
| Primary Category | `Productivity` |
| Secondary Category | `Education` |
| Age Rating | `4+` (全年齢) |
| Primary Language | `Japanese` |

---

## 📝 説明文 (Description)

### 日本語（最大 4000 文字）

```
「課題トラッカー」は、大学生のための講義別課題管理ツールです。

■ 特長
・講義ごとに課題をまとめて管理
・ガントチャート / カードの2ビュー切替
・締切までの残日数を色で可視化（緊急/注意/余裕）
・進捗バーで経過日数を直感的に把握
・完了時のちょっと嬉しいアニメーション

■ こんな方におすすめ
・レポート・問題演習・暗記など、種類の違う課題を並行して進める学生
・締切が近い課題を見落としたくない方
・シンプルで動作の軽いツールを探している方

■ プライバシー重視
・データは端末内にのみ保存
・アカウント登録不要
・トラッキング・広告なし
・オフライン動作対応

■ 使い方
1. 「＋ 追加」で課題を登録
2. ガントチャートで全体像を把握
3. 完了したら「✓」ボタンで消し込み

忙しい学生生活を、少しだけ楽に。
```

### 英語（必要なら）

```
"Kadai Tracker" is a course-based assignment manager for students.

Features:
- Organize assignments by course
- Switch between Gantt chart and card views
- Color-coded urgency (urgent / soon / later)
- Progress bars visualize elapsed time
- Satisfying completion animations

Privacy first:
- All data stays on your device
- No account required
- No tracking or ads
- Works offline

A lightweight tool to help you keep track of reports, practice problems, and memorization assignments across all your courses.
```

---

## 🔑 キーワード (100文字以内、カンマ区切り)

### 日本語
```
課題,大学生,医学生,Todo,タスク,締切,レポート,ガント,学習,勉強,予定,管理
```

### 英語
```
assignment,student,todo,deadline,tasks,gantt,study,planner,school
```

---

## 🔗 必須 URL

| 項目 | URL |
|---|---|
| Support URL | `https://github.com/shoasano21/kadai-tracker` |
| Marketing URL (任意) | `https://shoasano21.github.io/kadai-tracker/` |
| Privacy Policy URL | `https://shoasano21.github.io/kadai-tracker/privacy.html` |

---

## 📸 スクリーンショット要件

App Store は**最低 1 デバイスサイズ**が必要。iPhone 用は以下のいずれか:

| デバイス | 解像度 | 推奨枚数 |
|---|---|---|
| iPhone 6.9" (15 Pro Max, 16 Pro Max) | 1320×2868 | 3〜5 |
| iPhone 6.7" (14/15 Plus, 15 Pro Max) | 1290×2796 | 3〜5 |
| iPhone 6.5" (XS Max, 11 Pro Max) | 1284×2778 | 3〜5 |

**取得方法**:
1. iPhone で本アプリ（PWA）を開く
2. 各画面（ガント / カード / 追加モーダル / ダークモード / 緊急表示）のスクショを撮る
3. 画像を App Store Connect にアップロード

持ってる iPhone のサイズを教えてくれれば、どれで撮れば良いか案内します。

---

## 📋 レビュー情報 (App Review Information)

| 項目 | 値 |
|---|---|
| Sign-in required? | **No** (ログイン不要) |
| Demo account | 不要 |
| Contact first name | Sho |
| Contact last name | Asano |
| Contact email | sho.asano.0921@gmail.com |
| Review notes | `This is a local-only assignment tracker for university students. All data is stored in localStorage. No login, no server, no external API calls.` |

---

## ⚠️ 審査対策メモ

Apple は「ただの Web ラッパー」を rejection する傾向がある（Guideline 4.2: Minimum Functionality）。対策:

1. **オフライン動作** ✅ Service Worker 実装済み
2. **ネイティブ感** ✅ ホーム画面アイコン、スプラッシュ、セーフエリア対応済み
3. **プライバシーポリシー** ✅ `privacy.html` 作成済み
4. **追加機能** （reject された場合の予備）:
   - ローカル通知のスケジューリング
   - ウィジェット対応
   - Shortcuts (既に manifest に `shortcuts` 定義済み)
   - Sign in with Apple (不要だが審査で好印象)

それでも reject された場合は、Reviewer への返信で「オフライン完結型の学生向けローカルツール」であることを強調する。

---

## 📅 タイムライン目安

- 今日: Apple Developer 登録（承認待ち 24〜48h）
- Day 2: PWABuilder で iOS パッケージ生成
- Day 2: Codemagic 設定 → 自動ビルド
- Day 3: App Store Connect 入力 + スクショアップ + 提出
- Day 4〜6: Apple 審査
- Day 7: リリース
