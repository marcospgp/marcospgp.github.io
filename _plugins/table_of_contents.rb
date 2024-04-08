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
      toc = ""
      headers_found = false
      prev_level = 0  # Track the previous header level

      # Regex to match HTML headers
      input.scan(/<(h[1-6])\s*id="([^"]+)"[^>]*>(.*?)<\/\1>/).each do |match|
        headers_found = true
        level, id, title = match
        header_level = level[1].to_i
        sanitized_title = title.downcase.strip.gsub(' ', '-').gsub(/[^\w-]/, '')

        # Adjust indentation based on header hierarchy
        if header_level > prev_level
          toc << "<ul>"
        elsif header_level < prev_level
          toc << "</ul></li>" * (prev_level - header_level)
        end

        toc << "<li><a href=\"##{sanitized_title}\">#{title}</a>"

        prev_level = header_level
      end

      # Close any remaining open list items and lists
      toc << "</li></ul>" * prev_level

      if headers_found
        toc
      else
        "No headers found for TOC."
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::TocFilter)
