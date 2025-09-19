# frozen_string_literal: true

namespace :tags do
  def find_tags_with_missing_data
    bad = []
    Tag.find_each do |tag|
      print '.'
      $stdout.flush
      bad << tag if tag.data.blank?
    end
    bad
  end

  desc 'Find tags that have missing data'
  task find_missing_data: :environment do
    bad = find_tags_with_missing_data
    puts "Found #{bad.length} tags with missing data: #{bad.map(&:id).join(', ')}"
  end

  desc 'Delete tags with missing data'
  task delete_missing_data: :environment do
    bad = find_tags_with_missing_data
    puts "Deleting #{bad.length} bad-tags..."
    bad.each { |t| puts t.destroy }
    puts 'Done'
  end
end
