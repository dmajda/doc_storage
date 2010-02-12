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

# Load from a file
document = DocStorage::SimpleDocument.load_file("examples/simple.txt")

# Document manipulation
document.headers["Tags"] = "example"
document.body += "Nulla mi dui, pellentesque et accumsan vitae, mattis et velit."

# Save the modified document
document.save_file("#{dir}/simple_modified.txt")
