# Hierarchical TOC Generator - Written by ChatGPT
# Sets 'table_of_contents' variable for Jekyll documents with the Markdown-formatted TOC.
# The 'table_of_contents' variable is accessible in templates, and its display is controlled by front matter.
#
# Usage in templates:
#
#   <article class="table-of-contents">
#     {% if page.table_of_contents != false %}
#       {{ page.table_of_contents | markdownify }}
#     {% endif %}
#   </article>
#
# Example TOC structure for a document with the following headers:
#
#   # Drinks          -> id="drinks"
#   ## Coffee         -> id="drinks--coffee"
#   ### Latte         -> id="drinks--coffee--latte"
#   ### Espresso      -> id="drinks--coffee--espresso"
#   ## Tea            -> id="drinks--tea"
#
# Would result in a TOC like:
#
#   - [Drinks](#drinks)
#     - [Coffee](#drinks--coffee)
#       - [Latte](#drinks--coffee--latte)
#       - [Espresso](#drinks--coffee--espresso)
#     - [Tea](#drinks--tea)

Jekyll::Hooks.register [:pages, :posts, :documents], :pre_render do |doc|
  toc = "<ul>"
  headers_found = 0

  # Regex to match Markdown headers based on the number of '#' characters
  # This will capture the header level and the header text
  doc.content.scan(/^(\#{1,6})\s+(.+)$/).each do |match|
    level, title = match
    header_level = level.length  # Determine header level from number of '#' characters
    sanitized_title = title.gsub(/[^\w\s-]/, '').strip.downcase.gsub(/\s+/, '-')  # Basic sanitization and slugification

    toc << "<li class=\"toc-level-#{header_level}\"><a href=\"##{sanitized_title}\">#{title.strip}</a></li>\n"
    headers_found += 1
  end

  toc << "</ul>"

  # Only set the TOC data if headers were found
  if headers_found > 0
    doc.data['table_of_contents'] = toc
  end
end
