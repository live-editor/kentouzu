class CreateMessages < ActiveRecord::Migration
  def change
    create_table :messages do |t|
      t.string :first_name, :null => false, :default => ''
      t.string :last_name,  :null => false, :default => ''
      t.string :subject,    :null => false, :default => ''
      t.text :body
      t.timestamps
    end

    change_table :messages do |t|
      t.index :first_name
      t.index :last_name
      t.index :subject
      t.index :created_at
      t.index :updated_at
    end
  end
end
