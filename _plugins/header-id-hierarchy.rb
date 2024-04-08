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

# Custom implementation of `parameterize` for strings
class String
  def parameterize(separator = '-')
    # Downcase, replace non-alphanumeric characters with the separator, and remove trailing separators
    downcase.gsub(/[^a-z0-9]+/i, separator).chomp(separator)
  end
end

Jekyll::Hooks.register [:pages, :documents], :post_render do |doc|
  current_hierarchy = {}
  header_id_map = {}

  # Update header IDs with hierarchical structure
  modified_content = doc.output.gsub(/<(h[1-6])(.*?)>(.*?)<\/\1>/) do |match|
    level = $1[1].to_i  # Extract the numerical level of the header
    content = $3.strip

    # Generate a URL-friendly ID from the header content
    sanitized_id = content.parameterize

    # Update the current hierarchy with the new ID, removing any levels above the current
    current_hierarchy = current_hierarchy.select { |k, _| k < level }
    current_hierarchy[level] = sanitized_id

    # Construct the hierarchical ID by concatenating parent IDs
    hierarchical_id = current_hierarchy.values.join("--")

    # Map original ID to new hierarchical ID for later link updates
    header_id_map[sanitized_id] = hierarchical_id

    # Reconstruct the header tag with the new hierarchical ID
    "<#{$1} id=\"#{hierarchical_id}\">#{content}</#{$1}>"
  end

  # Update links in the document to reflect the new hierarchical header IDs
  modified_content.gsub!(/<a href="#([^"]+)">/) do |link_match|
    original_id = $1
    if header_id_map.key?(original_id)
      # Replace link with updated hierarchical ID if it exists in the map
      link_match.sub("##{original_id}", "##{header_id_map[original_id]}")
    else
      # No change if the ID isn't in the header map
      link_match
    end
  end

  # Update the document's output with modified content
  doc.output = modified_content
end
