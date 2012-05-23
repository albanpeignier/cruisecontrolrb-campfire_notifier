require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'fileutils'

task :default => [:verify_gem, :test]

desc "verify broach gem is installed"
task :verify_gem do
  ((msg = `bundle check`) && $? == 0) || abort(msg)
end

Rake::TestTask.new do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
  t.verbose = true
end

begin
  require 'rubygems'
  require 'rcov/rcovtask'

  Rcov::RcovTask.new do |t|
    t.libs << "test"
    t.test_files = FileList['test/**/*_test.rb']
    t.verbose = true
    t.rcov_opts = %w{--exclude / --include-file ^lib}
  end
rescue LoadError
  puts "Can't load rcov, please install rcov gem"
end
