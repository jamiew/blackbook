namespace :gml_objects do

  desc "Save all GmlObjects to disk"
  task :save_to_disk => :environment do
    GmlObject.find_each do |obj|
      puts "#{obj.id} (#{obj.tag_id}) data.length=#{obj.data.length} ..."
      obj.store_on_disk(true)
    end
  end
end

