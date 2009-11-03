require "rake"
require "rake/rdoctask"
require "spec/rake/spectask"

desc "Run tests"
Spec::Rake::SpecTask.new("test") do |t|
  t.spec_files = FileList['spec/**/*.rb']
end

desc "Generate documentation"
Rake::RDocTask.new do |t|
  t.main = "README.rdoc"
  t.rdoc_dir = "doc"
  t.rdoc_files.add("README.rdoc", "lib/**/*.rb")
end
