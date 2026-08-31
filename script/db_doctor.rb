# Says why the app cannot reach the database, instead of hanging.
#
#   docker exec <container> bin/rails runner /rails/script/db_doctor.rb
#
# A failed connection inside a container shows up as a 504 from the proxy,
# which looks identical whether the app is slow, the port is blocked or the
# credentials are wrong. This prints the actual error. It never prints the
# password.
config = ActiveRecord::Base.connection_db_config.configuration_hash

puts "  host=#{config[:host]} database=#{config[:database]} username=#{config[:username]}"
puts "  ssl_mode=#{config[:ssl_mode].inspect} connect_timeout=#{config[:connect_timeout].inspect}"

begin
  version = ActiveRecord::Base.with_connection { |c| c.select_value("SELECT VERSION()") }
  puts "  connected, server is #{version}"
rescue StandardError => e
  puts "  #{e.class}: #{e.message.lines.first.to_s.strip[0, 300]}"
end
