require 'helper'
require 'gooddata/command'

class TestGuesser < Test::Unit::TestCase
  should "order LDM types as follows: cp, fact, date, attribute" do
    assert_equal [ :connection_point, :fact, :date, :attribute ], \
                 GoodData::Command::Guesser::sort_types([ :fact, :attribute, :connection_point, :date ])
    assert_equal [ :fact ], GoodData::Command::Guesser::sort_types([ :fact ])
    assert_equal [], GoodData::Command::Guesser::sort_types([])
  end

  should "guess facts, dates and connection points from a simple CSV" do
    csv = [
      [ 'cp', 'a1', 'a2', 'd1', 'd2', 'f'],
      [ '1', 'one', 'huh', '2001-01-02', nil, '-1' ],
      [ '2', 'two', 'blah', nil, '1970-10-23', '2.3' ],
      [ '3', 'three', 'bleh', '0000-00-00', nil, '-3.14159'],
      [ '4', 'one', 'huh', '2010-02-28 08:12:34', '1970-10-23', nil ]
    ]
    fields = GoodData::Command::Guesser.new(csv).guess(csv.size + 10)

    assert_kind_of Hash, fields, "guesser should return a Hash"
    fields.each do |field, info|
      assert_kind_of Array, info, "guess for '%s' is not an Array" % field
    end

    type_msg_fmt = 'checking guessed types of "%s"'

    assert_equal GoodData::Command::Guesser::sort_types([
        :connection_point, :fact, :attribute
      ]), fields['cp'], type_msg_fmt % 'cp'

    assert_equal [ :attribute ], fields['a1'], type_msg_fmt % 'a1'
    assert_equal [ :attribute ], fields['a2'], type_msg_fmt % 'a2'

    assert_equal GoodData::Command::Guesser::sort_types([
        :attribute, :connection_point, :date
      ]), fields['d1'], type_msg_fmt % 'd1'
    assert_equal GoodData::Command::Guesser::sort_types([
        :attribute, :date
      ]), fields['d2'], type_msg_fmt % 'd2'
    assert_equal GoodData::Command::Guesser::sort_types([
        :attribute, :connection_point, :fact
      ]), fields['f'], type_msg_fmt % 'f'
  end
end
