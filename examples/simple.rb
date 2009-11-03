dir = File.dirname(__FILE__)

require "#{dir}/../lib/doc_storage"

# Create a new document with headers and body
document = DocStorage::SimpleDocument.new(
  {
    "Title"    => "Finishing the documentation",
    "Priority" => "urgent"
  },
  "We should finish the documentation ASAP."
)

# Parse a file
document = File.open("#{dir}/simple.txt", "r") do |f|
  DocStorage::SimpleDocument.parse(f)
end

# Document manipulation
document.headers["Tags"] = "example"
document.body += "Nulla mi dui, pellentesque et accumsan vitae, mattis et velit."

# Save the modified document
File.open("#{dir}/simple_modified.txt", "w") do |f|
  f.write(document)
end
