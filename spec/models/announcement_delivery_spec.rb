require "rails_helper"

RSpec.describe AnnouncementDelivery, type: :model do
  let(:announcement) do
    Announcement.create!(subject: "テスト", body: "本文", to_address: "admin@example.com", bcc_addresses: [ "a@example.com" ])
  end

  def create_delivery(addresses:, **attrs)
    AnnouncementDelivery.create!(announcement: announcement, addresses: addresses, **attrs)
  end

  describe ".process_queue!" do
    it "processable なレコードを id 昇順で処理する" do
      d1 = create_delivery(addresses: [ "a@example.com" ])
      d2 = create_delivery(addresses: [ "b@example.com" ])

      AnnouncementDelivery.process_queue!

      expect(d1.reload.status).to eq("requested")
      expect(d2.reload.status).to eq("requested")
    end

    it "next_run_at が未来のレコードはスキップする" do
      d = create_delivery(addresses: [ "a@example.com" ], next_run_at: 1.hour.from_now)

      AnnouncementDelivery.process_queue!

      expect(d.reload.status).to eq("pending")
    end

    it "next_run_at が過去のレコードは処理する" do
      d = create_delivery(addresses: [ "a@example.com" ], next_run_at: 1.hour.ago)

      AnnouncementDelivery.process_queue!

      expect(d.reload.status).to eq("requested")
    end
  end

  describe "#process!" do
    context "BATCH_SIZE 以下の場合" do
      it "全件送信して requested になる" do
        d = create_delivery(addresses: [ "a@example.com", "b@example.com" ])

        d.process!

        expect(d.reload.status).to eq("requested")
        expect(d.resend_ids.size).to eq(2)
        expect(d.resend_ids).to all(start_with("fake_"))
        expect(d.requested_at).to be_present
      end
    end

    context "BATCH_SIZE を超える場合" do
      it "最初のバッチを送信し、残りを新レコードに分裂する" do
        addresses = (1..15).map { |i| "user#{i}@example.com" }
        d = create_delivery(addresses: addresses)

        d.process!

        d.reload
        expect(d.status).to eq("requested")
        expect(d.addresses.size).to eq(10)
        expect(d.resend_ids.size).to eq(10)

        remaining = AnnouncementDelivery.where(announcement: announcement).pending.first
        expect(remaining.addresses.size).to eq(5)
        expect(remaining.next_run_at).to be_nil
      end
    end

    context "過去24時間の送信数がクォータしきい値以上の場合" do
      it "送信せず next_run_at を設定する" do
        # 過去の送信済みレコードを作成（70件分）
        create_delivery(
          addresses: (1..70).map { |i| "sent#{i}@example.com" },
          status: :requested,
          requested_at: 1.hour.ago,
          resend_ids: (1..70).map { |i| "id_#{i}" }
        )

        d = create_delivery(addresses: [ "new@example.com" ])
        d.process!

        d.reload
        expect(d.status).to eq("pending")
        expect(d.next_run_at).to be_present
      end
    end

    context "429 レートリミットの場合" do
      it "next_run_at を設定して中断する" do
        d = create_delivery(addresses: [ "a@example.com" ])
        allow(AnnouncementDelivery.client).to receive(:send_batch)
          .and_raise(Resend::Error::RateLimitExceededError.new("rate limited", 429))

        d.process!

        d.reload
        expect(d.status).to eq("pending")
        expect(d.next_run_at).to be_present
      end
    end

    context "バッチ送信がエラーの場合" do
      it "個別送信にフォールバックし、失敗アドレスを記録する" do
        d = create_delivery(addresses: [ "good@example.com", "bad@example.com" ])

        # バッチは失敗
        call_count = 0
        allow(AnnouncementDelivery.client).to receive(:send_batch) do |params|
          call_count += 1
          if call_count == 1
            raise Resend::Error::InvalidRequestError.new("validation error", 422)
          elsif params.first[:to] == [ "bad@example.com" ]
            raise Resend::Error::InvalidRequestError.new("invalid email", 422)
          else
            { data: [ { id: "fake_ok" } ], headers: { "x-resend-daily-quota" => "1" } }
          end
        end

        d.process!

        d.reload
        expect(d.status).to eq("requested")
        expect(d.addresses).to eq([ "good@example.com" ])
        expect(d.failed_addresses).to eq([ "bad@example.com" ])
        expect(d.resend_ids).to eq([ "fake_ok" ])
      end
    end

    context "個別送信中に429が発生した場合" do
      it "送信済み分を保存し、未送信分を新レコードに退避する" do
        d = create_delivery(addresses: [ "a@example.com", "b@example.com", "c@example.com" ])

        call_count = 0
        allow(AnnouncementDelivery.client).to receive(:send_batch) do |params|
          call_count += 1
          if call_count == 1
            raise Resend::Error::InvalidRequestError.new("error", 422)
          elsif call_count == 2
            # a@example.com 成功
            { data: [ { id: "fake_a" } ], headers: { "x-resend-daily-quota" => "1" } }
          else
            # b@example.com で429
            raise Resend::Error::RateLimitExceededError.new("rate limited", 429)
          end
        end

        d.process!

        d.reload
        expect(d.status).to eq("requested")
        expect(d.addresses).to eq([ "a@example.com" ])
        expect(d.resend_ids).to eq([ "fake_a" ])

        remaining = AnnouncementDelivery.where(announcement: announcement).pending.first
        expect(remaining.addresses).to eq([ "b@example.com", "c@example.com" ])
        expect(remaining.next_run_at).to be_present
      end
    end

    context "全アドレスが失敗した場合" do
      it "status が failed になる" do
        d = create_delivery(addresses: [ "bad@example.com" ])

        call_count = 0
        allow(AnnouncementDelivery.client).to receive(:send_batch) do
          call_count += 1
          raise Resend::Error::InvalidRequestError.new("invalid", 422)
        end

        d.process!

        d.reload
        expect(d.status).to eq("failed")
        expect(d.failed_addresses).to eq([ "bad@example.com" ])
      end
    end

    context "failed_addresses があるレコードの再処理" do
      it "failed_addresses を除外して残りを送信する" do
        d = create_delivery(
          addresses: [ "bad@example.com", "good@example.com", "good2@example.com" ],
          failed_addresses: [ "bad@example.com" ]
        )

        d.process!

        d.reload
        expect(d.status).to eq("requested")
        expect(d.addresses).to eq([ "good@example.com", "good2@example.com" ])
        expect(d.resend_ids.size).to eq(2)
      end
    end
  end

  describe ".recent_sent_count" do
    it "過去24時間の送信成功数を返す" do
      create_delivery(
        addresses: [ "a@example.com", "b@example.com" ],
        failed_addresses: [ "c@example.com" ],
        status: :requested,
        requested_at: 1.hour.ago,
        resend_ids: [ "id1", "id2" ]
      )

      expect(AnnouncementDelivery.recent_sent_count).to eq(1)
    end

    it "24時間以上前のレコードは含まない" do
      create_delivery(
        addresses: [ "a@example.com" ],
        status: :requested,
        requested_at: 25.hours.ago,
        resend_ids: [ "id1" ]
      )

      expect(AnnouncementDelivery.recent_sent_count).to eq(0)
    end
  end
end
