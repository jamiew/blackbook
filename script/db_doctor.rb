# Says why the app cannot reach the database, instead of hanging.
#
#   bin/kamal app exec --reuse "bin/rails runner /rails/script/db_doctor.rb"
#
# A failed connection inside a container reaches the browser as a 504 or a
# blank 500, which looks the same whether the app is slow, the socket is
# missing or the credentials are wrong. This says which. It never prints the
# password.
config = ActiveRecord::Base.connection_db_config.configuration_hash

puts "  client library: #{Mysql2::Client.info.inspect}"
puts "  socket=#{config[:socket]} database=#{config[:database]} username=#{config[:username]}"

begin
  version = ActiveRecord::Base.connection.select_value("SELECT VERSION()")
  puts "  connected, server is #{version}"
rescue StandardError => e
  puts "  FAILED: #{e.class} - #{e.message.lines.first.to_s.strip[0, 200]}"
  exit 1
end

# A connection that works while the schema is behind the code looks exactly
# like a broken connection from the outside: every page 500s.
puts "  pending migrations: #{ActiveRecord::Base.connection_pool.migration_context.needs_migration?}"
puts "  tables: #{ActiveRecord::Base.connection.tables.sort.join(', ')}"
