require "rake/gempackagetask"
require "rake/rdoctask"
require "spec/rake/spectask"

Spec::Rake::SpecTask.new do |t|
  t.spec_opts = ["--color", "--format", "nested"]
end

Rake::RDocTask.new do |t|
  t.main = "README.rdoc"
  t.rdoc_dir = "doc"
  t.rdoc_files.add("README.rdoc", "lib/**/*.rb")
end

specification = Gem::Specification.new do |s|
  s.name = "doc_storage"
  s.version = "0.9"
  s.summary = "Simple Ruby library for manipulating documents containing a " +
              "text and metadata."
  s.description = "DocStorage is a simple Ruby library for manipulating " +
                  "documents containing a text and metadata. These documents " +
                  "can be used to implement a blog, wiki, or similar " +
                  "application without a relational database."
  s.required_ruby_version = ">= 1.8.6"

  s.author = "David Majda"
  s.email = "david@majda.cz"
  s.homepage = "http://github.com/dmajda/doc_storage"

  s.files = FileList[
              "Rakefile",
              "README.rdoc",
              "LICENSE",
              "VERSION",
              Dir["lib/**/*.rb"],
              Dir["spec/**/*.rb"],
              Dir["examples/**/*"]
            ]

  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc"]
  s.rdoc_options = ["--main", "README.rdoc"]
end

Rake::GemPackageTask.new(specification) do |t|
end
