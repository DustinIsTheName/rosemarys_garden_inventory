class ScanProducts
	def self.activate
		theme = ShopifyAPI::Theme.all.select{|t| t.role == 'main'}.first
		settings_data = ShopifyAPI::Asset.find('config/settings_data.json', :params => {:theme_id => theme.id})
		settings_json = JSON.parse(settings_data.value)

		for block in settings_json["current"]["sections"]["product-links"]["blocks"]
			block = block.last
			puts Colorize.purple(block)

			if block["type"] == "product-set"
				product = Product.new
				product_one_oz = ShopifyAPI::Product.find(:first, params: {handle: block["settings"]["product_one_oz"]})
				product_tenth_oz = ShopifyAPI::Product.find(:first, params: {handle: block["settings"]["product_tenth_oz"]})

				product.one_oz_shopify_id = product_one_oz.id
				product.tenth_oz_shopify_id = product_tenth_oz.id
				product.one_oz_quantity = product_one_oz.variants.first.inventory_quantity
				product.tenth_oz_quantity = product_tenth_oz.variants.first.inventory_quantity

				if product.save
					puts Colorize.green('saved product')
				else
					puts Colorize.red('error saving product')
				end
			end
		end
	end

	def self.create_blocks
		total_pages = (ShopifyAPI::Product.count/250.0).ceil
		theme = ShopifyAPI::Theme.all.select{|t| t.role == 'main'}.first
		settings_data = ShopifyAPI::Asset.find('config/settings_data.json', :params => {:theme_id => theme.id})
		settings_json = JSON.parse(settings_data.value)

		iteration = 0000000000000
		start_time = Time.now

		pairless_products = []

		for page in 1..total_pages
			products = ShopifyAPI::Product.find(:all, params: {limit: 250, page: page})

			for product in products
				if ShopifyAPI.credit_left < 5
					puts "We have to wait 3 seconds then we will resume. Credit left: #{ShopifyAPI.credit_left}"
					sleep 3
				end

				if product.title.include? '(by 1/10 oz.)'
					one_oz_product = ShopifyAPI::Product.find(:all, params: {title: product.title.gsub('(by 1/10 oz.)', '').strip})&.select{|p| p.title.include? '(1 oz.)'}&.first

					if one_oz_product
						puts Colorize.orange(one_oz_product.title)
						settings_json["current"]["sections"]["product-links"]["blocks"][iteration.to_s.rjust(13, "0")] = {
							"type" => "product-set", 
							"settings" => {
								"title" => product.title.gsub('(by 1/10 oz.)', '').strip, 
								"product_one_oz" => one_oz_product.handle,
								"product_tenth_oz" => product.handle
							}
						}
						settings_json["current"]["sections"]["product-links"]["block_order"].push(iteration.to_s.rjust(13, "0"))
						iteration = iteration + 1
					else
						pairless_products.push(product.title)
					end
					puts Colorize.blue(product.title)
				end
			end
		end

		settings_data.value = JSON.pretty_generate(settings_json)
		if settings_data.save
			puts Colorize.green('saved settings')
		else
			puts Colorize.red('error saving settings')
		end

		for p in pairless_products
			puts Colorize.yellow(p)
		end
	end

	def self.add_tags
		total_pages = (ShopifyAPI::Product.count/250.0).ceil
		count = 0
		for page in 1..total_pages
			products = ShopifyAPI::Product.find(:all, params: {limit: 250, page: page})
			for product in products
				
				if ShopifyAPI.credit_left < 5
					puts "We have to wait 3 seconds then we will resume. Credit left: #{ShopifyAPI.credit_left}"
					sleep 3
				end

				if product.title.include? '(by 1/10 oz.)'
					count = count + 1
					product.tags = product.tags.add_tag 'exclude-from-stocky'

					if product.save
						puts Colorize.green(product.title + ' saved')
					else
						puts Colorize.red('error on ' + product.title)
					end
				end
			end
		end
		puts Colorize.green(count)
	end

	def self.adjust_inventory
		theme = ShopifyAPI::Theme.all.select{|t| t.role == 'main'}.first
		settings_data = ShopifyAPI::Asset.find('config/settings_data.json', :params => {:theme_id => theme.id})
		settings_json = JSON.parse(settings_data.value)

		skipped_products = []

		for block in settings_json["current"]["sections"]["product-links"]["blocks"]
			block = block.last

			if ShopifyAPI.credit_left < 5
				puts "We have to wait 3 seconds then we will resume. Credit left: #{ShopifyAPI.credit_left}"
				sleep 5
			end

			one_oz = ShopifyAPI::Product.find(:first, params: {handle: block["settings"]["product_one_oz"]})
			one_variant = one_oz.variants.first
			tenth_oz = ShopifyAPI::Product.find(:first, params: {handle: block["settings"]["product_tenth_oz"]})
			tenth_variant = tenth_oz.variants.first
			
			if one_variant.inventory_quantity > 0
				skipped_products.push(one_oz.title)
			else
				puts Colorize.cyan("#{one_oz.title}: #{one_variant.inventory_quantity}")
				puts Colorize.orange("#{tenth_oz.title}: #{tenth_variant.inventory_quantity}")
				puts Colorize.magenta("total: #{tenth_variant.inventory_quantity + one_variant.inventory_quantity * 10}\n")

				tenth_variant.inventory_quantity = tenth_variant.inventory_quantity + one_variant.inventory_quantity * 10
				if tenth_variant.save
					puts Colorize.green("saved #{tenth_oz.title} as #{tenth_variant.inventory_quantity}")
				else
					puts Colorize.red("error saving #{tenth_oz.title}")
				end

				one_variant.inventory_quantity = (tenth_variant.inventory_quantity / 10).floor
				if one_variant.save
					puts Colorize.green("saved #{one_oz.title} as #{one_variant.inventory_quantity}\n")
				else
					puts Colorize.red("error saving #{one_oz.title}\n")
				end

			end
		end

		for p in skipped_products
			puts Colorize.yellow(p)
		end
	end
end

















