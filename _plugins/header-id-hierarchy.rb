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

    Jekyll::Hooks.register [:pages, :documents], :post_render do |doc|
      header_map = {}
      current_hierarchy = []

      # Generate hierarchical IDs and map based on original 'href' values
      doc.output = doc.output.gsub(/<(h[1-6])(.*?)>(.*?)<\/\1>/) do |match|
        tag, attrs, content = $1, $2, $3.strip
        level = tag[1].to_i

        # Extract or generate an ID for the header
        id_match = attrs.match(/id="([^"]+)"/)
        original_id = id_match ? id_match[1] : content.parameterize

        # Adjust the hierarchy based on the current level and create the hierarchical ID
        current_hierarchy = current_hierarchy.slice(0, level - 1)
        current_hierarchy << original_id
        hierarchical_id = current_hierarchy.join("--")

        # Map the original ID (or the parameterized content if no ID is present) to the hierarchical ID
        header_map[original_id] = hierarchical_id

        # Return the modified header with the hierarchical ID
        "<#{tag} id=\"#{hierarchical_id}\">#{content}</#{tag}>"
      end

      # Update 'href' attributes in links using the map
      doc.output.gsub!(/<a href="#([^"]+)">/) do |link|
        original_href = $1

        # Use the original href to find the new hierarchical ID in the map
        new_id = header_map[original_href]

        new_id ? link.sub("##{original_href}", "##{new_id}") : link
      end
    end
  end
end
