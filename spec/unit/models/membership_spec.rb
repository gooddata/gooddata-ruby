# encoding: UTF-8

require 'gooddata/models/domain'
require 'gooddata/models/membership'
require 'gooddata/models/project_role'

describe GoodData::Membership do
  before(:all) do
    @client = ConnectionHelper.create_default_connection

    @users = [
      @client.create(GoodData::Membership,
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

      GoodData::Membership.new(
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

      @client.create(GoodData::Membership,
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

      @client.create(GoodData::Membership,
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
    @client.disconnect
  end

  describe '#diff_list' do
    it 'Returns empty diff for same arrays' do
      l1 = [
        @users[0]
      ]

      l2 = [
        @users[0]
      ]

      diff = GoodData::Membership.diff_list(l1, l2)
      diff[:added].length.should eql(0)
      diff[:changed].length.should eql(0)
      diff[:removed].length.should eql(0)
    end

    it 'Recognizes added element' do
      l1 = []

      l2 = [
        @users[0]
      ]

      diff = GoodData::Membership.diff_list(l1, l2)
      diff[:added].length.should eql(1)
      diff[:changed].length.should eql(0)
      diff[:removed].length.should eql(0)
    end

    it 'Recognizes changed element' do
      l1 = [
        @users[0]
      ]

      l2 = [
        GoodData::Membership.new(GoodData::Helpers.deep_dup(@users[0].json))
      ]
      l2[0].first_name = 'Peter'

      diff = GoodData::Membership.diff_list(l1, l2)
      diff[:added].length.should eql(0)
      diff[:changed].length.should eql(1)
      diff[:removed].length.should eql(0)
    end

    it 'Recognizes removed element' do
      l1 = [
        @users[0]
      ]

      l2 = []

      diff = GoodData::Membership.diff_list(l1, l2)
      diff[:added].length.should eql(0)
      diff[:changed].length.should eql(0)
      diff[:removed].length.should eql(1)
    end
  end
end
