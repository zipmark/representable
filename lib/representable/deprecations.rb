module Representable::Deprecations
  def skip_excluded_property?(binding, options) # TODO: remove with 1.2.
    if options[:except]
      options[:exclude] = options[:except]
      warn "The :except option is deprecated and will be removed in 1.2. Please use :exclude."
    end # i wanted a one-liner but failed :)
    super
  end
end
