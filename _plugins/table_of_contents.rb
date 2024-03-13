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

Jekyll::Hooks.register :documents, :post_render do |document|
  puts "Generating TOC for document: #{document.relative_path}"

  toc = "<ul>"
  headers_found = 0  # Counter to track the number of headers processed

  document.output.scan(/<(h[1-6])\s*id="([^"]+)"[^>]*>(.*?)<\/\1>/).each do |match|
    level, id, title = match
    indent = "  " * (level[1].to_i - 1)  # Adjust indentation based on header level
    toc << "<li class=\"toc-level-#{level[1]}\"><a href=\"##{id}\">#{title.strip}</a></li>"
    headers_found += 1
    puts "Found header: #{title.strip}, Level: #{level}, ID: #{id}"  # Debug log for each header
  end

  toc << "</ul>"

  if headers_found > 0
    document.data['table_of_contents'] = toc
    puts "TOC generated for #{document.relative_path} with #{headers_found} headers."
  else
    puts "No headers found for TOC in #{document.relative_path}."
  end
end
