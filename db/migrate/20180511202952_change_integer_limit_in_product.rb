class ChangeIntegerLimitInProduct < ActiveRecord::Migration
  def change
  	change_column :products, :one_oz_shopify_id, :integer, limit: 8
  	change_column :products, :tenth_oz_shopify_id, :integer, limit: 8
  end
end
