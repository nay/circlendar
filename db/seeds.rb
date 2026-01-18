# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# ========================================
# グローバル設定
# ========================================
Setting.find_or_create_by!(id: 1) do |setting|
  setting.circle_name = 'サンプルかるた会'
end

# ========================================
# 管理者太郎（admin1@example.com）
# 管理者、A級、東京かるた会
# ========================================
admin1_user = User.find_or_create_by!(email_address: 'admin1@example.com') do |user|
  user.password = 'password'
  user.role = :admin
  user.receives_announcements = true
end

admin1_member = Member.find_or_create_by!(user: admin1_user) do |member|
  member.name = '管理者太郎'
  member.organization_name = '東京かるた会'
  member.rank = :a
end

# ========================================
# 管理者花子（admin2@example.com）
# 管理者、B級、横浜かるた会
# ========================================
admin2_user = User.find_or_create_by!(email_address: 'admin2@example.com') do |user|
  user.password = 'password'
  user.role = :admin
  user.receives_announcements = true
end

admin2_member = Member.find_or_create_by!(user: admin2_user) do |member|
  member.name = '管理者花子'
  member.organization_name = '横浜かるた会'
  member.rank = :b
end

# ========================================
# 山田次郎（member1@example.com）
# メンバー、C級、川崎かるた会
# ========================================
member1_user = User.find_or_create_by!(email_address: 'member1@example.com') do |user|
  user.password = 'password'
  user.role = :member
  user.receives_announcements = true
end

player1 = Member.find_or_create_by!(user: member1_user) do |member|
  member.name = '山田次郎'
  member.organization_name = '川崎かるた会'
  member.rank = :c
end

# ========================================
# 佐藤三郎（member2@example.com）
# メンバー、D級、千葉かるた会、お知らせ受信OFF
# ========================================
member2_user = User.find_or_create_by!(email_address: 'member2@example.com') do |user|
  user.password = 'password'
  user.role = :member
  user.receives_announcements = false
end

player2 = Member.find_or_create_by!(user: member2_user) do |member|
  member.name = '佐藤三郎'
  member.organization_name = '千葉かるた会'
  member.rank = :d
end

# ========================================
# 施設マスタ
# ========================================
venue1 = Venue.find_or_create_by!(name: '渋谷区民会館 3階和室') do |venue|
  venue.url = 'https://example.com/shibuya'
  venue.announcement_summary = '渋谷区民会館 3階和室（JR渋谷駅より徒歩5分）'
  venue.announcement_detail = <<~TEXT.strip
    ☆渋谷区民会館 3階和室
    JR渋谷駅ハチ公口より徒歩5分。
    宇田川町方面へ進み、交番を右折してください。
  TEXT
end

venue2 = Venue.find_or_create_by!(name: '品川区スポーツセンター 体育室A') do |venue|
  venue.url = 'https://example.com/shinagawa'
  venue.announcement_summary = '品川区スポーツセンター 体育室A（東急大井町線戸越公園駅より徒歩3分）'
  venue.announcement_detail = <<~TEXT.strip
    ☆品川区スポーツセンター 体育室A
    東急大井町線戸越公園駅より徒歩3分。
    改札を出て左へ進み、商店街を抜けた先です。
  TEXT
end

venue3 = Venue.find_or_create_by!(name: '新宿文化センター 303号室') do |venue|
  venue.url = 'https://example.com/shinjuku'
  venue.announcement_summary = '新宿文化センター 303号室（東京メトロ副都心線東新宿駅直結）'
  venue.announcement_detail = <<~TEXT.strip
    ☆新宿文化センター 303号室
    東京メトロ副都心線東新宿駅A3出口直結。
    エレベーターで3階へお越しください。
  TEXT
end

