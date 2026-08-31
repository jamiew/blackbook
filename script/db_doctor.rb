# Says why the app cannot reach the database, instead of hanging.
#
#   docker exec <container> bin/rails runner /rails/script/db_doctor.rb
#
# A failed connection inside a container reaches the browser as a 504 or a
# blank 500, which looks the same whether the app is slow, the port is
# blocked, or the credentials are wrong. This tries the connection several
# ways and says which of them work. It never prints the password.
config = ActiveRecord::Base.connection_db_config.configuration_hash

puts "  client library: #{Mysql2::Client.info.inspect}"
puts "  host=#{config[:host]} database=#{config[:database]} username=#{config[:username]}"
puts "  ssl_mode=#{config[:ssl_mode].inspect} connect_timeout=#{config[:connect_timeout].inspect}"

base = config.slice(:host, :port, :username, :password, :database).merge(connect_timeout: 5)

attempts = {
  "as configured" => config.except(:adapter, :pool),
  "no ssl option" => base,
  "ssl_mode disabled" => base.merge(ssl_mode: :disabled),
  "no CLIENT_SSL flag" => base.merge(flags: %w[-SSL]),
  "unix socket" => base.except(:host, :port).merge(socket: "/var/run/mysqld/mysqld.sock")
}

attempts.each do |name, options|
  started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  client = Mysql2::Client.new(**options.symbolize_keys)
  puts "  #{name}: ok, server is #{client.query('SELECT VERSION()').first.values.first}"
  client.close
rescue StandardError => e
  elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
  puts "  #{name}: #{e.class} after #{elapsed.round(1)}s - #{e.message.lines.first.to_s.strip[0, 160]}"
end
