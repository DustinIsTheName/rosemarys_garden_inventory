class ProductsController < ApplicationController
	skip_before_filter :verify_authenticity_token
	before_filter :set_headers

	def order_creation
		puts Colorize.magenta(params)

		verified = verify_webhook(request.body.read, request.headers["HTTP_X_SHOPIFY_HMAC_SHA256"])
		if verified
			theme = ShopifyAPI::Theme.all.select{|t| t.role == 'main'}.first
			settings_data = ShopifyAPI::Asset.find('config/settings_data.json', :params => {:theme_id => theme.id})
			settings_json = JSON.parse(settings_data.value)

			for item in params["line_items"]
				if item["product_id"]
					product = ShopifyAPI::Product.find(item["product_id"])
					linked_product = false
					p = false
					amount_to_increase = 0
					new_inventory = 0

					for block in settings_json["current"]["sections"]["product-links"]["blocks"]
						block = block.last

						if block["type"] == "product-set"
							if block["settings"]["product_one_oz"] == product.handle

								puts Colorize.yellow('IS ONE OZ')

								linked_product = ShopifyAPI::Product.find(:first, params: {handle: block["settings"]["product_tenth_oz"]})
								variant = linked_product.variants.first
								old_inventory = variant.inventory_quantity
								p = Product.find_by_one_oz_shopify_id(product.id)
								amount_to_increase = -(item["quantity"]) * 10
								puts Colorize.orange('amount_to_increase: ' + amount_to_increase.to_s)

								variant.inventory_quantity = variant.inventory_quantity + amount_to_increase

								if old_inventory == variant.inventory_quantity
									puts Colorize.orange('no change in ' + linked_product.title)
								else
									if variant.save
										puts Colorize.green('updated tenth product, ' + linked_product.title)
									else
										puts Colorize.red('error updating tenth product')
									end

									p.one_oz_quantity = p.one_oz_quantity - item["quantity"]
									p.tenth_oz_quantity = linked_product.variants.first.inventory_quantity
									if p.save
										puts Colorize.cyan('updated internal product')
									else
										puts Colorize.yellow('error updating internal product')
									end
								end

							end
							if block["settings"]["product_tenth_oz"] == product.handle

								puts Colorize.yellow('IS ONE TENTH OZ')

								linked_product = ShopifyAPI::Product.find(:first, params: {handle: block["settings"]["product_one_oz"]})
								variant = linked_product.variants.first
								p = Product.find_by_tenth_oz_shopify_id(product.id)
								
								old_inventory = p.tenth_oz_quantity
								new_inventory = ((p.tenth_oz_quantity - item["quantity"])/10.0).floor
								puts Colorize.bright('tenth_oz_quantity: ' + p.tenth_oz_quantity.to_s)
								puts Colorize.bright('item_quantity: ' + item["quantity"].to_s)
								puts Colorize.orange('new_inventory: ' + new_inventory.to_s)

								variant.inventory_quantity = new_inventory

								if old_inventory == variant.inventory_quantity
									puts Colorize.orange('no change in ' + linked_product.title)
								else
									if variant.save
										puts Colorize.green('updated one oz product, ' + linked_product.title)
									else
										puts Colorize.red('error updating one oz product')
									end

									p.one_oz_quantity = linked_product.variants.first.inventory_quantity
									p.tenth_oz_quantity = p.tenth_oz_quantity - item["quantity"]
									if p.save
										puts Colorize.cyan('updated internal product')
									else
										puts Colorize.yellow('error updating internal product')
									end
								end

							end
						end
					end
				end
			end
		end

		head :ok, content_type: "text/html"
	end

	def product_update
		puts Colorize.magenta(params)

		verified = verify_webhook(request.body.read, request.headers["HTTP_X_SHOPIFY_HMAC_SHA256"])
		if verified
			theme = ShopifyAPI::Theme.all.select{|t| t.role == 'main'}.first
			settings_data = ShopifyAPI::Asset.find('config/settings_data.json', :params => {:theme_id => theme.id})
			settings_json = JSON.parse(settings_data.value)

			product = ShopifyAPI::Product.find(params["id"])
			linked_product = false
			p = false
			amount_to_increase = 0
			new_inventory = 0

			for block in settings_json["current"]["sections"]["product-links"]["blocks"]
				block = block.last

				if block["type"] == "product-set"
					if block["settings"]["product_one_oz"] == product.handle

						puts Colorize.yellow('IS ONE OZ')

						linked_product = ShopifyAPI::Product.find(:first, params: {handle: block["settings"]["product_tenth_oz"]})
						variant = linked_product.variants.first
						old_inventory = variant.inventory_quantity
						p = Product.find_by_one_oz_shopify_id(product.id)
						amount_to_increase = (product.variants.first.inventory_quantity - p.one_oz_quantity) * 10
						puts Colorize.orange('amount_to_increase: ' + amount_to_increase.to_s)

						variant.inventory_quantity = variant.inventory_quantity + amount_to_increase

						if old_inventory == variant.inventory_quantity
							puts Colorize.orange('no change in ' + linked_product.title)
						else
							if variant.save
								puts Colorize.green('updated tenth product, ' + linked_product.title)
							else
								puts Colorize.red('error updating tenth product')
							end

							p.one_oz_quantity = product.variants.first.inventory_quantity
							p.tenth_oz_quantity = linked_product.variants.first.inventory_quantity
							if p.save
								puts Colorize.cyan('updated internal product')
							else
								puts Colorize.yellow('error updating internal product')
							end
						end

					end
					if block["settings"]["product_tenth_oz"] == product.handle

						puts Colorize.yellow('IS ONE TENTH OZ')

						linked_product = ShopifyAPI::Product.find(:first, params: {handle: block["settings"]["product_one_oz"]})
						variant = linked_product.variants.first
						old_inventory = variant.inventory_quantity
						p = Product.find_by_tenth_oz_shopify_id(product.id)
						new_inventory = (product.variants.first.inventory_quantity/10.0).floor
						puts Colorize.orange('new_inventory: ' + new_inventory.to_s)

						variant.inventory_quantity = new_inventory

						if old_inventory == variant.inventory_quantity
							puts Colorize.orange('no change in ' + linked_product.title)
						else
							if variant.save
								puts Colorize.green('updated one oz product, ' + linked_product.title)
							else
								puts Colorize.red('error updating one oz product')
							end

							p.one_oz_quantity = linked_product.variants.first.inventory_quantity
							p.tenth_oz_quantity = product.variants.first.inventory_quantity
							if p.save
								puts Colorize.cyan('updated internal product')
							else
								puts Colorize.yellow('error updating internal product')
							end
						end

					end
				end
			end

		end

		head :ok, content_type: "text/html"
	end

	private

		def set_headers
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Request-Method'] = '*'
    end

		def verify_webhook(data, hmac_header)
			digest  = OpenSSL::Digest.new('sha256')
			calculated_hmac = Base64.encode64(OpenSSL::HMAC.digest(digest, ENV["WEBHOOK_SECRET"], data)).strip
			if calculated_hmac == hmac_header
				puts Colorize.green("Verified!")
			else
				puts Colorize.red("Invalid verification!")
			end
			calculated_hmac == hmac_header
		end
end