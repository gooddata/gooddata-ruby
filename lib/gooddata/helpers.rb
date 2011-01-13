module GoodData::Helpers
  def home_directory
    running_on_windows? ? ENV['USERPROFILE'] : ENV['HOME']
  end

  def running_on_windows?
    RUBY_PLATFORM =~ /mswin32|mingw32/
  end

  def running_on_a_mac?
    RUBY_PLATFORM =~ /-darwin\d/
  end

  def error(msg)
    STDERR.puts(msg)
    exit 1
  end
end
