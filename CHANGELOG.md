# GoodData Ruby SDK Changelog


## 0.6.20
- added iterators for retrieval of project, domain, and group objects
- use query resource inlining for retrieving user filters
- added support of GoodData PGP SSO
- fixed default parameters from ~/.gooddata file (auth token, server)
- added project WebDav deprecation warning
- removed dependency on Active Support gem

## 0.6.19
- major (not backward compatible) blueprint refactoring
- added environment parameter to the project creation
- added HTTP retry strategy with exponential wait times and maximum retries set to 10
- set max concurrent platform connections set to 20 per session
- set socket timeout to 1 minute

## 0.6.18
- added support for the HYPERLINK label type in blueprint
- fixed method Schedule#create doesn't set schedule name
- added method "error?" to the class "ExecutionDetail"
- added blueprint support for folders
- added ability to change SSO provider for existing platform user
- added schedules and executions convenience methods

## 0.6.17
- added validation of the blueprint datatypes (e.g. INTEGER -> INT, allow mixed case etc.)
- improved the data loading logging and error handling
- added date dimension switching
- switched to the new asynchronous ETL pull resource
- added specification of date reference's format in blueprint
- added HTTP logging oneliner 

## 0.6.16
- fixed SSL certificate validation (verify_ssl option in the GoodData.connect)
- logging changes: separated the HTTP and application logging to different levels, added platform request ID
- fixed the WebDav URI bootstrap to work with the EU datacenter
- added driver parameter for Vertica based project creation

## 0.6.15

- Adding users now accepts more variants of providing users
- Import users is not importing users to domain automatically. There is app in appstore that should help you with various ways of importing users
- Speed improvements for adding users
- Fixed listing facts/attributes on the dataset
- Corrected fixed limit on listing users from domain. Paging is handled by different parameter
- Replacing value in metric/attribute should be more resilient

## 0.6.14

- Project update from blueprint does not fail when MAQL chunks are empty.
- You can call migrate_datasets with dry_run to obtain MAQL chunks.
- Fix of title generation in blueprint from wire.

## 0.6.13

- Fixed TT problems
- Fixed process redeployment helpers
- Rubocop compliance with the latest version
- MD datasets are now available
- SSL set to verify none for now. We will make it more secure in next version.
- Changed limit on users pulled from domain. Will change it in the future so there is no fixed limit.

## 0.6.12

- Ability to create a Data Warehouse (ADS) 
- Retry all requests 3 times when SystemCallError, RestClient::InternalServerError or RestClient::RequestTimeout
- Automatic 429/TooManyRequests Handler
- When creating user login and email can be different now
- Automatic client disconnect at_exit of ruby script
- When creating user login and email can be different now
- Fixed Domain#add_user (GH issue #354)
- Support for GoodData.connect ENV['GD_GEM_USER'], ENV['GD_GEM_PASSWORD']
- Added Schedule#execute(:wait => true|false) option
- Merge GoodData::Rest::Connection and GoodData::Rest::Connection::RestClientConnection
- Unified expection handler for REST API and WebDav Access (using GoodData::Rest::Connection.retryable)
- GoodData#stats_on, GoodData#stats_off, GoodData::Rest::Client#stats_on, GoodData#stats_off
- GoodData::Mixin::MdObjectQuery#using now accepts :full => true|false option
- GoodData::MdObject#[] automatically returns proper type (ie. GoodData::Report)
- Improved user management
- Added simple GoodData::Dimension

## 0.6.11

- Ability to download deployed process
- Added locking objects capabilities
- Added removing color mapping form a report definition
- Report defintions are deleted along with a report
- Report definitions are deleted along with a report
- Improved process deployment and schedules
- Parameters in processes and schedules are now able to take complex parameters
- #create_metric is significantly faster
- Pretty_expression for metric should not fail on missing data
- Extended notation can be switched off when using create_metric
- Implemented retry on connection related issues
- All executions should use latest resource version
- Uploading files to webdav should use streaming and be more memory efficient
- Ability to pass absolute path to file upload  
- Allowing special chars in uploaded file
- GooddataMiddleware doesn't require username+password, when it has SST  

## 0.6.10

- Fixed client default missing in ProjectMetadata
- Listing schedules on processes is working
- Scrubing params in logs is back
- Added ProjectMetadata helpers on project
- Listing processes on client works as expected
- Schedule can be enabled/disabled
- Added pselect helper function

## 0.6.9

- Fixing issues with creating models.
- Adding couple more helpers for report/metric computation
- Rewriting several full_* specs to use the new syntax

## 0.6.8

- REST Factory - See [PR #224](https://github.com/gooddata/gooddata-ruby/pull/224)
- Replace on report definitions allows to swap attributes, metrics and other things in report definitions
- Fixed bug in clone so you can clone projects without data
- Many map call on REST happen in parallel
- Query requests (all attributes, all metrics etc) are happening in parallel and full: true is now the default
- Computing an a report which returns no results does not fail but returns nil
- Refactored handling of all various asynchronous resources into 2 methods
- added ability to log in with only SST token
- added with_connection
- ability to deploy just one file, zipped files or directory

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
