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
  Jekyll::Hooks.register [:pages, :documents], :post_render do |document|
    content = document.output
    new_content = ''
    inside_anchor = false
    tag_depth = 0

    content.scan(/<[^>]+>|[^<]+/).each do |fragment|
      if fragment.start_with?('<')
        if fragment.start_with?('<a ')
          inside_anchor = true
          tag_depth += 1
        elsif fragment.start_with?('</a>')
          tag_depth -= 1
          inside_anchor = false if tag_depth == 0
        elsif fragment.start_with?('<img ') && !inside_anchor
          src_match = fragment.match(/src=['"]([^'"]*)['"]/)
          src = src_match[1] if src_match
          fragment = "<a href='#{src}' target='_blank'>#{fragment}</a>"
        end
      end

      new_content += fragment
    end

    document.output = new_content
  end
end
