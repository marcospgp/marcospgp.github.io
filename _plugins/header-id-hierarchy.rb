module Jekyll
  class HierarchicalIdGenerator < Jekyll::Generator
    def generate(site)
      site.documents.each do |doc|
        current_hierarchy = {}

        modified_content = doc.output.gsub(/<(h[1-6])(.*?)>(.*?)<\/\1>/) do |match|
          level = $1[1].to_i  # Extract the numerical level of the header, e.g., 1 for h1
          attrs = $2
          content = $3.strip

          # Generate an ID for the current header based on its content
          new_id = content.parameterize

          # Update the current hierarchy with the new ID, removing any levels above the current
          current_hierarchy = current_hierarchy.select { |k, _| k < level }
          current_hierarchy[level] = new_id

          # Construct the hierarchical ID by concatenating parent IDs
          hierarchical_id = current_hierarchy.values.join("--")

          # Reconstruct the header tag with the new hierarchical ID
          "<#{$1} id=\"#{hierarchical_id}\">#{content}</#{$1}>"
        end

        # Update the document's output with modified content
        doc.output = modified_content
      end
    end
  end
end
