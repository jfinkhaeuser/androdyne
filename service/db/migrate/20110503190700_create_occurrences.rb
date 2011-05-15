class CreateOccurrences < ActiveRecord::Migration
  def self.up
    create_table :occurrences do |t|
      # Identifying information
      t.string  :phone,           :null => false
      t.string  :os_version,      :null => false

      # Display information
      t.integer :count,           :null => false, :default => 1

      # Foreign key
      t.integer :stacktrace_id,   :null => false

      t.timestamps
    end

    add_index :occurrences, ["stacktrace_id", "phone", "os_version"], :name => "index_occurrences_on_unique", :unique => true
  end

  def self.down
    drop_table :occurrences
  end
end
