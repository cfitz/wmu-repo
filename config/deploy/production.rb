set :server_ip, "198.199.77.207"
server server_ip, :app, :web, :primary => true
set :rails_env, 'production'
set :branch, 'master'