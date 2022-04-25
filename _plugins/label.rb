module Jekyll
  class Label < Liquid::Block
    def initialize(tagName, markup, tokens)
       super
       @markup = markup.strip
    end

    def render(context)
      %Q{<div class="code-block"><div class="language-tag">#{@markup}</div><pre class="code-block-inner">#{super}</pre></div>}
    end
  end
end

Liquid::Template.register_tag('label', Jekyll::Label)
