# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/test_*.rb"]
end

require "standard/rake"

task default: %i[test standard]

task :run do
  $LOAD_PATH << "lib"
  require "concurrent"
  require "kuiq/admin_ui"
  AdminUI.launch
end
