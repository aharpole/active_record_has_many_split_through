begin
  require "bundler/gem_tasks"
rescue TypeError, NameError
  # Probably using gel
end

require "rake/testtask"
require "yaml"
require "erb"
require "active_record"

Rake::TestTask.new(:test_with_split) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task :default => :test
task :test => [:test_with_split, :test_without_split]

task :test_without_split do
  puts "RUNNINNG WITHOUT SPLIT"
  sh "NO_SPLIT=1 rake test_with_split"
end

namespace :db do
  task :create do
    yaml_file = File.open('config/database.yml')
    config_file = YAML.load(ERB.new(yaml_file.read).result)

    config_file["default_env"].each do |spec_name, config|
      ActiveRecord::Tasks::DatabaseTasks.create(config)
    end
  end

  task :drop do
    yaml_file = File.open('config/database.yml')
    config_file = YAML.load(ERB.new(yaml_file.read).result)

    config_file["default_env"].each do |spec_name, config|
      ActiveRecord::Tasks::DatabaseTasks.drop(config)
    end
  end
end
