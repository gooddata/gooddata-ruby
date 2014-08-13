# GoodData Ruby SDK Changelog

## 0.6.8

- REST Factory - See [PR #224](https://github.com/gooddata/gooddata-ruby/pull/224)

## 0.6.7

- Fixed the scaffolding templates to take advantage of new syntax (missing references in dataset refs) 
- Fixing inclusion of extensions when using CLI
- Fixed pollers and added/fixed tests for schedules and processes
- Added with_connection which automatically disconnects when you are done

## 0.6.6

- Various fixes

## 0.6.5

- Mixins

## 0.6.4

- Ability to get blueprint directly through API. This way you can work with projects that was not created using SDK
- Added basis for GD_LINT that checks your project for typical problems

## 0.6.3

- Able to do save_as on metadata objects (Report, Metric, Dashboard)
- Model is now not created through build and update if it is not passing validations
- Added a setter for identifier on Metadata Object
