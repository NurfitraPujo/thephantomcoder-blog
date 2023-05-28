class Builders::Icon < SiteBuilder
  def build
    helper :icon
  end
  def icon(icon, classes = "", style: :solid, fixed: true, rotate: nil, flip: nil, size: nil, animate: nil, **attributes)
    classes << " fa-#{icon.to_s.gsub("_", "-")}"
    classes << " fa#{style.to_s[0].downcase}" # Solid/regular/thin/brands
    classes << " fa-fw" if fixed # Fixed-width
    classes << " fa-rotate-#{rotate}" if rotate
    classes << " fa-flip-#{flip}" if flip
    classes << " fa-#{size}" if size
    classes << " fa-#{animate.to_s.gsub("w", "-")}" if animate
    attributes["aria-hidden"] = "true"
    attributes["class"] = classes
    attributes = attributes.collect { |key, value| "#{key}=\"#{value}\"" }
    <<~ICON.strip.html_safe
      <i #{attributes.join(" ")}></i>
    ICON
  end
end
