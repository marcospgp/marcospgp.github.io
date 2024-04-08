# Hierarchical TOC Generator - Written by ChatGPT
#
# Usage in templates:
#
#   <article class="table-of-contents">
#     {% if page.table_of_contents != false %}
#       {{ page.table_of_contents | safe }}
#     {% endif %}
#   </article>
#
# The | safe filter in Liquid tells Jekyll that the TOC HTML is safe to render
# as-is, without escaping it.
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

Jekyll::Hooks.register [:pages, :documents], :pre_render do |doc|
  toc = "<ul>"
  headers_found = false

  doc.content.scan(/^(\#{1,6})\s+(.+)$/).each do |match|
    headers_found = true
    level, title = match
    header_level = level.length
    sanitized_title = title.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
    toc << "<li class=\"toc-level-#{header_level}\"><a href=\"##{sanitized_title}\">#{title}</a></li>\n"
  end

  toc << "</ul>"

  doc.data['table_of_contents'] = toc if headers_found
end
