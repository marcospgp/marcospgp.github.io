# Hierarchical ID generator - written by ChatGPT
#
# Example:
#
# # Drinks          -> id="drinks"
# ## Coffee         -> id="drinks--coffee"
# ### Latte         -> id="drinks--coffee--latte"
# ### Espresso      -> id="drinks--coffee--espresso"
# ## Tea            -> id="drinks--tea"
#
# Also updates links, such as from table of contents:
#
# <a href="#coffee">Coffee</a>
# becomes:
# <a href="#drinks--coffee">Coffee</a>

module Jekyll
  module HierarchicalHeadersAndUpdateLinks

    # Function to create URL-friendly IDs
    def self.parameterize(str, separator = '-')
      str.downcase.gsub(/[^a-z0-9]+/i, separator).chomp(separator)
    end

    Jekyll::Hooks.register [:pages, :documents], :post_render do |doc|
      header_map = {}
      current_hierarchy = []

      # Generate hierarchical IDs and map based on 'href' values
      doc.output = doc.output.gsub(/<(h[1-6])(.*?)>(.*?)<\/\1>/) do |match|
        tag, _, content = $1, $2, $3.strip
        level = tag[1].to_i
        sanitized_id = HierarchicalHeadersAndUpdateLinks.parameterize(content)

        # Adjust hierarchy based on the current level
        current_hierarchy = current_hierarchy.slice(0, level - 1)
        current_hierarchy << sanitized_id

        hierarchical_id = current_hierarchy.join("--")

        # Map original 'href' value to the hierarchical ID
        header_map["#" + sanitized_id] = "#" + hierarchical_id

        # Return the modified header with the hierarchical ID
        "<#{tag} id=\"#{hierarchical_id}\">#{content}</#{tag}>"
      end

      # Update 'href' attributes in links using the map
      doc.output.gsub!(/<a href="#([^"]+)">/) do |link|
        original_href = "#" + $1
        if header_map.key?(original_href)
          link.sub(original_href, header_map[original_href])
        else
          link
        end
      end
    end
  end
end
