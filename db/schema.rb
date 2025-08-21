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

ActiveRecord::Schema[8.0].define(version: 2025_08_21_173228) do
  create_table "comments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "title", limit: 50, default: ""
    t.text "text"
    t.integer "commentable_id"
    t.string "commentable_type"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "ip_address"
    t.datetime "hidden_at"
    t.index ["commentable_id"], name: "index_comments_on_commentable_id"
    t.index ["commentable_type"], name: "index_comments_on_commentable_type"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "favorites", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "user_id"
    t.string "object_type"
    t.integer "object_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["object_id", "object_type"], name: "index_favorites_on_object_id_and_object_type"
    t.index ["object_id", "object_type"], name: "index_on_object_id_and_object_type"
  end

  create_table "likes", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "object_id"
    t.string "object_type"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "notifications", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "subject_id"
    t.string "subject_type"
    t.string "verb"
    t.integer "user_id"
    t.integer "supplement_id"
    t.string "supplement_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "tags", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "user_id"
    t.string "title"
    t.string "slug"
    t.integer "comment_count"
    t.integer "likes_count"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "location"
    t.string "application"
    t.string "author"
    t.string "cached_tag_list"
    t.string "image_file_name"
    t.string "image_content_type"
    t.integer "image_file_size"
    t.datetime "image_updated_at"
    t.string "uuid"
    t.string "ip"
    t.text "description"
    t.string "remote_image"
    t.string "remote_secret"
    t.string "gml_application"
    t.string "gml_version"
    t.string "gml_username"
    t.string "gml_uniquekey"
    t.string "gml_uniquekey_hash"
    t.string "gml_keywords"
    t.integer "size"
    t.string "ipfs_hash"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "login", null: false
    t.string "email", default: "", null: false
    t.string "crypted_password", null: false
    t.string "password_salt", null: false
    t.string "persistence_token", null: false
    t.string "perishable_token", default: "", null: false
    t.integer "login_count", default: 0, null: false
    t.datetime "last_request_at"
    t.datetime "last_login_at"
    t.datetime "current_login_at"
    t.string "last_login_ip"
    t.string "current_login_ip"
    t.boolean "admin"
    t.string "photo_file_name"
    t.string "photo_content_type"
    t.integer "photo_file_size"
    t.datetime "photo_updated_at"
    t.string "website"
    t.string "tagline"
    t.text "about"
    t.string "location"
    t.string "slug"
    t.string "name"
    t.string "iphone_uniquekey"
    t.index ["email"], name: "index_users_on_email"
    t.index ["iphone_uniquekey"], name: "index_users_on_iphone_uniquekey"
    t.index ["last_request_at"], name: "index_users_on_last_request_at"
    t.index ["login"], name: "index_users_on_login"
    t.index ["perishable_token"], name: "index_users_on_perishable_token"
    t.index ["persistence_token"], name: "index_users_on_persistence_token"
  end

  create_table "visualizations", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "user_id"
    t.string "name"
    t.string "slug"
    t.string "website"
    t.string "download"
    t.string "version"
    t.text "description"
    t.string "authors"
    t.string "kind", default: ""
    t.boolean "is_embeddable", default: false
    t.string "embed_url"
    t.string "embed_callback"
    t.string "embed_params"
    t.text "embed_code"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "approved_at"
    t.integer "approved_by"
    t.string "image_file_name"
    t.string "image_content_type"
    t.integer "image_file_size"
  end
end
