# TODO

## Lib

- Check all GoodData::Something[:all], they used to return Array of Hashes in many cases now they are all returning Objects
- Use less strict versioning See [#96](https://github.com/gooddata/gooddata-ruby/pull/196)
- Library wide-logging to tmp/logs/{{TIMESTAMP}}.log
- Globar library crash handler storing stacktraces to tmp/crashes/{{TIMESTAMP}}.log
- High Level Error Handling
- Pretty Print Rest Client & Connection
- Unify
  - [NoProjectError](https://github.com/gooddata/gooddata-ruby/blob/master/lib/gooddata/exceptions/no_project_error.rb)
  - [ProjectNotFound](https://github.com/gooddata/gooddata-ruby/blob/master/lib/gooddata/exceptions/project_not_found.rb)
- Use more of pmap
- Create class (GoodData::Storage) for abstracting remote FS (=> WebDav)
- Print stats at client disconnect and not at_exit as now!
- Make stats optional via cmd-line switch

## Tests

- Pending tests
- Rubocop spec/**/*.rb
- Properly split unit and integration tests

## All Timers

- [Issues](https://github.com/gooddata/gooddata-ruby/issues)
- Rake notes - [rake notes](https://gist.github.com/korczis/a127456afdda3df4e3a6)

# Done

- walked through Project and added majority of the helpers for getting project related objects (fact, attr, metric, etc)