#
# Cookbook Name:: backup
# Attributes:: backup
#

default[:backup][:configs_dir] = "/data/backup_jobs"

default[:backup][:jobs] = {}

# defaults:destinations is set programmatically.
default[:backup][:defaults][:destinations] = {}

default[:backup][:defaults][:frequency] = ["daily"]

# client:default_destinations is typically set in node or role attributes.
default[:backup][:client][:default_destinations] = []
default[:backup][:client][:defaults][:keep] = 5

default[:backup][:manager][:backup_dir] = "/data/backups"
default[:backup][:manager][:client_search_index] = "node"
default[:backup][:manager][:client_search_query] = 'recipes:backup\:\:client'
