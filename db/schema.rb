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

ActiveRecord::Schema[8.1].define(version: 2026_01_18_025624) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "announcement_templates", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.boolean "default"
    t.text "subject"
    t.datetime "updated_at", null: false
  end

  create_table "announcements", force: :cascade do |t|
    t.bigint "announcement_template_id"
    t.text "bcc_addresses", default: [], array: true
    t.text "body"
    t.datetime "created_at", null: false
    t.bigint "event_id"
    t.datetime "sent_at"
    t.integer "sent_by"
    t.text "subject"
    t.string "to_address"
    t.datetime "updated_at", null: false
    t.index ["announcement_template_id"], name: "index_announcements_on_announcement_template_id"
    t.index ["event_id"], name: "index_announcements_on_event_id"
  end

  create_table "attendances", force: :cascade do |t|
    t.boolean "after_party"
    t.time "arrival_time"
    t.datetime "created_at", null: false
    t.time "departure_time"
    t.bigint "event_id", null: false
    t.text "message"
    t.bigint "player_id", null: false
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_attendances_on_event_id"
    t.index ["player_id"], name: "index_attendances_on_player_id"
  end

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date"
    t.time "end_time"
    t.text "notes"
    t.time "start_time"
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
    t.string "circle_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.boolean "receives_announcements", default: true
    t.string "role"
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "venues", force: :cascade do |t|
    t.text "announcement_detail"
    t.text "announcement_summary"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.string "url"
  end

  add_foreign_key "announcements", "announcement_templates"
  add_foreign_key "announcements", "events"
  add_foreign_key "attendances", "events"
  add_foreign_key "attendances", "players"
  add_foreign_key "events", "venues"
  add_foreign_key "players", "users"
  add_foreign_key "sessions", "users"
end
