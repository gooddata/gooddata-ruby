def init
  super
  sections :header, [:method_signature, T('docstring'), :source, :specs]
end

def source
  return if owner != object.namespace
  return if Tags::OverloadTag === object
  return if object.source.nil?
  erb(:source)
end
