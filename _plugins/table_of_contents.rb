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
    def parameterize(str, separator = '-')
      str.downcase.gsub(/[^a-z0-9]+/i, separator).chomp(separator)
    end

    def table_of_contents(content)
      toc = ""
      headers_found = false
      hierarchy = []

      content.scan(/<(h[2-6])[^>]*>(.*?)<\/\1>/).each do |match|
        headers_found = true
        level = match[0][1].to_i
        title = match[1].strip
        sanitized_id = parameterize(title)

        # Update the hierarchy based on the current header level
        if level == 2
          hierarchy = []
        elsif level > hierarchy.length + 2
          hierarchy = hierarchy[0, level - 2]
        end
        hierarchy << sanitized_id

        # Generate the hierarchical ID for the header
        hierarchical_id = hierarchy.join("--")

        # Append the TOC entry for the header
        toc << "<li><a href=\"##{hierarchical_id}\">#{title}</a></li>\n"
      end

      if headers_found
        "<article class=\"table-of-contents\"><ul>#{toc}</ul></article>"
      else
        "No headers found for TOC."
      end
    end
  end
end

Liquid::Template.register_filter(Jekyll::TocFilter)
