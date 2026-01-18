# README

主に競技かるたの練習会のお知らせや出欠確認をするアプリケーションです。

## ライセンス

[Polyform Noncommercial License 1.0.0](./LICENSE)

## 開発環境

* PostgreSQLをインストールしておく
* git clone
* bundle install
* rails db:create db:migrate db:seed dev:seed
* rails server
* http://localhost:3000/ で動作確認

## 本番運用時に必要なこと

現在のコードは、メール送信に Resend を使う想定となっています。

### 環境変数の設定
- DATABASE_URL - PostgreSQL接続URL
- APP_HOST - アプリのホスト名（メールのURL生成用）
- MAILER_FROM - メール送信元アドレス
- RESEND_API_KEY - Resend APIキー

### セットアップ

* seedについて
  * dev:seed は開発用なので、db:seed だけを実行してください。
* アプリ起動後
  * サークル設定で、サークル名を設定してください。
  * 最初の管理者のメールアドレスやパスワードを変更してください。
