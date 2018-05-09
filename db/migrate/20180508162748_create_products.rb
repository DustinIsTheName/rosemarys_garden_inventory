class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
    	t.integer :one_oz_shopify_id
    	t.integer :tenth_oz_shopify_id
    	t.integer :one_oz_quantity
    	t.integer :tenth_oz_quantity

      t.timestamps null: false
    end
  end
end
