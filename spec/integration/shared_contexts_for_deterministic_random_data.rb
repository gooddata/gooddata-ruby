shared_context 'deterministic random string in $example_name' do
  before(:each) do |example|
    $example_name = example.description
  end
end
