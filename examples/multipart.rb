dir = File.dirname(__FILE__)

require "#{dir}/../lib/doc_storage"

# Create a new document with two parts
document = DocStorage::MultipartDocument.new([
  DocStorage::SimpleDocument.new(
    {
      "Title"    => "Finishing the documentation",
      "Priority" => "urgent"
    },
    "We should finish the documentation ASAP."
  ),
  DocStorage::SimpleDocument.new(
    {
      "Title"    => "Finishing the code",
      "Priority" => "more urgent"
    },
    "But we should finish the code first!"
  ),
])

# Load from a file
document = DocStorage::MultipartDocument.load_file("examples/multipart.txt")

# Document manipulation
document.parts << DocStorage::SimpleDocument.new(
  {
    "Author"   => "Middle man",
    "Datetime" => "2009-11-01 21:15:33",
  },
  "I think your article is neither good nor bad."
)

# Save the modified document
File.open("#{dir}/multipart_modified.txt", "w") do |f|
  f.write(document)
end
