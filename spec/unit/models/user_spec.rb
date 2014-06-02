# encoding: UTF-8

require 'gooddata/models/domain'
require 'gooddata/models/user'
require 'gooddata/models/project_role'

describe GoodData::User do
  before(:all) do
    ConnectionHelper.create_default_connection

    @users = [
      GoodData::User.new(
        {
          'user' => {
            'content' => {
              'email' => 'petr.cvengros@gooddata.com',
              'firstname' => 'Petr',
              'lastname' => 'Cvengros'
            },
            'meta' => {}
          }
        }
      ),

      GoodData::User.new(
        {
          'user' => {
            'content' => {
              'email' => 'tomas.korcak@gooddata.com',
              'firstname' => 'Tomas',
              'lastname' => 'Korcak'
            },
            'meta' => {}
          }
        }
      ),

      GoodData::User.new(
        {
          'user' => {
            'content' => {
              'email' => 'patrick.mcconlogue@gooddata.com',
              'firstname' => 'Patrick',
              'lastname' => 'McConlogue'
            },
            'meta' => {}
          }
        }
      ),

      GoodData::User.new(
        {
          'user' => {
            'content' => {
              'email' => 'tomas.svarovsky@gooddata.com',
              'firstname' => 'Tomas',
              'lastname' => 'Svarovsky'
            },
            'meta' => {}
          }
        }
      ),
    ]
  end

  after(:all) do
    GoodData.disconnect
  end

  describe '#diff_list' do
    it 'Returns empty diff for same arrays' do
      l1 = [
        @users[0]
      ]

      l2 = [
        @users[0]
      ]

      diff = GoodData::User.diff_list(l1, l2)
      diff[:added].length.should eql(0)
      diff[:changed].length.should eql(0)
      diff[:removed].length.should eql(0)
    end

    it 'Recognizes added element' do
      l1 = []

      l2 = [
        @users[0]
      ]

      diff = GoodData::User.diff_list(l1, l2)
      diff[:added].length.should eql(1)
      diff[:changed].length.should eql(0)
      diff[:removed].length.should eql(0)
    end

    it 'Recognizes changed element' do
      l1 = [
        @users[0]
      ]

      l2 = [
        GoodData::User.new(@users[0].json.deep_dup)
      ]
      l2[0].first_name = 'Peter'

      diff = GoodData::User.diff_list(l1, l2)
      diff[:added].length.should eql(0)
      diff[:changed].length.should eql(1)
      diff[:removed].length.should eql(0)
    end

    it 'Recognizes removed element' do
      l1 = [
        @users[0]
      ]

      l2 = []

      diff = GoodData::User.diff_list(l1, l2)
      diff[:added].length.should eql(0)
      diff[:changed].length.should eql(0)
      diff[:removed].length.should eql(1)
    end
  end
end
