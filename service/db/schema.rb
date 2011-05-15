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
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20110503191448) do

  create_table "log_messages", :force => true do |t|
    t.string   "tag",           :null => false
    t.string   "message",       :null => false
    t.integer  "stacktrace_id", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "log_messages", ["tag", "message"], :name => "index_log_messages_on_unique", :unique => true

  create_table "occurrences", :force => true do |t|
    t.string   "phone",                        :null => false
    t.string   "os_version",                   :null => false
    t.integer  "count",         :default => 1, :null => false
    t.integer  "stacktrace_id",                :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "occurrences", ["stacktrace_id", "phone", "os_version"], :name => "index_occurrences_on_unique", :unique => true

  create_table "packages", :force => true do |t|
    t.string   "package_id", :null => false
    t.string   "name",       :null => false
    t.string   "secret",     :null => false
    t.integer  "user_id",    :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "packages", ["package_id"], :name => "index_packages_on_package_id", :unique => true

  create_table "stacktraces", :force => true do |t|
    t.integer  "version_code", :null => false
    t.string   "hash",         :null => false
    t.string   "version",      :null => false
    t.string   "trace",        :null => false
    t.integer  "package_id",   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "stacktraces", ["hash"], :name => "index_stacktraces_on_hash"
  add_index "stacktraces", ["package_id", "version_code", "hash"], :name => "index_stacktraces_on_unique", :unique => true

  create_table "users", :force => true do |t|
    t.string   "login",             :null => false
    t.string   "email",             :null => false
    t.string   "crypted_password",  :null => false
    t.string   "password_salt",     :null => false
    t.string   "persistence_token", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "users", ["email"], :name => "index_users_on_email", :unique => true
  add_index "users", ["login"], :name => "index_users_on_login", :unique => true
  add_index "users", ["persistence_token"], :name => "index_users_on_persistence_token", :unique => true

end
