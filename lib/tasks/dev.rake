namespace :dev do
  desc "Load development seed data"
  task seed: :environment do
    # ========================================
    # グローバル設定
    # ========================================
    Setting.first_or_create!(circle_name: "サンプルかるた会")

    # ========================================
    # 管理者太郎（admin1@example.com）
    # 管理者、A級、東京かるた会
    # ========================================
    admin1_member = Member.joins(:user).merge(User.where(email_address: "admin1@example.com")).first || Member.create!(
      email_address: "admin1@example.com",
      password: "circlendar",
      role: :admin,
      receives_announcements: true,
      confirmed_at: Time.current,
      name: "管理者太郎",
      organization_name: "東京かるた会",
      rank: :a
    )

    # ========================================
    # 管理者花子（admin2@example.com）
    # 管理者、B級、横浜かるた会
    # ========================================
    admin2_member = Member.joins(:user).merge(User.where(email_address: "admin2@example.com")).first || Member.create!(
      email_address: "admin2@example.com",
      password: "circlendar",
      role: :admin,
      receives_announcements: true,
      confirmed_at: Time.current,
      name: "管理者花子",
      organization_name: "横浜かるた会",
      rank: :b
    )

    # ========================================
    # 山田次郎（member1@example.com）
    # メンバー、C級、川崎かるた会
    # ========================================
    player1 = Member.joins(:user).merge(User.where(email_address: "member1@example.com")).first || Member.create!(
      email_address: "member1@example.com",
      password: "circlendar",
      role: :member,
      receives_announcements: true,
      confirmed_at: Time.current,
      name: "山田次郎",
      organization_name: "川崎かるた会",
      rank: :c
    )

    # ========================================
    # 佐藤三郎（member2@example.com）
    # メンバー、D級、千葉かるた会、お知らせ受信OFF
    # ========================================
    player2 = Member.joins(:user).merge(User.where(email_address: "member2@example.com")).first || Member.create!(
      email_address: "member2@example.com",
      password: "circlendar",
      role: :member,
      receives_announcements: false,
      confirmed_at: Time.current,
      name: "佐藤三郎",
      organization_name: "千葉かるた会",
      rank: :d
    )

    # ========================================
    # 施設マスタ
    # ========================================
    venue1 = Venue.create!(
      name: "渋谷区民会館 3階和室",
      url: "https://example.com/shibuya",
      short_name: "渋谷区民会館",
      announcement_summary: "渋谷区民会館 3階和室（JR渋谷駅より徒歩5分）",
      announcement_detail: <<~TEXT.strip
        ☆渋谷区民会館 3階和室
        JR渋谷駅ハチ公口より徒歩5分。
        宇田川町方面へ進み、交番を右折してください。
      TEXT
    )

    venue2 = Venue.create!(
      name: "品川区スポーツセンター 体育室A",
      url: "https://example.com/shinagawa",
      short_name: "品川区スポーツセンター",
      announcement_summary: "品川区スポーツセンター 体育室A（東急大井町線戸越公園駅より徒歩3分）",
      announcement_detail: <<~TEXT.strip
        ☆品川区スポーツセンター 体育室A
        東急大井町線戸越公園駅より徒歩3分。
        改札を出て左へ進み、商店街を抜けた先です。
      TEXT
    )

    venue3 = Venue.create!(
      name: "新宿文化センター 303号室",
      url: "https://example.com/shinjuku",
      short_name: "新宿文化センター",
      announcement_summary: "新宿文化センター 303号室（東京メトロ副都心線東新宿駅直結）",
      announcement_detail: <<~TEXT.strip
        ☆新宿文化センター 303号室
        東京メトロ副都心線東新宿駅A3出口直結。
        エレベーターで3階へお越しください。
      TEXT
    )

    # ========================================
    # お知らせテンプレート
    # ========================================
    AnnouncementTemplate.create!(
      subject: "【練習会のお知らせ】{{練習会ヘッドライン}}",
      body: <<~BODY,
        お疲れ様です。

        下記の日程で練習会を開催します。
        参加される方は、アプリより参加登録をお願いします。

        {{練習会サマリー}}

        {{会場案内}}

        よろしくお願いします。
      BODY
      default: true
    )

    # ========================================
    # イベント1：2週間後の渋谷区民会館（公開済み）
    # ========================================
    event1 = Event.create!(
      venue: venue1,
      date: 2.weeks.from_now.to_date,
      schedule: "１２：３０すぎ－１８：００前　ゆるゆると３試合",
      status: :published
    )

    Attendance.create!(event: event1, player: admin1_member, status: :attending, arrival_time: "13:00", after_party: :attending)
    Attendance.create!(event: event1, player: admin2_member, status: :attending, arrival_time: "13:00", after_party: :attending)
    Attendance.create!(event: event1, player: player1, status: :attending, arrival_time: "13:30", departure_time: "16:00", after_party: :not_attending, message: "2本目から参加予定です")
    Attendance.create!(event: event1, player: player2, status: :undecided, message: "仕事の都合で未定です")

    # ========================================
    # イベント2：1ヶ月後の品川区スポーツセンター（下書き）
    # ========================================
    Event.create!(
      venue: venue2,
      date: 1.month.from_now.to_date,
      schedule: "１２：３０すぎ－１８：００前　ゆるゆると３試合",
      status: :draft
    )

    # ========================================
    # イベント3：1週間前の新宿文化センター（公開済み・過去）
    # ========================================
    event3 = Event.create!(
      venue: venue3,
      date: 1.week.ago.to_date,
      schedule: "１３：００ー１８：００　２本か３本",
      status: :published
    )

    Attendance.create!(event: event3, player: admin1_member, status: :attending, arrival_time: "14:00", after_party: :not_attending)
    Attendance.create!(event: event3, player: player1, status: :attending, arrival_time: "15:00", after_party: :not_attending)

    # ========================================
    # イベント4：3週間後の新宿文化センター（公開済み・未回答）
    # ========================================
    event4 = Event.create!(
      venue: venue3,
      date: 3.weeks.from_now.to_date,
      schedule: "１３：００ー１８：００　２本か３本",
      status: :published
    )

    Attendance.create!(event: event4, player: admin2_member, status: :attending, arrival_time: "13:00", after_party: :not_attending)
    Attendance.create!(event: event4, player: player1, status: :not_attending, message: "用事があり参加できません")

    puts "Development seed data created successfully!"
    puts "Users: admin1@example.com, admin2@example.com, member1@example.com, member2@example.com"
    puts "Password: circlendar"
  end
end
