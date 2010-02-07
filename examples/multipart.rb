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

# Parse a file
document = File.open("#{dir}/multipart.txt", "r") do |f|
  DocStorage::MultipartDocument.parse(f)
end

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
