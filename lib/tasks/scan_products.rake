task :scan_products => :environment do |t, args|
  ScanProducts.activate
end