# Written by ChatGPT.
#
# Turns every "<img>" element in pages & posts into a link that opens the image.

module Jekyll
  Jekyll::Hooks.register [:pages, :documents], :post_render do |document|
    content = document.output
    new_content = ''
    inside_anchor = false
    tag_depth = 0

    content.scan(/<[^>]+>|[^<]+/).each do |fragment|
      if fragment.start_with?('<')
        if fragment.start_with?('<a ')
          inside_anchor = true
          tag_depth += 1
        elsif fragment.start_with?('</a>')
          tag_depth -= 1
          inside_anchor = false if tag_depth == 0
        elsif fragment.start_with?('<img ') && !inside_anchor
          src_match = fragment.match(/src=['"]([^'"]*)['"]/)
          src = src_match[1] if src_match
          fragment = "<a href='#{src}' target='_blank'>#{fragment}</a>"
        end
      end

      new_content += fragment
    end

    document.output = new_content
  end
end
