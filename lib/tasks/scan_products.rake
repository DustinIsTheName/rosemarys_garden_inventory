task :scan_products => :environment do |t, args|
  ScanProducts.activate
end

task :create_blocks => :environment do |t, args|
  ScanProducts.create_blocks
end

task :add_tags => :environment do |t, args|
  ScanProducts.add_tags
end

task :adjust_inventory => :environment do |t, args|
  ScanProducts.adjust_inventory
end