module Support
  BLUEPRINT_FILE = './spec/lcm/integration/data/model.json'
  METRICS_FILE = './spec/lcm/integration/data/metrics.json'
  REPORTS_FILE = './spec/lcm/integration/data/reports.json'
  DASHBOARDS_FILE = './spec/lcm/integration/data/dashboards.json'

  DATASET_IDENTIFIER = 'dataset.csv_policies'
  FACT_IDENTIFIER = 'fact.csv_policies.customer_lifetime_value'
  FACT_IDENTIFIER_RENAMED = 'fact.csv_policies.customer_lifetime_value.renamed'
  DATA_FILE = './spec/lcm/integration/data/policies.csv'

  CC_PROCESS_ARCHIVE = './spec/lcm/integration/data/cc_process.zip'
  CC_PROCESS_NAME = 'Simple CloudConnect Process'
  CC_SCHEDULE_CRON = '0 15 10 3 *'
  CC_GRAPH = 'graph/test.grf'
  CC_PARAMS = { param_1: 'a', param_2: 'b' }
  CC_SECURE_PARAMS = { secure_param_1: 'secretive_foo', secure_param_2: 'secretive_bar' }

  RUBY_HELLO_WORLD_PROCESS_PATH = '${PUBLIC_APPSTORE}:branch/master:/apps/hello_world_brick'
  RUBY_HELLO_WORLD_PROCESS_NAME = 'Simple Ruby Process'
  RUBY_PARAMS = { param_1: 'a', param_2: 'b' }
  RUBY_SECURE_PARAMS = { secure_param_1: 'secretive_baz', secure_param_2: 'secretive_qux' }

  PRODUCTION_TAGGED_METRIC = 'metric.max.claim.amount'

  CUSTOM_CLIENT_ID_COLUMN = 'custom_client_id_column'

  COMPUTED_ATTRIBUTE_ID = 'attr.comp.my_computed_attr'

  USER_GROUP_NAME = 'My Test Group'
end
