set :application, "heywatch_ec2"

set :use_sudo, false

# GitHub repository
set :repository,  "git@github.com:citizencast/heywatch_ec2.git"
set :scm, :git
# The git repository is cloned to a temp directory
# => This folder is copied and pulled on update_code task
set :deploy_via, :remote_cache

set :user, 'merb'
set :deploy_to, "/home/merb/#{application}"

set :merb_env, 'production'
set :branch, "master" 
server "ec2-174-129-124-26.compute-1.amazonaws.com", :app, :web, :db, :primary => true

namespace :deploy do
  
  desc "Restarting mod_rails with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "touch #{current_path}/tmp/restart.txt"
  end

  [:start, :stop].each do |t|
    desc "#{t.to_s.capitalize} task is a no-op with mod_rails"
    task t, :roles => :app do ; end
  end
  
  task :migrate, :roles => :db, :only => { :primary => true } do
    rake = fetch(:rake, "rake")
    merb_env = fetch(:merb_env, "production")

    directory = case migrate_target.to_sym
      when :current then current_path
      when :latest  then current_release
      else raise ArgumentError, "unknown migration target #{migrate_target.inspect}"
      end

    run "cd #{directory}; #{rake} MERB_ENV=#{merb_env} db:autoupgrade"
  end
  
  desc "Copy config files into release path"
  task :copy_config_files do
    run "cp #{shared_path}/config/* #{release_path}/config/"
  end
  after "deploy:update_code", "deploy:copy_config_files"
  
  desc "Create shared/config directory and default database.yml."
  task :create_shared_config do
    run "mkdir -p #{shared_path}/config"

    top.upload(File.dirname(__FILE__) + '/application.rb_sample', "#{shared_path}/config/application.rb")
    
    puts "Please edit application.rb in the shared directory."
  end
  after "deploy:setup", "deploy:create_shared_config"
  
  desc "Link shared files into release_path"
  task :link_shared_files, :roles => :app do
    run <<-CMD
      ln -s #{shared_path}/production.db #{latest_release}/production.db && \
      cd #{latest_release} && ln #{shared_path}/config.ru
    CMD
  end
  after "deploy:update_code", "deploy:link_shared_files"
end
