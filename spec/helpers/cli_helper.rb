# encoding: UTF-8

require 'gooddata/cli/cli'

module CliHelper
  # Execute block and capture its stdou
  # @param block Block to be executed with stdout redirected
  # @returns Captured output as string
  def capture_stdout(&block)
    original_stdout = $stdout
    $stdout = fake = StringIO.new
    begin
      yield
    ensure
      $stdout = original_stdout
    end
    fake.string
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
