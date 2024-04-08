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
    # Custom implementation of `parameterize` for strings
    def parameterize(str, separator = '-')
      str.downcase.gsub(/[^a-z0-9]+/i, separator).chomp(separator)
    end

    # Method to generate hierarchical IDs for headers
    def generate_hierarchical_id(header_content, hierarchy)
      sanitized_id = parameterize(header_content)
      hierarchy.join("--") + "--#{sanitized_id}"
    end

    # Method to generate the table of contents (TOC) from the document's content
    def table_of_contents(content)
      toc = ""
      headers_found = false
      hierarchy = []

      # Regex to match Markdown headers
      content.scan(/^(\#{1,6})\s+(.+)$/).each do |match|
        headers_found = true
        level, title = match
        header_level = level.length

        # Update the hierarchy based on the current header level
        hierarchy = hierarchy[0, header_level - 1]
        hierarchy << parameterize(title)

        # Generate the hierarchical ID for the header
        hierarchical_id = generate_hierarchical_id(title, hierarchy)

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
