base = Pathname(__FILE__).dirname.expand_path
Dir.glob(base + '*_middleware.*').each do | file |
  require file
end
