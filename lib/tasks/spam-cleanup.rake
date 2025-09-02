desc "Cleanup spam"
task cleanup_spam: :environment do
  puts "OK let's kill the spam"

  users_with_tags = Tag.pluck(:user_id)

  users_with_comments = Comment.pluck(:user_id)

  puts "#{User.count} total users"
  puts "#{users_with_tags.uniq.length} users with tags"
  puts "#{users_with_comments.uniq.length} users with comments"
  puts "#{(users_with_tags.uniq & users_with_comments.uniq).length} with both"
end
