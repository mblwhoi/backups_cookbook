#
# Cookbook Name:: backup_manager
# Recipe:: default
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
clients = search(node[:backup][:manager][:client_search_index], node[:backup][:manager][:client_search_query])

# Get old list of backup clients we service from node attributes.
old_client_list = []
if node[:backup][:manager].attribute?("clients")
  old_client_list = node[:backup][:manager][:clients]
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

  # Set the path to the authorized_keys file
  authorized_keys_file = "#{storage_folder}/.ssh/authorized_keys"

  # Create authorized_keys file if it does not exist.
  execute "create authorized_keys file for #{client_name}" do
    command "touch #{authorized_keys_file}; chown #{user_name}:#{user_name} #{authorized_keys_file}; chmod 700 #{authorized_keys_file}"
    not_if "test -f #{authorized_keys_file}"
  end

  # Add the client's root public keys to the user's authorized_keys file.
  # Note: the public keys come from the client node's attributes.
  client_key = ""
  if client.attribute?('user_public_keys') && client[:user_public_keys].attribute?('root') && client[:user_public_keys][:root]

    # For each key...
    client[:user_public_keys][:root].each do |key_name, key|

      # Add key if it is not in the authorized_keys file.
      execute "add key #{key_name} for #{client_name}" do
        command "echo '#{key}' >> #{authorized_keys_file}"
        not_if "grep -q -v '#{key}' #{authorized_keys_file}"
      end
    
    end

  end

end

