# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_12_000350) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "announcement_deliveries", force: :cascade do |t|
    t.text "addresses", default: "[]", null: false
    t.bigint "announcement_id", null: false
    t.datetime "created_at", null: false
    t.text "error_message"
    t.text "failed_addresses", default: "[]", null: false
    t.datetime "next_run_at"
    t.text "note"
    t.datetime "requested_at"
    t.text "resend_ids", default: "[]"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["announcement_id"], name: "index_announcement_deliveries_on_announcement_id"
    t.index ["next_run_at"], name: "index_announcement_deliveries_on_next_run_at"
    t.index ["status"], name: "index_announcement_deliveries_on_status"
  end

  create_table "announcement_delivery_results", force: :cascade do |t|
    t.string "address", null: false
    t.bigint "announcement_delivery_id", null: false
    t.datetime "created_at", null: false
    t.string "event"
    t.string "resend_id", null: false
    t.datetime "updated_at", null: false
    t.index ["announcement_delivery_id"], name: "idx_on_announcement_delivery_id_8951ba860a"
    t.index ["resend_id"], name: "index_announcement_delivery_results_on_resend_id", unique: true
  end

  create_table "announcement_templates", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.boolean "default"
    t.text "subject"
    t.datetime "updated_at", null: false
  end

  create_table "announcements", force: :cascade do |t|
    t.bigint "announcement_template_id"
    t.text "body"
    t.datetime "created_at", null: false
    t.datetime "delivery_finished_at"
    t.datetime "delivery_started_at"
    t.text "recipient_addresses", default: [], array: true
    t.integer "sent_by"
    t.text "subject"
    t.string "to_address"
    t.datetime "updated_at", null: false
    t.index ["announcement_template_id"], name: "index_announcements_on_announcement_template_id"
  end

  create_table "attendances", force: :cascade do |t|
    t.string "after_party", default: "undecided", null: false
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.text "message"
    t.bigint "player_id", null: false
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_attendances_on_event_id"
    t.index ["player_id"], name: "index_attendances_on_player_id"
  end

  create_table "event_announcements", force: :cascade do |t|
    t.bigint "announcement_id", null: false
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.datetime "updated_at", null: false
    t.index ["announcement_id"], name: "index_event_announcements_on_announcement_id"
    t.index ["event_id", "announcement_id"], name: "index_event_announcements_on_event_id_and_announcement_id", unique: true
    t.index ["event_id"], name: "index_event_announcements_on_event_id"
  end

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date"
    t.string "schedule"
    t.string "status", default: "draft", null: false
    t.datetime "updated_at", null: false
    t.bigint "venue_id", null: false
    t.index ["venue_id"], name: "index_events_on_venue_id"
  end

  create_table "players", force: :cascade do |t|
    t.bigint "attendance_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name"
    t.string "organization_name"
    t.string "rank"
    t.string "type"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["attendance_id"], name: "index_players_on_attendance_id"
    t.index ["user_id"], name: "index_players_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.integer "announcement_batch_size", default: 10, null: false
    t.integer "announcement_daily_quota_threshold", default: 70, null: false
    t.integer "announcement_retry_interval_hours", default: 2, null: false
    t.string "circle_name"
    t.datetime "created_at", null: false
    t.string "signup_token"
    t.datetime "updated_at", null: false
  end

  create_table "user_mail_addresses", force: :cascade do |t|
    t.string "address", null: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["address"], name: "index_user_mail_addresses_on_address", unique: true
    t.index ["confirmation_token"], name: "index_user_mail_addresses_on_confirmation_token", unique: true
    t.index ["user_id"], name: "index_user_mail_addresses_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "disabled_at"
    t.string "email_address"
    t.datetime "last_accessed_at"
    t.string "password_digest"
    t.boolean "receives_announcements", default: true
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "venues", force: :cascade do |t|
    t.text "announcement_detail"
    t.text "announcement_summary"
    t.datetime "created_at", null: false
    t.string "name"
    t.string "short_name"
    t.datetime "updated_at", null: false
    t.string "url"
  end

  add_foreign_key "announcement_deliveries", "announcements"
  add_foreign_key "announcement_delivery_results", "announcement_deliveries"
  add_foreign_key "announcements", "announcement_templates"
  add_foreign_key "attendances", "events"
  add_foreign_key "attendances", "players"
  add_foreign_key "event_announcements", "announcements"
  add_foreign_key "event_announcements", "events"
  add_foreign_key "events", "venues"
  add_foreign_key "players", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "user_mail_addresses", "users"
end
