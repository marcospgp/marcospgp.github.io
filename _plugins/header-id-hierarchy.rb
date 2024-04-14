# Hierarchical ID generator - written by ChatGPT
#
# Example:
#
# # Drinks          -> id="drinks"
# ## Coffee         -> id="drinks--coffee"
# ### Latte         -> id="drinks--coffee--latte"
# ### Espresso      -> id="drinks--coffee--espresso"
# ## Tea            -> id="drinks--tea"
#
# Also updates links, such as from table of contents:
#
# <a href="#coffee">Coffee</a>
# becomes:
# <a href="#drinks--coffee">Coffee</a>
#
# This was created for "notes.md", which contains many headers and where chances
# of overlap on links to specific headers increase.

module Jekyll
  Jekyll::Hooks.register [:pages, :documents], :post_render do |document|
    content = document.output

    # Simplified parser to build a tree structure
    def build_tree(html)
      tree = { tag: :root, children: [] }
      current_node = tree

      html.scan(/<(\w+)|<\/(\w+)>|([^<>]+)/) do |open_tag, close_tag, text|
        if open_tag
          new_node = { tag: open_tag.to_sym, children: [], parent: current_node }
          current_node[:children] << new_node
          current_node = new_node
        elsif close_tag
          current_node = current_node[:parent]
        elsif text.strip != ''
          current_node[:children] << { tag: :text, content: text }
        end
      end

      tree
    end

    # Traverser that ignores <a> tags and processes <img> tags
    def process_tree(node)
      return if node[:tag] == :a

      node[:children].each do |child|
        if child[:tag] == :img
          src = child[:attributes][:src]
          child[:parent][:children] << { tag: :a, attributes: { href: src, target: '_blank' }, children: [child] }
          child[:parent][:children].delete(child)
        else
          process_tree(child) if child[:children]
        end
      end
    end

    tree = build_tree(content)
    process_tree(tree)

    # Render tree back to HTML
    document.output = render_html(tree)
  end

  def render_html(node)
    # Simplified rendering of the tree back to HTML
    html = ''
    node[:children].each do |child|
      if child[:tag] == :text
        html += child[:content]
      else
        inner_html = render_html(child)
        html += "<#{child[:tag]} #{child[:attributes].map{|k,v| "#{k}='#{v}'"}.join(' ')}>#{inner_html}</#{child[:tag]}>"
      end
    end
    html
  end
end