# ========================================
# お知らせテンプレート
# ========================================
AnnouncementTemplate.find_or_create_by!(subject: '【練習会のお知らせ】{{日付}} {{会場名}}') do |template|
  template.body = <<~BODY
    お疲れ様です。

    下記の日程で練習会を開催します。
    参加される方は、アプリより参加登録をお願いします。

    ■ 日時
    {{日付}} {{開始時刻}}〜{{終了時刻}}

    ■ 場所
    {{会場名}}
    {{会場URL}}

    よろしくお願いします。
  BODY
  template.default = true
end

# ========================================
# イベント1：2週間後の渋谷区民会館（公開済み）
# ========================================
event1 = Event.find_or_create_by!(
  venue: venue1,
  date: 2.weeks.from_now.to_date
) do |event|
  event.start_time = '13:00'
  event.end_time = '17:00'
  event.notes = '初心者の方も歓迎します'
  event.status = :published
end

# イベント1の参加状況
# 管理者太郎：参加、13:00から、アフターあり
Attendance.find_or_create_by!(event: event1, player: admin1_member) do |attendance|
  attendance.status = :attending
  attendance.arrival_time = '13:00'
  attendance.after_party = true
  attendance.message = ''
end

# 管理者花子：参加、13:00から、アフターあり
Attendance.find_or_create_by!(event: event1, player: admin2_member) do |attendance|
  attendance.status = :attending
  attendance.arrival_time = '13:00'
  attendance.after_party = true
  attendance.message = ''
end

# 山田次郎：参加、13:30から16:00まで、アフターなし、2本目から
Attendance.find_or_create_by!(event: event1, player: player1) do |attendance|
  attendance.status = :attending
  attendance.arrival_time = '13:30'
  attendance.departure_time = '16:00'
  attendance.after_party = false
  attendance.message = '2本目から参加予定です'
end

# 佐藤三郎：未定、仕事の都合
Attendance.find_or_create_by!(event: event1, player: player2) do |attendance|
  attendance.status = :undecided
  attendance.message = '仕事の都合で未定です'
end

# ========================================
# イベント2：1ヶ月後の品川区スポーツセンター（下書き）
# ========================================
event2 = Event.find_or_create_by!(
  venue: venue2,
  date: 1.month.from_now.to_date
) do |event|
  event.start_time = '10:00'
  event.end_time = '16:00'
  event.notes = '昼食は各自ご持参ください'
  event.status = :draft
end

# ========================================
# イベント3：1週間前の新宿文化センター（公開済み・過去）
# ========================================
event3 = Event.find_or_create_by!(
  venue: venue3,
  date: 1.week.ago.to_date
) do |event|
  event.start_time = '14:00'
  event.end_time = '17:00'
  event.notes = '2本目 15:20〜

可能な方は札を持ってきてください！'
  event.status = :published
end

# イベント3の参加状況
Attendance.find_or_create_by!(event: event3, player: admin1_member) do |attendance|
  attendance.status = :attending
  attendance.arrival_time = '14:00'
  attendance.after_party = false
end

Attendance.find_or_create_by!(event: event3, player: player1) do |attendance|
  attendance.status = :attending
  attendance.arrival_time = '15:00'
  attendance.after_party = false
end

# ========================================
# イベント4：3週間後の新宿文化センター（公開済み・未回答）
# ========================================
event4 = Event.find_or_create_by!(
  venue: venue3,
  date: 3.weeks.from_now.to_date
) do |event|
  event.start_time = '13:00'
  event.end_time = '17:30'
  event.notes = '級位者向け練習会です'
  event.status = :published
end

# イベント4の参加状況
# 管理者花子：参加
Attendance.find_or_create_by!(event: event4, player: admin2_member) do |attendance|
  attendance.status = :attending
  attendance.arrival_time = '13:00'
  attendance.after_party = false
end

# 山田次郎：欠席
Attendance.find_or_create_by!(event: event4, player: player1) do |attendance|
  attendance.status = :not_attending
  attendance.message = '用事があり参加できません'
end

# 管理者太郎：未回答（レコードなし）
# 佐藤三郎：未回答（レコードなし）

puts "Seed data created successfully!"
puts "Users: admin1@example.com, admin2@example.com, member1@example.com, member2@example.com"
puts "Password: password"
