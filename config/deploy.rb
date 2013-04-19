# config/deploy.rb

require 'bundler/capistrano'


set :rvm_ruby_string, :local               # use the same ruby as used locally for deployment
set :rvm_autolibs_flag, "read-only"        # more info: rvm help autolibs

before 'deploy:setup', 'rvm:install_rvm'   # install RVM
before 'deploy:setup', 'rvm:install_ruby'  # install Ruby and create gemset, OR:
before 'deploy:setup', 'rvm:create_gemset' # only create gemset

require "rvm/capistrano"

# this is handled by SV
#require 'capistrano-unicorn'
#after 'deploy:restart', 'unicorn:reload' # app IS NOT preloaded
#after 'deploy:restart', 'unicorn:restart'  # app preloaded


set :application, 'wmu-repo'

set :stages, %w(production staging)
set :default_stage, 'production'
require 'capistrano/ext/multistage'

default_run_options[:pty] = true
ssh_options[:forward_agent] = true

set :repository, "https://github.com/cfitz/wmu-repo.git"
set :deploy_to, "/var/www/#{application}"
set :branch, "master"

set :scm, :git
set :scm_verbose, true

set :deploy_via, :remote_cache
set :use_sudo, true
set :keep_releases, 3
set :user, 'deployer'

set :bundle_without, [:development, :test, :acceptance]
set :rake, "#{rake} --trace"

before 'deploy:finalize_update', 'deploy:assets:symlink'

after 'deploy:update_code', :upload_env_vars
after 'deploy:update_code', 'deploy:assets:precompile'

#before 'deploy:update_code', "deploy:clear_crontab"
after 'deploy:update_code', 'deploy:update_crontab'


after 'deploy:setup' do
  sudo "chown -R #{user} #{deploy_to} && chmod -R g+s #{deploy_to}"
end

namespace :deploy do
  desc <<-DESC
  Send a USR2 to the unicorn process to restart for zero downtime deploys.
  runit expects 2 to tell it to send the USR2 signal to the process.
  DESC

  task :restart, :roles => :app, :except => { :no_release => true } do
    run "sv 2 /home/#{user}/service/#{application}"
  end
  
  desc "Update the crontab file"
  task :update_crontab, :roles => :app, :except => { :no_release => true } do
    run "cd #{release_path} && bundle exec whenever --update-crontab #{application}"
  end
  
  desc "Update the crontab file"
  task :clear_crontab, :roles => :app, :except => { :no_release => true } do
    run "cd #{release_path} && bundle exec whenever --clear-crontab #{application}"
  end
 

  namespace :assets do

    task :precompile, :roles => :web do
      #from = source.next_revision(current_revision)
      #if capture("cd #{latest_release} && #{source.local.log(from)} vendor/assets/ lib/assets/ app/assets/ | wc -l").to_i > 0
        run_locally("rake assets:clean && rake assets:precompile")
        run_locally "cd public && tar -jcf assets.tar.bz2 assets"
        top.upload "public/assets.tar.bz2", "#{shared_path}", :via => :scp
        run "cd #{shared_path} && tar -jxf assets.tar.bz2 && rm assets.tar.bz2"
        run_locally "rm public/assets.tar.bz2"
        run_locally("rake assets:clean")
      #else
      #  logger.info "Skipping asset precompilation because there were no asset changes"
      #end
    end

    task :symlink, roles: :web do
      run ("rm -rf #{latest_release}/public/assets &&
            mkdir -p #{latest_release}/public &&
            mkdir -p #{shared_path}/assets &&
            ln -s #{shared_path}/assets #{latest_release}/public/assets")
    end
  end
end

task :upload_env_vars do
  upload(".env.#{rails_env}", "#{release_path}/.env.#{rails_env}", :via => :scp)
end