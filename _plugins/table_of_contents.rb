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

      # Regex to match HTML headers
      content.scan(/<(h[2-6])(.*?)>(.*?)<\/\1>/).each do |match|
        headers_found = true
        tag, _, title = match
        header_level = tag[1].to_i

        # Update the hierarchy based on the current header level
        hierarchy = hierarchy[0, header_level - 2]  # Adjust to exclude h1
        hierarchical_id = generate_hierarchical_id(title, hierarchy)

        # Construct the hierarchical structure for the TOC
        toc << "<li><a href=\"##{hierarchical_id}\">#{title}</a>"
        toc << "<ul>" if header_level < 6  # Add sub-list if not h6
        toc << "</li>\n"
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
