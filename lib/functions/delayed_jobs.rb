class DelayedJobs

	def self.order_creation(params)
		theme = ShopifyAPI::Theme.all.select{|t| t.role == 'main'}.first
		settings_data = ShopifyAPI::Asset.find('config/settings_data.json', :params => {:theme_id => theme.id})
		settings_json = JSON.parse(settings_data.value)

		for item in params["line_items"]

			if ShopifyAPI.credit_left < 5
				puts Colorize.bright('about to exceed credit, waiting 10 seconds')
				sleep 10
			end

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

							unless p
								p = create_product(product.id, linked_product.id, product.variants.first.inventory_quantity, linked_product.variants.first.inventory_quantity)
							end

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
							
							unless p
								p = create_product(linked_product.id, product.id, linked_product.variants.first.inventory_quantity, product.variants.first.inventory_quantity)
							end

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

	def self.product_update(params)
		if ShopifyAPI.credit_left < 5
			puts Colorize.bright('about to exceed credit, waiting 10 seconds')
			sleep 10
		end
			
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

					unless p
						p = create_product(product.id, linked_product.id, product.variants.first.inventory_quantity, linked_product.variants.first.inventory_quantity)
					end

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
						p.tenth_oz_quantity = variant.inventory_quantity
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

					unless p
						p = create_product(linked_product.id, product.id, linked_product.variants.first.inventory_quantity, product.variants.first.inventory_quantity)
					end

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

						p.one_oz_quantity = variant.inventory_quantity
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

	def self.create_product(one_oz_id, tenth_oz_id, one_inventory_quantity, tenth_inventory_quantity)
		product = Product.new

		product.one_oz_shopify_id = one_oz_id
		product.tenth_oz_shopify_id = tenth_oz_id
		product.one_oz_quantity = one_inventory_quantity
		product.tenth_oz_quantity = tenth_inventory_quantity

		if product.save
			puts Colorize.purple('created internal product')
		else
			puts Colorize.red('error creating internal product')
		end

		product
	end

end









































