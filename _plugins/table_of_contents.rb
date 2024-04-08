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

      content.scan(/<(h[1-6])[^>]*>(.*?)<\/\1>/).each do |match|
        headers_found = true
        level = match[0][1].to_i
        title = match[1].strip
        sanitized_id = parameterize(title)

        # Update the hierarchy based on the current header level
        if level == 1
          hierarchy = [sanitized_id]
        elsif level > hierarchy.length
          hierarchy << sanitized_id
        else
          hierarchy = hierarchy[0, level - 1]
          hierarchy[-1] = sanitized_id
        end

        # Generate the hierarchical ID for the header
        hierarchical_id = hierarchy.join("--")

        # Indent the TOC entry based on the hierarchy level
        toc << "<li><a href=\"##{hierarchical_id}\">#{title}</a><ul>" if level > 1
        toc << "<li><a href=\"##{hierarchical_id}\">#{title}</a></li>" if level == 1
        toc << "</ul></li>" if level < 6
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
