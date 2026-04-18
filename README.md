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

### 送信キューの定期処理（Fly.io 前提）

Resend の日次上限等で送信できなかった `AnnouncementDelivery` を時間おきに再試行するため、Fly.io の Scheduled Machines で `AnnouncementDelivery.process_queue!` を定期実行します。

初回セットアップ（`<app>` は `fly.toml` の `app` 値、`<image>` は `fly releases --app <app>` で取得できる現在のイメージ）:

```
fly machine run <image> \
  --app <app> \
  --region nrt \
  --schedule hourly \
  -- bin/rails runner 'AnnouncementDelivery.process_queue!'
```

デプロイで新イメージになったら Scheduled Machine も追従させる:

```
fly machine update <machine-id> --image <new-image> --app <app>
```
