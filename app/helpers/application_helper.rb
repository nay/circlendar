module ApplicationHelper
  def format_with_links(text)
    return "" if text.blank?

    # URLを自動リンク化（target="_blank"付き）
    url_regex = %r{(https?://[^\s<]+)}
    linked_text = h(text).gsub(url_regex) do |url|
      %(<a href="#{url}" target="_blank" rel="noopener noreferrer" class="text-blue-600 hover:text-blue-800 underline">#{url}</a>)
    end

    simple_format(linked_text, {}, sanitize: false)
  end
end
