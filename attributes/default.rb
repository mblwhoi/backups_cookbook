#
# Cookbook Name:: backup
# Attributes:: backup
#

default[:backup][:configs_dir] = "/data/backup_jobs"

default[:backup][:jobs] = {}

default[:backup][:defaults][:destinations] = {}
default[:backup][:defaults][:frequency] = ["daily"]

default[:backup][:client][:storage_destinations] = []
default[:backup][:client][:defaults][:keep] = 1

default[:backup][:manager][:backup_dir] = "/data/backups"
default[:backup][:manager][:client_search_index] = "node"
default[:backup][:manager][:client_search_query] = 'run_list:recipe\[backup::client\]'
