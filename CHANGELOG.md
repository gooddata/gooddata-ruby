# GoodData Ruby SDK Changelog

## 0.6.54
- TMA-512 - Fix invalid data type issue in blueprint when a field has > 255 characters
- TMA-506 - Add option :time to report.execute to force platform simulate the result of report at that time
- TMA-509 - Provisioning: Should clean all zombie clients when project creation limit reached
- TMA-542 - Release: Should fail when segments contains duplicated ids
- TMA-536 - Release: transfer Dataset and Fact Tags in ImportObjectCollection
- TMA-532 - Rollout: Improve behavior of update_preferences: introduce 2 paramameters allow_cascade_drops and keep_data
- TMA-537 - Release: rename parameter production_tag to production_tags and support passing Array value
- TMA-572 - Improve API call statistics log: add grouping on CLIENT_ID
- TMA-563 - Provisioning brick doesn't verify status of project_id
- TMA-502 - User and User Filters brick: multiple_projects_column = client_id should be default for client modes
- TMA-565 - Provisioning brick doesn't add technical users when input source contains project_id
- TMA-547 - Provisioning brick: sync client workspace title
- TMA-301 - Make it possible to pass dynamic parameters to schedules
- TMA-568 - Users Brick: add support for other user's attributes
- TMA-195 - LCM bricks should transfer permissions and groups
- TMA-575 - Add support for raw export-report API

## 0.6.53
- TMA-522 - Rollout: Incorrect CLIENT_ID assigned to client schedule

## 0.6.52
- Add support for computed attribute in blueprint
- Fix bug with transfering schedules without their state
- Support segment-specific production tags (TMA-309)
- Rewrite deprecated schedule parameter "GRAPH" (TMA-453)
- Add parameter HTTP_LOGGING to LoggerMiddleware
- Resolve also hidden reference parameters (TMA-411)
- Support integer type id in Domain#clients (TMA-450)
- Support urn for date dimension (TMA-221)
- Implement "skip_actions" for LCM2
- Support MAQL DIFF API (TMA-219)
- Support for restricted flag
- Fix deployment via SDK on Windows

## 0.6.50
- Add support for Email Notification Rules on Process
- Add support for exclude_schedules option in Project#export_clone
- Add support for cross_data_center_export option in Project#export_clone
- Support for Automated Data Distribution in project
- Added Dockefile for easy build of dockerized gooddata-ruby
- Handle export/import async task errors (TMA-231)
- Support for custom color palette
- Support for trasfering attribute drill paths
- Implemented basic version of LCM2
- Add more logging for user, user filter management

## 0.6.49
- Implement Helpers::GD_MAX_RETRY to allow max retries override

## 0.6.48
- Fix jruby issue with uninitialized constant GoodData::Rest::Connection::ConnectionHelper

## 0.6.47
- Support for GD_MAX_RETRY environment variable for external manual override of maximum retry attempts
- Updated dependencies (gems)
- Do not log params if JSON parsing fails

## 0.6.46
- Fixed transfer_label_types, use target client for lookup

## 0.6.45
- Fixed transfer_everything when LDMs are the same

## 0.6.44
- Fixed the tests
- The MAQL execution now throws an exception if there is an error
- The authentication is made via tokens not cookies

## 0.6.26
- There is first implementation of transfering ETLs
- Fixed bug with getting clients from domain
- Temporary workaround for problem on API when it fails with 500 when you are trying to read  changes of provision clients when nothing was provisioned
- Added option to not delete projects when updating clients in segments

## 0.6.24
- Fixed problem with validElements causing 500

## 0.6.23
- Fixed typo sometimes causing crash of ReportDefinition#replace

## 0.6.22
- Added rake task (license:add) for automatic license headers generating
- Handle situation when upload_status.json does not exist
- Connect using SSO - GoodData#connect_sso
- Added Measure semantics, alias methods metrics to measure (ie. interpolate_metric -> interpolate_measure)
- rake tasks license:check, license:report & license:info for automated license reporting added
- Fixed a typo in labels
- Executions are paging + are implemented as lazy enumerators
- Fixed after getter in schedule
- Blueprint works with deprecated labels
- Metadata object has new methods for working with unlisted attribute
- Metadata method deprecated= now accepts and return true/false
- Included date_facts in building a manifest
- Using API for user provisioning by login
- Multiple data sets upload Project#upload_multiple
- GoodData::MdObject.json is assignable now (using attr_accessor)
- Added method for updating report definition in easy way - GoodData::Report#update_definiton(opts, &block)
- Added more logging around connecting to server. Cleaning up staging information. Adding tests to make
- Middlewares are transforming params to Ruby hash (useful for executors when they pass Java Hash instance)
- Cleaning up way Data permissions work with errors so we can update Bricks
- Fixed Project#browser_url
- Increased max count of retries for 429 - Too Many Requests
- Fixed potentional crash of ReportDefinition#replace
- Updated dependencies (gems)

## 0.6.21
- Consolidated error reporting for Domain#create_users & Project#import_users
- Removed superfluous error messages on 401
- Fixed bug with rich params when it could happen that hidden params got deleted on schedule save

## 0.6.20
- added iterators for retrieval of project, domain, and group objects
- use query resource inlining for retrieving user filters
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
