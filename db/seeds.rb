# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# For development sample data, use: bin/rails dev:seed

# ========================================
# グローバル設定
# ========================================
setting = Setting.first_or_create!(circle_name: 'サンプルかるた会')
if setting.signup_token.blank?
  setting.generate_signup_token!
  puts "Signup token generated: #{setting.signup_token}"
end

# ========================================
# 最初の管理者（管理者が一人もいない場合のみ作成）
# ========================================
if User.where(role: :admin).none?
  user = User.new(
    email_address: 'admin@example.com',
    password: 'circlendar',
    role: :admin,
    receives_announcements: true
  )
  user.build_member(name: '管理者')
  user.confirm_new_mail_addresses
  user.save!

  puts "Admin user created: admin@example.com / circlendar"
end

puts "Seed completed!"
