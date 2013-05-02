#!bin/env ruby
# encoding utf-8

require 'bundler/capistrano'
require './config/CORM_Object.rb'

deploy_json = JSON(File.read('./config/deploy.json'))
servers = deploy_json['servers']
hostnames = Array.new

logger.log(1, deploy_json['deployement'].to_s);

def createObject(o, depth)
    object = {}
    o.each do |index, value|
        if (value.is_a? Hash)
            object[index] = createObject(o[index], depth+1)
        else
            if (value.is_a? String)
                object[index] = (value[0] == ':' ? value[1..value.length].to_sym : value)
            else
                object[index] = value
            end
        end
    end
    return object
end

# set all capistrano variables
deploy_json['deployement'].each do |index, value|
    if (value.is_a? Hash)
        set index.to_sym, createObject(value, 0)
    elsif (value.is_a? String)
       set index.to_sym, (value[0] == ':' ? value[1..value.length].to_sym : value)
    else
        set index.to_sym, value
    end
end


# get all servers
servers.each do |hostname, content|
    if (defined? servers[hostname]['enabled'])
        if (servers[hostname]['enabled'] == true)
          hostnames.push(hostname)
          role :web, hostname
          role :app, hostname
          role :db, hostname, :primary => true
          logger.log(1, 'LOAD SERVER: ' + hostname)
        else
            logger.log(0, 'FAIL LOAD SERVER: ' + hostname)
        end
    else
        logger.log(0, 'FAIL LOAD SERVER: ' + hostname)
    end
end

logger.info(hostnames.join(', '))

# Ask version number
version = Capistrano::CLI.ui.ask("Enter version: ")
if(version.length == 0)
    corm = CORM_Object.get
    version = corm[:version].split(' ')[0]
end
logger.info('VERSION: ' + version.to_s)

namespace :deploy do
   task :start do ; end
   task :stop do ; end
    task :restart, :roles => :app, :except => { :no_release => true } do
     hostname = "$CAPISTRANO:HOST$"
     path = File.join(current_path, 'config', 'CORM.json')
     json_string = File.read(path)
     json_object = JSON.parse(json_string)
     
     corm = CORM_Object.createObject(json_object, 0, false)
     corm.set_version(version)
     
     corm['host'] = hostname
     if (corm['mail'])
         corm['mail'].each do |index, value|
             if (!servers[hostname][index].nil?)
                corm['mail'][index] = servers[hostname][index]
             end
         end
     end
     corm['host'] = servers[hostname]['host']
     
     corm.save(path)
     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
   end
   
   desc "Symlink shared configs and folders on each release"
   task :symlink_shared do
    run "ln -nfs #{shared_path}/config/database.yml #{release_path}/config/database.yml"
    run "ln -nfs #{shared_path}/assets #{release_path}/public/assets"
   end
   
   desc "Change owner of the tmp folder"
   task :change_owner_tmp do
    run "chown -R apache:apache #{deploy_to}"
   end
end

before 'deploy:assets:precompile', 'deploy:symlink_shared'
after 'deploy:update_code', 'deploy:migrate', 'deploy:change_owner_tmp'
# after "deploy:restart", "deploy:cleanup"


#set :deploy_via, :remote_cache
#set :ssh_options, {:forward_agent => true}

default_run_options[:pty] = true

