# Helper functions #

# get job file name
def _backup_job_get_job_file_name(job_name)
  return "#{node['backup']['configs_dir']}/#{job_name}"
end

# get whenever job name.
def _backup_job_get_whenever_job_name(job_name)
  return "_backup_#{job_name}"
end


# Build backup job object and set node attributes.
action :create do

  # Initialize backup job object.
  job = {}

  # Set name.
  job["name"] = new_resource.name

  # Set description
  job["description"] = new_resource.description

  # Set file tasks.
  job["file_tasks"] = new_resource.file_tasks

  # Set database tasks.
  job["database_tasks"] = new_resource.database_tasks

  # Set destinations.
  job["destinations"] = new_resource.destinations

  # Set frequency.
  job["frequency"] = new_resource.frequency


  # Update node's backup attributes with job object, keyed by job name.
  # We do this here to preserve attributes as they were set originally, before
  # jobs are processed.
  node.set['backup']['jobs'][job['name']] = job

  # Initialize destinations object.
  destinations = {}

  # Set defaults.
  job["destinations"] ||= "default"

  # If destinations is 'default', use node defaults.
  if job["destinations"] == 'default'
    destinations = node["backup"]["defaults"]["destinations"].to_hash
    
  # Otherwise if destinations has the key 'from_databag', get destinations from a databag.
  elsif job["destinations"].has_key?('from_databag')
    bag_name = job["destinations"]["from_databag"]
    bag = data_bag(job["destinations"]["from_databag"])
    
    bag.each do |item_name|
      item = data_bag_item(bag_name, item_name)
      destinations[item_name] = item
    end
    
  # Otherwise get destinations from inline definitions.
  else
    destinations = job["destinations"].to_hash
  end


  # Overwrite job destinations with processed destinations.
  job["destinations"] = destinations

  # If no frequency is set, use node defaults.
  if ! job['frequency']
    job['frequency'] = node["backup"]["defaults"]["frequency"]
  end

  # Path to backup job file that will be written or updated.
  job_file = _backup_job_get_job_file_name(job['name'])

  # Write the job file.
  template job_file do
    cookbook "backup"
    source "backup_job.erb"
    owner "root"
    group "root"
    mode "0750"
    variables(:job_name => job['name'], :job => job)
    action :create
  end

  # Create whenever jobs.  Job ids are prefixed w/ '_backup_#{job_name}_'.
  job['frequency'].each do |f|

    # Make frequency hashes for frequency keywords.
    if f.class == String
      if f == 'daily'
        f = {"every" => "1 day"}
      elsif f == 'weekly'
        f = {"every" => "1 week"}
      elsif f == 'monthly'
        f = {"every" => "1 month"}
      end
    end
    
    
    # Make whenever job from frequency hash
    whenever_job_name = _backup_job_get_whenever_job_name(job['name'])
    whenever_job "#{whenever_job_name}" do
      every f['every']
      at f['at'] || "4:20am"
      user 'root'
      command "backup perform --trigger '#{job['name']}' --config-file '#{job_file}'"
      action :create
    end

  end

end


# Remove backup job.
action :delete do

  # Remove corresponding whenever job.
  whenever_job_name = _backup_job_get_whenever_job_name(new_resource.name)
  whenever_job "#{whenever_job_name}" do
    action :delete
  end
  
  # Remove job file.
  job_file = _backup_job_get_job_file_name(new_resource.name)
  execute "remove defunct backup job file '#{new_resource.name}'" do      
    command "rm -f '#{job_file}'"
  end    

  # Remove attribute.
  if ! node['backup']['jobs'][new_resource.name].nil?
    node['backup']['jobs'].delete(new_resource.name)
  end


end

