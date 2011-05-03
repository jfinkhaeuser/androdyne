class CreateLogMessages < ActiveRecord::Migration
  def self.up
    create_table :log_messages do |t|
      # Display information
      t.string  :tag,             :null => false
      t.string  :message,         :null => false

      # Foreign key
      t.integer :stacktrace_id,   :null => false

      t.timestamps
    end

    add_index :log_messages, ["tag", "message"], :name => "index_log_messages_on_unique", :unique => true
  end

  def self.down
    drop_table :log_messages
  end
end
