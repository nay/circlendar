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

ActiveRecord::Schema[8.0].define(version: 2025_10_10_053814) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "announcement_templates", force: :cascade do |t|
    t.string "name"
    t.text "subject"
    t.text "body"
    t.boolean "is_default"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "announcements", force: :cascade do |t|
    t.bigint "event_id"
    t.integer "sent_by"
    t.text "subject"
    t.text "body"
    t.string "to_address"
    t.text "bcc_addresses", default: [], array: true
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_announcements_on_event_id"
  end

  create_table "attendances", force: :cascade do |t|
    t.bigint "event_id", null: false
    t.bigint "player_id", null: false
    t.string "status"
    t.time "arrival_time"
    t.time "departure_time"
    t.boolean "after_party"
    t.text "message"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_attendances_on_event_id"
    t.index ["player_id"], name: "index_attendances_on_player_id"
  end

  create_table "events", force: :cascade do |t|
    t.bigint "venue_id", null: false
    t.date "date"
    t.time "start_time"
    t.time "end_time"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "draft", null: false
    t.index ["venue_id"], name: "index_events_on_venue_id"
  end

  create_table "players", force: :cascade do |t|
    t.string "type"
    t.bigint "user_id"
    t.string "name"
    t.string "organization_name"
    t.string "rank"
    t.bigint "attendance_id"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attendance_id"], name: "index_players_on_attendance_id"
    t.index ["user_id"], name: "index_players_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "settings", force: :cascade do |t|
    t.string "circle_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.string "role"
    t.boolean "receives_announcements", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "venues", force: :cascade do |t|
    t.string "name"
    t.string "address"
    t.string "url"
    t.text "access_info"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "announcements", "events"
  add_foreign_key "attendances", "events"
  add_foreign_key "attendances", "players"
  add_foreign_key "events", "venues"
  add_foreign_key "players", "users"
  add_foreign_key "sessions", "users"
end
