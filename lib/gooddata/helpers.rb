module GoodData::Helpers
  def self.home_directory
    running_on_windows? ? ENV['USERPROFILE'] : ENV['HOME']
  end

  def self.running_on_windows?
    RUBY_PLATFORM =~ /mswin32|mingw32/
  end

  def self.running_on_a_mac?
    RUBY_PLATFORM =~ /-darwin\d/
  end

  def self.error(msg)
    STDERR.puts(msg)
    exit 1
  end

  def self.find_goodfile(pwd, options={})
    root = Pathname(options[:root] || '/' )
    pwd = Pathname(pwd).expand_path
    begin
       gf = pwd + "Goodfile"
       if gf.exist?
         return gf
       end
       pwd = pwd.parent
    end until root == pwd
    fail "Goodfile not found in #{pwd.to_s} or any parent up to #{root.to_s}"
  end

  def self.hash_dfs(thing, &block)
    if !thing.is_a?(Hash) && !thing.is_a?(Array)
    elsif thing.is_a?(Array)
      thing.each do |child|
        hash_dfs(child, &block)
      end
    else
      thing.each do |key, val|
        yield(thing, key)
        hash_dfs(val, &block)
      end
    end
  end
end
