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

class String
  def parameterize(separator = '-')
    downcase.gsub(/[^a-z0-9]+/i, separator).chomp(separator)
  end
end

Jekyll::Hooks.register [:pages, :documents], :post_render do |doc|
  current_hierarchy = {}
  header_id_map = {}

  # Update header IDs with hierarchical structure
  modified_content = doc.output.gsub(/<(h[1-6])(.*?)>(.*?)<\/\1>/) do |match|
    level = $1[1].to_i
    content = $3.strip
    sanitized_id = content.parameterize

    current_hierarchy = current_hierarchy.select { |k, _| k < level }
    current_hierarchy[level] = sanitized_id

    hierarchical_id = current_hierarchy.values.join("--")

    # Map both original and sanitized IDs to the new hierarchical ID
    header_id_map[content] = hierarchical_id
    header_id_map[sanitized_id] = hierarchical_id

    "<#{$1} id=\"#{hierarchical_id}\">#{content}</#{$1}>"
  end

  # Update links to reflect the new hierarchical header IDs
  modified_content.gsub!(/<a href="#([^"]+)">/) do |link_match|
    original_id = $1

    # Attempt to find a direct match or a parameterized match in the header ID map
    new_id = header_id_map[original_id] || header_id_map[original_id.parameterize]

    if new_id
      link_match.sub("##{original_id}", "##{new_id}")
    else
      link_match
    end
  end

  # Update the document's output with modified content
  doc.output = modified_content
end
