namespace :gml_objects do

  desc "Save all GmlObjects to disk"
  task :save_to_disk => :environment do
    Tag.find_each do |tag|
      obj = tag.gml_object
      puts "#{obj.id} (#{obj.tag_id}) data.length=#{obj.data.length} ..."
      obj.store_on_disk
    end
  end


  desc "Generate empty GmlObjects for all Tags that don't have them"
  task :fix_missing => :environment do
    Tag.find_each do |tag|
      next unless tag.gml_object.nil?
      tag.send(:build_gml_object)
      tag.send(:save_gml_object)
    end
  end

  desc "Save all GML objects to IPFS"
  task save_to_ipfs: :environment do
    count = 0
    failed = 0
    
    Tag.find_each do |tag|
      next unless tag.gml_object.present?
      
      begin
        puts "Saving Tag ##{tag.id} to IPFS..."
        tag.gml_object.save_to_ipfs
        count += 1
        puts "  → Saved with hash: #{tag.reload.ipfs_hash}"
      rescue => e
        puts "  → Failed: #{e.message}"
        failed += 1
      end
    end
    
    puts "Successfully saved #{count} GML files to IPFS"
    puts "Failed to save #{failed} GML files" if failed > 0
  end

  desc "Verify IPFS hashes for all tags"
  task verify_ipfs: :environment do
    count = 0
    verified = 0
    failed = 0
    
    Tag.where.not(ipfs_hash: nil).find_each do |tag|
      count += 1
      puts "Verifying Tag ##{tag.id} (#{tag.ipfs_hash})..."
      
      begin
        data = tag.gml_object.read_from_ipfs
        if data.present?
          verified += 1
          puts "  → Verified (#{data.length} bytes)"
        else
          failed += 1
          puts "  → Failed: No data returned"
        end
      rescue => e
        failed += 1
        puts "  → Failed: #{e.message}"
      end
    end
    
    puts "Checked #{count} tags with IPFS hashes"
    puts "Verified: #{verified}"
    puts "Failed: #{failed}"
  end

end

