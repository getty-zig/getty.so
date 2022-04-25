module Jekyll
  class Lang < Liquid::Block
    def initialize(tagName, lang, tokens)
       super
       @lang = lang
    end

    def render(context)
      %Q{<div class="code-block"><div class="language-tag">#{@lang}</div><pre class="code-block-inner" lang="shell">#{super}</pre></div>}
    end
  end
end

Liquid::Template.register_tag('lang', Jekyll::Lang)
