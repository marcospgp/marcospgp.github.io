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

    # Define 'parameterize' as a module function
    def self.parameterize(str, separator = '-')
      str.downcase.gsub(/[^a-z0-9]+/i, separator).chomp(separator)
    end

    # Define a function to strip HTML tags
    def self.strip_html_tags(str)
      str.gsub(/<\/?[^>]*>/, "")
    end

    Jekyll::Hooks.register [:pages, :documents], :post_render do |doc|
      header_map = {}
      current_hierarchy = []

      doc.output = doc.output.gsub(/<(h[1-6])(.*?)>(.*?)<\/\1>/) do |match|
        tag, attrs, content = $1, $2, $3.strip

        # Strip HTML from the header content before processing
        plain_text_content = HierarchicalHeadersAndUpdateLinks.strip_html_tags(content)

        level = tag[1].to_i
        sanitized_id = HierarchicalHeadersAndUpdateLinks.parameterize(plain_text_content)
        current_hierarchy = current_hierarchy.slice(0, level - 1)
        current_hierarchy[level - 1] = sanitized_id

        hierarchical_id = current_hierarchy.join("--")

        header_map[sanitized_id] = hierarchical_id

        "<#{tag} id=\"#{hierarchical_id}\">#{plain_text_content}</#{tag}>"
      end

      doc.output.gsub!(/<a href="#([^"]+)">/) do |link|
        original_id = HierarchicalHeadersAndUpdateLinks.parameterize($1)
        if header_map.key?(original_id)
          link.sub("##{original_id}", "##{header_map[original_id]}")
        else
          link
        end
      end
    end
  end
end
