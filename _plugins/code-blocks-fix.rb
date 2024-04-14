# Written by ChatGPT.
#
# Adds the "language-<language>" class from "<pre>" elements to any child
# "<code>" elements.
# This is needed because Jekyll/Kramdown/Rouge add the class to a "<div>" parent
# element when generating code blocks, but highlight.js looks for the class in
# the "<code>" element - and if it's not there, auto detects the language.

module Jekyll
  module TransferLanguageClass
    Jekyll::Hooks.register [:pages, :documents], :post_render do |doc|
      # We'll add a temporary marker to each div with a language class to help identify the current language context.
      nested_language = nil
      doc.output = doc.output.gsub(/<div[^>]*class="([^"]*)"/) do |div_tag|
        # Check if the div has a language class and capture it
        match = div_tag.match(/language-[\w-]+/)
        nested_language = match ? match[0] : nested_language

        # Include the language as a data attribute if found
        if nested_language
          "#{div_tag} data-language=\"#{nested_language}\""
        else
          div_tag
        end
      end

      # Now, adjust the <code> tags within these divs
      doc.output.gsub!(/<code( class="([^"]*)")?/) do |code_tag|
        existing_classes = $2
        if nested_language
          existing_classes = existing_classes ? "#{existing_classes} #{nested_language}" : nested_language
          "<code class=\"#{existing_classes}\""
        else
          code_tag
        end
      end

      # Remove the temporary data attributes to clean up
      doc.output.gsub!(/ data-language="[^"]*"/, '')
    end
  end
end
