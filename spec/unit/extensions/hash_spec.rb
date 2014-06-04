# encoding: UTF-8

describe Hash do

  describe '#deep_dup' do
    it 'should crete a deep copy' do
      x = {
        :a => {
          :b => :c
        }
      }
      y = x.dup
      deep_y = x.deep_dup

      y[:a].object_id.should === x[:a].object_id
      deep_y[:a].object_id.should_not === x[:a].object_id
    end
  end
end
