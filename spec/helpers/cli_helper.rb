# encoding: UTF-8

require 'gooddata/cli/cli'

module CliHelper
  # Execute block and capture its stdou
  # @param block Block to be executed with stdout redirected
  # @returns Captured output as string
  def capture_stdout(&block)
    original_stdout = $stdout
    original_stderr = $stderr
    $stdout = $stderr = StringIO.new

    begin
      yield
      $stdout.string
    ensure
      $stdout = original_stdout
      $stderr = original_stderr
    end
  end

  # Run CLI with arguments and return captured stdout
  # @param args Arguments
  # @return Captured stdout
  def run_cli(args = [])
    old = $0
    $0 = 'gooddata'
    res = capture_stdout { GoodData::CLI.main(args) }
    $0 = old
    res
  end
end
