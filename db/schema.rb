# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20190301153530) do

  create_table "apps", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "comments", force: :cascade do |t|
    t.string   "title",            limit: 50,    default: ""
    t.text     "text",             limit: 65535
    t.integer  "commentable_id",   limit: 4
    t.string   "commentable_type", limit: 255
    t.integer  "user_id",          limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ip_address",       limit: 255
    t.datetime "hidden_at"
  end

  add_index "comments", ["commentable_id"], name: "index_comments_on_commentable_id", using: :btree
  add_index "comments", ["commentable_type"], name: "index_comments_on_commentable_type", using: :btree
  add_index "comments", ["user_id"], name: "index_comments_on_user_id", using: :btree

  create_table "favorites", force: :cascade do |t|
    t.integer  "user_id",     limit: 4
    t.string   "object_type", limit: 255
    t.integer  "object_id",   limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "favorites", ["object_id", "object_type"], name: "index_favorites_on_object_id_and_object_type", using: :btree
  add_index "favorites", ["object_id", "object_type"], name: "index_on_object_id_and_object_type", using: :btree

  create_table "forum_posts", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "forum_threads", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "forums", force: :cascade do |t|
    t.string   "name",        limit: 255
    t.string   "description", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "likes", force: :cascade do |t|
    t.integer  "object_id",   limit: 4
    t.string   "object_type", limit: 255
    t.integer  "user_id",     limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "notifications", force: :cascade do |t|
    t.string   "subject_id",      limit: 255
    t.string   "subject_type",    limit: 255
    t.string   "verb",            limit: 255
    t.integer  "user_id",         limit: 4
    t.integer  "supplement_id",   limit: 4
    t.string   "supplement_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "notifications", ["user_id"], name: "index_notifications_on_user_id", using: :btree

  create_table "tags", force: :cascade do |t|
    t.integer  "user_id",            limit: 4
    t.string   "title",              limit: 255
    t.string   "slug",               limit: 255
    t.integer  "comment_count",      limit: 4
    t.integer  "likes_count",        limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "location",           limit: 255
    t.string   "application",        limit: 255
    t.string   "author",             limit: 255
    t.string   "cached_tag_list",    limit: 255
    t.string   "image_file_name",    limit: 255
    t.string   "image_content_type", limit: 255
    t.integer  "image_file_size",    limit: 4
    t.datetime "image_updated_at"
    t.string   "uuid",               limit: 255
    t.string   "ip",                 limit: 255
    t.text     "description",        limit: 65535
    t.string   "remote_image",       limit: 255
    t.string   "remote_secret",      limit: 255
    t.string   "gml_application",    limit: 255
    t.string   "gml_version",        limit: 255
    t.string   "gml_username",       limit: 255
    t.string   "gml_uniquekey",      limit: 255
    t.string   "gml_uniquekey_hash", limit: 255
    t.string   "gml_keywords",       limit: 255
    t.integer  "size",               limit: 4
    t.string   "ipfs_hash",          limit: 255
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "login",              limit: 255,                null: false
    t.string   "email",              limit: 255,   default: "", null: false
    t.string   "crypted_password",   limit: 255,                null: false
    t.string   "password_salt",      limit: 255,                null: false
    t.string   "persistence_token",  limit: 255,                null: false
    t.string   "perishable_token",   limit: 255,   default: "", null: false
    t.integer  "login_count",        limit: 4,     default: 0,  null: false
    t.datetime "last_request_at"
    t.datetime "last_login_at"
    t.datetime "current_login_at"
    t.string   "last_login_ip",      limit: 255
    t.string   "current_login_ip",   limit: 255
    t.boolean  "admin"
    t.string   "photo_file_name",    limit: 255
    t.string   "photo_content_type", limit: 255
    t.integer  "photo_file_size",    limit: 4
    t.datetime "photo_updated_at"
    t.string   "website",            limit: 255
    t.string   "tagline",            limit: 255
    t.text     "about",              limit: 65535
    t.string   "location",           limit: 255
    t.string   "slug",               limit: 255
    t.string   "name",               limit: 255
    t.string   "iphone_uniquekey",   limit: 255
  end

  add_index "users", ["email"], name: "index_users_on_email", using: :btree
  add_index "users", ["iphone_uniquekey"], name: "index_users_on_iphone_uniquekey", using: :btree
  add_index "users", ["last_request_at"], name: "index_users_on_last_request_at", using: :btree
  add_index "users", ["login"], name: "index_users_on_login", using: :btree
  add_index "users", ["perishable_token"], name: "index_users_on_perishable_token", using: :btree
  add_index "users", ["persistence_token"], name: "index_users_on_persistence_token", using: :btree

  create_table "visualizations", force: :cascade do |t|
    t.integer  "user_id",            limit: 4
    t.string   "name",               limit: 255
    t.string   "slug",               limit: 255
    t.string   "website",            limit: 255
    t.string   "download",           limit: 255
    t.string   "version",            limit: 255
    t.text     "description",        limit: 65535
    t.string   "authors",            limit: 255
    t.string   "kind",               limit: 255,   default: ""
    t.boolean  "is_embeddable",                    default: false
    t.string   "embed_url",          limit: 255
    t.string   "embed_callback",     limit: 255
    t.string   "embed_params",       limit: 255
    t.text     "embed_code",         limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "approved_at"
    t.integer  "approved_by",        limit: 4
    t.string   "image_file_name",    limit: 255
    t.string   "image_content_type", limit: 255
    t.integer  "image_file_size",    limit: 4
  end

end
