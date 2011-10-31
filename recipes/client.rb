#
# Cookbook Name:: backup
# Recipe:: default
#
# Backup client setup.  For making a client that works with a backup::destination.

# Note: we include ohai so that the 'user_public_keys' plugin gets included.
# TODO: put the user_public_keys plugin in its own recipe for clarity?
include_recipe %w{backup ssh_key ohai}

# Setup ssh key for root if no key exists.
ssh_key "root key" do
  user "root"
  type "dsa"
  action :create_if_missing
end

# Initialize a hash of processed destination configs.
processed_destinations = {}

# Process storage destinations.
node['backup']['client']['storage_destinations'].each do |destination_config|
  
  # Initialize processed destination config.
  processed_config = {}

  # Handle node name type configs.
  if destination_config['type'] == 'node'

    # Get node's domain name.
    ip = search('node', "name:#{destination_config['name']}")[0].ipaddress

    processed_config['type'] = 'node'
    processed_config['name'] = destination_config['name']
    processed_config['ip'] = ip


  # Handle ip address type configs.
  elsif destination_config['type'] == 'ip'

    name = search('node', "ip:#{destination_config['ip']}")[0].name

    processed_config['type'] = 'node'
    processed_config['name'] = name
    processed_config['ip'] = destination_config['ip']



  # Handle search type configs.
  elsif destination_config['type'] == 'search'

    # Get nodes resulting from search.
    node_list = search(destination_config['search_index'], destination_config['query'])

    # Add destination config for each node.
    node_list.each do |n|
      processed_config['type'] = 'node'
      processed_config['name'] = n.name
      processed_config['ip'] = n.ipaddress
    end

  end



  # Set number to keep
  processed_config['keep'] = destination_config['keep'] || node['backup']['client']['defaults']['keep']

  # Save the processed destination config to the list.
  processed_destinations[processed_config['name']] = processed_config

end


# For each processed destination...
processed_destinations.each do |name, config|

  # Add a namespaced destination to the node's default destinations,
  # namespaced with _backup_client.
  destination = {
    "description" => "Set automatically by backup::client recipe.",
    "type" => "SCP",
    "params" => {
      "ip" => "\"#{config['ip']}\"",
      "username" => "\"#{node['fqdn']}\"",
      "path" => "\"~/backups\"",
      "keep" => config['keep']
    }
  }

  node.set['backup']['defaults']['destinations']["_backup_client:#{name}"] = destination

end

# Remove defunct backup client destinations.
node['backup']['defaults']['destinations'].each do |name, destination|

  # If destination was set by this recipe...
  if name =~ /^_backup_client:(.*)$/

    # Delete the destination if it is not in the current destinations.
    if processed_destinations[$1].nil?
      node['backup']['defaults']['destinations'].delete(name)
    end

  end
end


