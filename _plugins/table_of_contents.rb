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

module Jekyll
  class HierarchicalTOCGenerator < Generator
    priority :low

    def generate(site)
      site.documents.each do |doc|
        doc.data['table_of_contents'] = build_toc(doc.output)
      end
    end

    private

    def build_toc(html_content)
      toc = '<ul>'
      html_content.scan(/<(h[1-6])\s*id="([^"]+)"[^>]*>(.*?)<\/\1>/).each do |match|
        level, id, title = match
        toc << "<li class=\"toc-level-#{level[1]}\"><a href=\"##{id}\">#{title.strip}</a></li>"
      end
      toc << '</ul>'
      toc
    end
  end
end
