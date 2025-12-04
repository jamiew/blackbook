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

ActiveRecord::Schema[8.1].define(version: 2025_12_04_000001) do
  create_table "comments", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.integer "commentable_id"
    t.string "commentable_type"
    t.datetime "created_at", precision: nil
    t.datetime "hidden_at", precision: nil
    t.string "ip_address"
    t.text "text", size: :medium
    t.string "title", limit: 50, default: ""
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.index ["commentable_id"], name: "index_comments_on_commentable_id"
    t.index ["commentable_type"], name: "index_comments_on_commentable_type"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "favorites", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "object_id"
    t.string "object_type"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.index ["object_id", "object_type"], name: "index_favorites_on_object_id_and_object_type"
    t.index ["user_id", "object_id", "object_type"], name: "index_favorites_unique_on_user_and_object", unique: true
  end

  create_table "likes", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.integer "object_id"
    t.string "object_type"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.index ["user_id", "object_id", "object_type"], name: "index_likes_unique_on_user_and_object", unique: true
  end

  create_table "notifications", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.datetime "created_at", precision: nil
    t.string "subject_id"
    t.string "subject_type"
    t.integer "supplement_id"
    t.string "supplement_type"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.string "verb"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "tags", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.string "application"
    t.string "author"
    t.string "cached_tag_list"
    t.integer "comment_count"
    t.datetime "created_at", precision: nil
    t.text "description", size: :medium
    t.string "gml_application"
    t.string "gml_keywords"
    t.string "gml_uniquekey"
    t.string "gml_uniquekey_hash"
    t.string "gml_username"
    t.string "gml_version"
    t.string "image_content_type"
    t.string "image_file_name"
    t.integer "image_file_size"
    t.datetime "image_updated_at", precision: nil
    t.string "ip"
    t.integer "likes_count"
    t.string "location"
    t.string "remote_image"
    t.string "remote_secret"
    t.string "slug"
    t.string "title"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.string "uuid"
  end

  create_table "users", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.text "about", size: :medium
    t.boolean "admin"
    t.datetime "created_at", precision: nil
    t.string "crypted_password", null: false
    t.datetime "current_login_at", precision: nil
    t.string "current_login_ip"
    t.string "email", default: "", null: false
    t.string "iphone_uniquekey"
    t.datetime "last_login_at", precision: nil
    t.string "last_login_ip"
    t.datetime "last_request_at", precision: nil
    t.string "location"
    t.string "login", null: false
    t.integer "login_count", default: 0, null: false
    t.string "name"
    t.string "password_salt", null: false
    t.string "perishable_token", default: "", null: false
    t.string "persistence_token", null: false
    t.string "photo_content_type"
    t.string "photo_file_name"
    t.integer "photo_file_size"
    t.datetime "photo_updated_at", precision: nil
    t.string "slug"
    t.string "tagline"
    t.datetime "updated_at", precision: nil
    t.string "website"
    t.index ["email"], name: "index_users_on_email"
    t.index ["iphone_uniquekey"], name: "index_users_on_iphone_uniquekey"
    t.index ["last_request_at"], name: "index_users_on_last_request_at"
    t.index ["login"], name: "index_users_on_login"
    t.index ["perishable_token"], name: "index_users_on_perishable_token"
    t.index ["persistence_token"], name: "index_users_on_persistence_token"
  end

  create_table "visualizations", id: :integer, charset: "utf8mb3", force: :cascade do |t|
    t.datetime "approved_at", precision: nil
    t.integer "approved_by"
    t.string "authors"
    t.datetime "created_at", precision: nil
    t.text "description", size: :medium
    t.string "download"
    t.string "embed_callback"
    t.text "embed_code", size: :long
    t.string "embed_params"
    t.string "embed_url"
    t.string "image_content_type"
    t.string "image_file_name"
    t.integer "image_file_size"
    t.boolean "is_embeddable", default: false
    t.string "kind", default: ""
    t.string "name"
    t.string "slug"
    t.datetime "updated_at", precision: nil
    t.integer "user_id"
    t.string "version"
    t.string "website"
    t.index ["name"], name: "index_visualizations_unique_on_name", unique: true
  end
end
