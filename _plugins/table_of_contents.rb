# Hierarchical TOC Generator - Written by ChatGPT
#
# Usage in layouts:
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
    HeaderNode = Struct.new(:title, :id, :children, :level, :parent)

    # Add a class level variable for max depth
    @@max_depth = 3  # Set default max depth

    # Method to change the maximum depth
    def self.max_depth=(depth)
      @@max_depth = depth
    end

    def table_of_contents(content)
      root = HeaderNode.new("root", "", [], 0, nil)
      last_node = root

      content.scan(/<(h[1-6]) id="([^"]+)">(.*?)<\/\1>/).each do |match|
        level = match[0][1].to_i
        # Skip headers that exceed the max depth
        next if level > @@max_depth

        node = HeaderNode.new(match[2].strip, match[1], [], level, nil)

        # Find the appropriate parent for the current node
        while last_node.level >= level
          last_node = last_node.parent
        end

        last_node.children << node
        node.parent = last_node
        last_node = node
      end

      html = generate_html(root)
      html.empty? ? "" : "<article class=\"table-of-contents\">#{html}</article>"
    end

    private

    def generate_html(node)
      return "" if node.children.empty? || node.level >= @@max_depth

      html = "<ul>"
      node.children.each do |child|
        html += "<li><a href=\"##{child.id}\">#{child.title}</a>"
        html += generate_html(child)
        html += "</li>"
      end
      html += "</ul>"

      html
    end
  end
end

Liquid::Template.register_filter(Jekyll::TocFilter)
