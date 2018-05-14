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
end