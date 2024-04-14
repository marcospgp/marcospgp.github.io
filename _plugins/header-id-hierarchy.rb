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
#
# This was created for "notes.md", which contains many headers and where chances
# of overlap on links to specific headers increase.

module Jekyll
  module HierarchicalHeadersAndUpdateLinks

    Jekyll::Hooks.register [:pages, :documents], :post_render do |doc|
      header_map = {}
      current_hierarchy = []

      doc.output = doc.output.gsub(/<(h[1-6])(.*?)>(.*?)<\/\1>/) do |match|
        tag, attrs, content = $1, $2, $3.strip
        level = tag[1].to_i

        # Directly use existing ID or content as the original ID
        id_match = attrs.match(/id="([^"]+)"/)
        original_id = id_match ? id_match[1] : content

        # Update hierarchy and construct hierarchical ID
        current_hierarchy = current_hierarchy.slice(0, level - 1)
        current_hierarchy << original_id
        hierarchical_id = current_hierarchy.join("--")

        # Map original ID to hierarchical ID
        header_map[original_id] = hierarchical_id

        # Apply the hierarchical ID to the header
        "<#{tag} id=\"#{hierarchical_id}\">#{content}</#{tag}>"
      end

      # Update links to use hierarchical IDs
      doc.output.gsub!(/<a href="#([^"]+)">/) do |link|
        original_href = $1

        # Replace href with hierarchical ID if it exists in the map
        if header_map.key?(original_href)
          link.sub("##{original_href}", "##{header_map[original_href]}")
        else
          link
        end
      end
    end
  end
end
