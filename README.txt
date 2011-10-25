= DESCRIPTION:

Recipes for a backup client/manager system.

Backup clients can create backups via the ruby backup gem, and then sync them to a backup manager.

= REQUIREMENTS:

= ATTRIBUTES:

Backup clients can configure individual backup jobs in attributes .  Job configurations look like this:

   "backup" {
     "jobs": {
        "some_job": {
          "description": "Description of some job."
          "database_tasks": {
            "phpmyadmin_db": {
              "name": "phpmyadmin",
              "type": "MySQL"
            }
          },
          "file_tasks": {
            "file_task_1": {
              "includes": ["/etc/cron.daily/"],
              "excludes": ["/etc/cron.daily/dpkg"]
            },
            "some_other_file_task": {
             "includes": [...],
             "excludes": [...]
            },
            ...
          },
          "destinations": {
            "some_destination": {
               "type": "RSync",
               "params": {
                 "username": "\"some_username\"",
                 "path": "\"~/backups\"",
                 "ip": "\"some hostname/ip\""
               }
            },
          }
        }
      }
        

More details on these attributes:

A job consists of several parameters.
 * description (optional): a human-readable description of the job, intended for sysadmin documentation.
 * database_tasks (optional): a set of database task configurations, where each database task configuration can have these parameters:
  * name: name of the database
  * type: type of the database
 * file_tasks (optional): a set of file tasks, where each task can have these parameters:
  * includes: a list of files or directories to include
  * excludes: a lit of files or directories to exclude
 * destinations: A set of destination configurations, where destinations can have these parameters:
  * type: just 'RSync' for now...perhaps add more later.
  * params: type-specific parameters.  (add documentation for parameters)

Note that destinations can also be set to 'defaults' (in which case it will read destinations from the node[:backup][:default_destinations] attribute), or {"from_databag": "some databag name"}.


The backup manager can be configured with these attributes:

[:backup][:manager][:backup_dir] = "/data/backups" # where to store backups on the backup manager.
[:backup][:manager][:client_search_index] = "node" # chef search index to search for clients for this manager
[:backup][:manager][:client_search_query] = 'run_list:recipe\[backup\]' # chef search query to search for clients for this manager

The client_search_index and client_search_query attributes allow for configurable selection of different sets of nodes.  For example, you may want to have abackup agent node that stores backups for nodes with a certain role, or which have specific recipes in their run lists.


= USAGE:

