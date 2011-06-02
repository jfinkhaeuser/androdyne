class CreateLogMessagesOccurrencesJoinTable < ActiveRecord::Migration
  def self.up
    create_table :log_messages_occurrences, :id => false do |t|
      t.integer :occurrence_id,   :null => false
      t.integer :log_message_id,  :null => false
    end
  end

  def self.down
    drop_table :log_messages_occurrences
  end
end
