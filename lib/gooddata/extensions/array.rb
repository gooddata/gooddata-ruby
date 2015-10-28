class Array
  # Converts an array into a string suitable for use as a URL query string, using the given key as the param name.
  def to_query(key)
    prefix = "#{key}[]"

    if empty?
      nil.to_query(prefix)
    else
      collect { |value| value.to_query(prefix) }.join '&'
    end
  end

  # Calls to_param on all its elements and joins the result with slashes.
  # This is used by url_for in Action Pack.
  def to_param
    collect(&:to_param).join('/')
  end
end
