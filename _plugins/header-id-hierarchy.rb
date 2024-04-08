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
    class String
      def parameterize(separator = '-')
        downcase.gsub(/[^a-z0-9]+/i, separator).chomp(separator)
      end
    end

    Jekyll::Hooks.register [:pages, :documents], :post_render do |doc|
      header_map = {}
      current_hierarchy = []

      # Step 1: Convert all header IDs and build a map to use later
      doc.output = doc.output.gsub(/<(h[1-6])(.*?)>(.*?)<\/\1>/) do |match|
        tag, attrs, content = $1, $2, $3.strip
        level = tag[1].to_i

        sanitized_id = content.parameterize
        current_hierarchy = current_hierarchy.slice(0, level - 1)
        current_hierarchy[level - 1] = sanitized_id

        hierarchical_id = current_hierarchy.join("--")

        header_map[sanitized_id] = hierarchical_id

        "<#{tag} id=\"#{hierarchical_id}\">#{content}</#{tag}>"
      end

      # Step 2: Update all links using the map created earlier
      doc.output.gsub!(/<a href="#([^"]+)">/) do |link|
        original_id = $1.parameterize
        if header_map.key?(original_id)
          link.sub("##{original_id}", "##{header_map[original_id]}")
        else
          link
        end
      end
    end
  end
end
