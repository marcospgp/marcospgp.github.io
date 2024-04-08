# Hierarchical TOC Generator - Written by ChatGPT
#
# Usage in templates:
#
#   <article class="table-of-contents">
#     {% if page.table_of_contents != false %}
#       {{ content | table_of_contents | safe }}
#     {% endif %}
#   </article>
#
# The "safe" filter tells Jekyll that the TOC HTML is safe to render without
# escaping.

module Jekyll
  module TocFilter
    def table_of_contents(input)
      toc = "<ul>"
      headers_found = false

      input.scan(/^(\#{1,6})\s+(.+)$/).each do |match|
        headers_found = true
        level, title = match
        header_level = level.length
        sanitized_title = title.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')
        toc << "<li class=\"toc-level-#{header_level}\"><a href=\"##{sanitized_title}\">#{title}</a></li>\n"
      end

      toc << "</ul>"

      if headers_found
        toc
      else
        "No headers found for TOC."
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::TocFilter)
