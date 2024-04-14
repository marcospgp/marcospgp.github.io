# Written by ChatGPT.
#
# Turns every "<img>" element in pages & posts into a link that opens the image.

module Jekyll
  class LinkifyImages < Jekyll::Generator
    priority :low

    def generate(site)
      site.pages.each { |page| linkify_images_in(page) }
      site.posts.docs.each { |post| linkify_images_in(post) }
    end

    private

    def linkify_images_in(document)
      return if document.output.nil? || document.output.empty?

      # This regex finds img tags not already inside anchor tags
      regex = /(<img)/
      new_output = document.output.gsub(regex) do |img_tag|
        src = $2
        "<a href=\"#{src}\" target=\"_blank\">#{img_tag}</a>"
      end

      document.output = new_output
    end
  end
end
