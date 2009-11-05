require "rake"
require "rake/rdoctask"
require "spec/rake/spectask"

Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*.rb']
end

Rake::RDocTask.new do |t|
  t.main = "README.rdoc"
  t.rdoc_dir = "doc"
  t.rdoc_files.add("README.rdoc", "lib/**/*.rb")
end
