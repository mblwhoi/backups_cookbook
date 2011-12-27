#
# Cookbook Name:: backups
# Recipe:: manager
#

# Make backups parent directory.
directory "#{node[:backup][:manager][:backup_dir]}" do
  owner "root"
  group "root"
  mode "0755"
  action :create
  recursive true
end

# Get current list of backup clients to service.
clients = search(node['backup']['manager']['client_search_index'], node['backup']['manager']['client_search_query'])

# Get old list of backup clients we service from node attributes.
old_client_list = []
if node['backup']['manager'].attribute?("clients")
  old_client_list = node['backup']['manager']['clients']
end

# Remove clients which are not in the current list.
# REMOVE DEFUNCT CLIENTS HERE?

# Persist client list for the next run.
node.set['backup']['manager']['clients'] = clients

# For each node in the current list...
clients.each do |client|
  
  # Use first 32 characters of client's name as the username.
  client_name = client.name
  user_name = "%.32s" % client_name

  # Generate the path of the client's storage folder
  storage_folder = "#{node[:backup][:manager][:backup_dir]}/#{user_name}"

  # Make a user.
  user "#{user_name}" do
    comment "#{client_name} backup user"
    home "#{storage_folder}"
    shell "/bin/bash"
  end

  # Make a directory, readable only by the user.
  directory "#{storage_folder}" do
    owner "#{user_name}"
    group "#{user_name}"
    mode "0700"
    action :create
  end
  
  # Create .ssh folder if it does not exist.
  directory "#{storage_folder}/.ssh" do
    owner "#{user_name}"
    group "#{user_name}"
    mode "0700"
    action :create
  end

  # Initialize a list of public keys which should have access to the backups.
  access_keys = []

  # Add the client's root public keys to the list.
  # Note: root users's public keys come from the client node's attributes,
  # via the ohai plugin 'user_public_keys'.
  client_key = ""
  if client.attribute?('user_public_keys') && client['user_public_keys'].attribute?('root') && client['user_public_keys']['root']
    client['user_public_keys']['root'].each do |key_name, key|
      access_keys << key
    end
  end

  # Add the client's users' public keys to the list.
  # Note: the users for which we try to add keys are those users specified
  # in a node's [users][user_configs] attributes, per the users::users recipe.
  if client.attribute?('users') && client['users'].attribute?('user_configs')
    client['users']['user_configs'].each do |user_config|
      
      user = {}
      
      # If type is databag, get user data from databag.
      if user_config["type"] == 'databag'
        databag = user_config["databag"] || node["users"]["default_users_databag"]
        search("#{databag}", "id:#{user_config['id']}") do |u| 
          user.merge!(u)
        end 

      # If type is inline, get user data from the given configuration.
      elsif user_config["type"] == 'inline'
        user.merge!(user_config)
      end 

      # If we do have a user...
      if user['id']
        # Try to get the user's authorized keys.
        if ! user['ssh_keys'].nil?
          user['ssh_keys'].each do |key|
            access_keys << key
          end
        end
      end
    end
  end

  # Generate the authorized keys file from the access keys.
  template "#{storage_folder}/.ssh/authorized_keys" do
    source "authorized_keys.erb"
    owner "#{user_name}"
    group "#{user_name}"
    mode "0600"
    variables :ssh_keys => access_keys
  end


end

