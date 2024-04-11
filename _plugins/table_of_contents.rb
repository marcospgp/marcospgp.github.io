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
    def table_of_contents(content)
      toc = ""
      current_level = 1
      content.scan(/<(h[1-6]) id="([^"]+)">(.*?)<\/\1>/).each do |match|
        level, id, title = match[0][1].to_i, match[1], match[2].strip

        # Adjust TOC string based on header level changes
        case level <=> current_level
        when 1 # Moving down a level
          toc << "<ul>" * (level - current_level)
        when -1 # Moving up a level
          toc << "</li></ul>" * (current_level - level) + "</li>"
        else # Same level
          toc << "</li>" unless toc.empty?
        end

        # Add current header to TOC
        toc << "<li><a href=\"##{id}\">#{title}</a>"
        current_level = level
      end

      toc << "</li>" + "</ul></li>" * (current_level - 1) unless toc.empty?

      toc.empty? ? "" : "<article class=\"table-of-contents\"><ul>#{toc}</ul></article>"
    end
  end
end

Liquid::Template.register_filter(Jekyll::TocFilter)
