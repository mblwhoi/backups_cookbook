def initialize(*args)
  super
  @action = :create
end

actions :create, :delete

attribute :name, :kind_of => String, :name_attribute => true, :required => true
attribute :description, :kind_of => String
attribute :destinations
attribute :file_tasks
attribute :database_tasks
attribute :frequency
