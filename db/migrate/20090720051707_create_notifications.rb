class CreateNotifications < ActiveRecord::Migration
  def self.up
    create_table :notifications do |t|
      t.string :subject_id
      t.string :subject_type
      t.string :verb
      t.integer :user_id
      t.integer :supplement_id
      t.string :supplement_type

      t.timestamps
    end
  end

  def self.down
    drop_table :notifications
  end
end
