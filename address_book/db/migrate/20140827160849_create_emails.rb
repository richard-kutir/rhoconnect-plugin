class CreateEmails < ActiveRecord::Migration
  def change
    create_table :emails do |t|
      t.references :person, index: true
      t.string :address

      t.timestamps
    end
  end
end
