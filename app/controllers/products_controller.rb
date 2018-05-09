class ProductsController < ApplicationController
	skip_before_filter :verify_authenticity_token
	before_filter :set_headers

	def order_creation
		puts Colorize.magenta(params)

		verified = verify_webhook(request.body.read, request.headers["HTTP_X_SHOPIFY_HMAC_SHA256"])
		if verified
			

		end

		head :ok, content_type: "text/html"
	end

	def product_update
		puts Colorize.magenta(params)

		verified = verify_webhook(request.body.read, request.headers["HTTP_X_SHOPIFY_HMAC_SHA256"])
		if verified


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