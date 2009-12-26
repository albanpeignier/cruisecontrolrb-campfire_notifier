require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'fileutils'

task :default => [:verify_gem, :test]

desc "verify broach gem is installed"
task :verify_gem do
  abort("broach gem not installed.  [sudo gem install broach]") unless Gem.available? 'broach'
  abort("mocha gem not installed.  [sudo gem install mocha]") unless Gem.available? 'mocha'
  abort("shoulda gem not installed.  [sudo gem install shoulda]") unless Gem.available? 'shoulda'
end

Rake::TestTask.new do |t|
  t.libs << "test"
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
