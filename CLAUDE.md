# Claude Code 向けプロジェクト指示

## 開発ステップと役割分担

- 作業ブランチは私（ユーザー）が用意します。もし、mainブランチにいる場合は用意するよう依頼してください。
- コードを変更したら、テスト、RuboCopを通過させてください。
- あなた（Claude Code）による開発、テスト、RuboCopが終わったら、私（ユーザー）に動作確認をしてもらい、必要に応じて修正を行ってください。
- 私（ユーザー）の動作確認、テスト、RuboCopが終わったら、コミットをしてください。
- リモートレポジトリへの push や PR作成は私（ユーザー）が行います。
- リリースは私（ユーザー）が行います。

## コミットのルール

- 作業は小さなステップに分けて進め、ステップごとにコミットする
- 例：CRUD機能を作るとき
  - 一覧画面を作る → コミット
  - 新規作成を作る → コミット
  - 編集を作る → コミット
  - 削除を作る → コミット
- 動作確認できる単位でコミットする

## PRのルール

- 作業ブランチで最初のコミットをしたら、Draft PRを作成する
- 作業中はDraft状態を維持し、完了したらReady for Reviewにする

## 翻訳（I18n）のルール

- モデル名は `Model.model_name.human` を使って表示する
  - 例: `Event.model_name.human` → "練習会"
  - 翻訳は `config/locales/ja.yml` の `activerecord.models` に定義
- ビューの文言は `t()` ヘルパーを使って翻訳する
  - 翻訳は `config/locales/ja.yml` に定義

## 命名規則

- booleanカラムは `is_xxx` のような接頭辞を使わない
  - 良い例: `default`, `published`, `active`
  - 悪い例: `is_default`, `is_published`, `is_active`
- booleanの値を参照するときは `?` メソッドを使う
  - 例: `template.default?`, `event.published?`
