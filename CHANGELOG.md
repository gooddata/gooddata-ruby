# GoodData Ruby SDK Changelog
## 1.3.5
 - Fix reading version from file
 - BUGFIX: TMA-1264 Copy version files to Docker image
 - Bump version to 1.3.4

## 1.3.4
 - FEATURE: TMA-1240 Read SDK and brick versions from files
 - TEST: TMA-1061 Introduce end to end tests
 - TMA-483 request number optimisation in synchronize users and user filters action
 - TMA-1232: resilient user filters spec
 - II-294: Update base image - CentOS 7.6
 - FEATURE: TMA-1243 Upgrade LCM k8s image to JRuby version 9.2.5.0
 - Encrypt notification recipient
 - TMA-1192: dependable CI env
 - TMA-1003: Move mocking methods into a separate class
 - BUGFIX: TMA-1233 Install RVM according to changes in installation script
 - Describe parameters of create_expression
 - BUGFIX: TMA-1233 Remove ZenTest development dependency which isn't needed anymore
 - Relax the activesupport dependency
 - fixup! TMA-1003: Add unit test for delete_extra_process_schedule
 - BUGFIX: TMA-1218 Anonymise hidden parameters only in LCM bricks running in K8s
 - TMA-1003: Add unit test for delete_extra_process_schedule
 - Update README.md
 - Remove nonsensical object extension
 - TMA-1189: Remove unnecessary requires from specs
 - FEATURE: TMA-1198 Log LCM brick output to file instead of stdout when running in K8s
 - Update README.md
 - REFACTOR: TMA-1198 Set global logger in LoggerMiddleware instead of GoodDataMiddleware
 - TMA-1216 removed constant PROJECT_URL
 - TMA-1070: Record vcr cassettes
 - TMA-1070: Add test for LCM components
 - TRIVIAL: Remove code which was commented out
 - TMA-1208 Log to sigle file from K8s LCM bricks
 - TMA-1190: Merge cleanup stage into periodic
 - BUGFIX: TMA-1121 use current user call instead of expensive bootstrap

## 1.3.3
 - Fix git-ignoring project cache
 - Fix style in vcr configurer
 - TMA-1205: Fix vcr configurer setup
 - Describe releasing process more accurately
 - Fix editorconfig
 - TMA-1190: Add cleanup stage to travis.yml
 - gemspec cleanup: transitive deps, email, authors
 - TMA-1190: Add test env clean-up script
 - TMA-1185: Record vcr cassettes
 - TMA-1185: Fix vcr for project cache
 - TMA-1182: UFB extended spec passing
 - TRIVIAL: remove redundant suffix
 - BUGFIX: TMA-1183 don't use make_tmpname
 - TMA-1181: use correct exit code from lcm integ. docker-compose
 - TMA-782: do not rely on spec extensions
 - Revert "TMA-1181: do not use docker for lcm-integration-tests"
 - TMA-1152: logout and delete users after spec
 - FEATURE: TMA-1165 Create Help brick and make it default entry point in Docker image
 - TMA-1181: passing userprov spec
 - TRIVIAL: use the correct ruby version's for tests in travis
 - TMA-1181: do not use docker for lcm-integration-tests
 - Add pry-byebug to dev dependencies
 - Fix standalone calls to rspec expect
 - TMA-782: transfer component type process thru lcm
 - FEATURE: TMA-1165 Remove unused info bricks
 - Enable travis notifications in slack
 - Update gooddata.gemspec
 - TMA-1048 update ads driver dependency
 - Run unit tests in supported rubies
 - Run cron job on staging env 1/2/3
 - FEATURE: TMA-1034 Add Docker label containing LCM bricks version
 - SETI-2444 fix docker run on jenkins slaves
 - TMA-1014: parallel do_not_touch logic in UFB
 - TMA-905: do not print dynamic schedule param value if the param is set as secure
 - BUGFIX: TMA-1153 Adjust LCM brick syslog to be able to log to Splunk
 - TMA-1100 fix productized connector deployment
 - TMA-1071: Record VCR cassettes
 - TMA-1071: Reenable VCR
 - Add pry-byebug to dev dependencies

## 1.3.2
 - Add rake task for changelog preview
 - added possibility to run tests on PI
 - TMA-1025: Parametrize output stage prefix
 - TMA-1002 fix test run and added abbility to recover from mandatory projects delete
 - Remove secret from .travis.yml
 - Dont swallow error in .decrypt
 - Properly escape secret in .travis.yml
 - Update ruby in .travis.yml to 2.3
 - Fix travis secret
 - FEATURE: TMA-1034 Create image build pipeline
 - TMA-1033: report pid in case of UFB failure
 - Name travis build stages
 - TMA-801: Update rubocop
 - FEATURE: TMA-1052 Create execution script for each brick
 - TMA-1081: fail UFB when multiple_project mode column is missing from UB input
 - Enable running tests using cron in travis
 - Reduce log size
 - Set $HOME to writable directory
 - Run pronto in travis
 - TRIVIAL: Correct Ruby version used in brick Dockerfile
 - FEATURE: TMA-1052 Change parameters passing
 - TMA-1078: Generate stronger passwords
 - Set correct default password
 - TMA-986 fix random user selection in user filters test
 - TMA-1005: Rotate test user password
 - TMA-1005: Add description for rake password:rotate

## 1.3.1
 - FEATURE: TMA-1030 Raise jruby version used in K8s docker image (#1284)
 - Update README.md
 - TRIVIAL: Correct dockerfile maintainer
 - TMA-1033: show reason of filter composition failure (#1282)
 - TMA-483 && TMA-963 Paralel ufb bug final fix
 - TMA-963 && TMA-483: UFB and UB performance (#1234)
 - TMA-1002 fixed broken tests
 - no vcr (#1277)
 - TMA-1005: Automate rotating credentials
 - TMA-925: Optimize polling intervals
 - Add info about running tests to CONTRIBUTING.md (#1262)
 - Fix rubocop issue
 - Add empty lines between licenses and modules
 - SETI-2180 Updated base image namespace
 - FEATURE: TMA-1030 Dockerize LCM bricks
 - FEATURE: TMA-1030 Write brick outputs to files
 - FEATURE: TMA-1030 Add Hello World brick
 - REFACTOR: TMA-1030 Non functional changes
 - BUGFIX: TMA-1040 Add nil result if action fails
 - TEST: TMA-1040 Add tests for "perform" method in LCM2 module
 - Require ActiveSupport where it's needed
 - Revert Array refinement to Enumerable opening
 - Revert class to reopening
 - Use duplicable? from ActiveSupport
 - Remove object.blank? as ActiveSupport already do it
 - Revert Object to reopening
 - Increase the scope of monkey patchs
 - Fixes tests in CI
 - Patch all places that use '.to_b' with all extensions that implements it
 - Isolate Symbol monkeypatch in SymbolExtensions module
 - Code :lipstick: Insert license header in files where it was missing
 - Isolate String monkeypatch in StringExtensions module
 - Add TrueExtensions and FalseExtensions in missing places
 - Isolate Object monkeypatch in ObjectExtensions module
 - Isolate Numeric monkeypatch in NumericExtensions module
 - Isolate BigDecimal monkeypatch in BigDecimalExtensions module
 - Adds Extensions to Globalhelper, it's the only one calls `duplicable?`
 - Isolate Nil monkeypatch in NilExtensions module
 - Isolate Integer monkeypatch in IntegerExtensions module
 - Isolate Hash monkeypatch in HashExtensions module
 - Isolate True/False monkey patchs in respectives modules
 - Is a good practice to explicit the error in rescue block
 - Isolate Enumerable monkey patch in EnumerableExtensions module
 - Isolate Class monkeypatch in ClassExtensions module
 - TMA-927: handle uppercase email inputs
 - TMA-648 tests not deleting ads instances fixed

## 1.3.0
 - Add changelog for 1.2.1
 - Automate bumping version (#1243)
 - TMA-787 added support M:N in LCM
 - Fix spec for synchronize_ldm=diff_against_master
 - TRIVIAL: remove the newline character from the CSV header string
 - TMA-484: Fix getting latest master version (#1258)
 - minor fixes to the load tests
 - Enable lcm tests on personal instance
 - TMA-787 added support M:N in LCM
 - Fix logging error


## 1.2.1
 - Document gem release process (#1254)
 - TMA-956 - Update process.rb to fix regression from TMA-832 (#1248)
 - Add certificate for prodgdc
 - fixed up the pefr cluster urls
 - fixed url to perfcluster
 - TMA-983: Fix error in after hook
 - Exclude specs from gem release
 - Exclude specs from gem release
 - Bump version to 1.2.0 (#1242)
 - Run pronto against correct branch (#1244)
 - SRT-796: Ensure safe version of rubyzip

## 1.2.0
 - * TMA-484: Perform MAQL diff only once in rollout
 - Use the latest aws sdk gem (#1237)
 - fixed lcm.rake file
 - Limit logging (#1238)
 - TMA-969 brick does not ends when run with nonsensical delete params (or mode)
 - Add a readme for LCM specs (#1224)
 - Added VCR_ON to the docker compose env variables
 - fixed rake task for load tests
 - Load webmock only when VCR is on
 - Deduplicate environments
 - fix: clean up logger in logging_spec
 - TMA-950: VCRize user_filters_spec
 - TMA-950: VCR for over_to_user_filters_spec
 - TMA-950: VCR for mandatory_user_filter_spec
 - modified docker-compose commpands in rake file to solve the localstack problem
 - TMA-939: VCRize domain_spec
 - TMA-939: VCRize profile_spec
 - changed localstack image in docker compose
 - Run project specs in test:integration task
 - TMA-900: VCR for full_project_spec
 - TMA-900: VCR for full_process_schedule_spec
 - TMA-900: VCR for variables_spec
 - TMA-900: VCR for urn_date_dim_spec
 - TMA-900: VCR for subscription_spec
 - TMA-900: VCR for segment_spec
 - TMA-900: VCR for partial_md_export_import_spec
 - TMA-900: VCR for lcm_spec
 - TMA-900: VCR for deprecated_load_spec
 - TMA-900: VCR for date_dim_switch_spec
 - TMA-900: VCR for create_project_spec
 - TMA-900: VCR for create_from_template_spec
 - TMA-900: VCR for connection_spec
 - TMA-900: VCR for schedule_spec
 - fixed cyclic decrypting of encrypted password
 - TRIVIAL: remove redundant if
 - TMA-900: VCR for command_projects_spec
 - TMA-900: VCR for command_datawarehouse_spec
 - TMA-900: VCR for clients_spec
 - TMA-900: VCR for channel_configuration_spec
 - TMA-900: VCR for unit_project_spec
 - TMA-900: VCR for models project_spec
 - TMA-900: VCR for project_role_spec
 - TMA-900: VCR for report_spec
 - TMA-900: VCR for process_spec
 - TMA-900: VCR for membership_spec
 - TMA-900: VCR for label_spec
 - delete empty invitation_spec
 - TMA-900: VCR for data_product_spec
 - fix: delete domain users at one place
 - fix: temporarily remove domain_spec from VCR
 - fix: temporarily remove vcr for user groups
 - fix rspec before example
 - fixup! Skip sleep only when vcr_record_mode=none
 - TMA-928: delete temporary user profiles
 - Skip sleep only when vcr_record_mode=none
 - TMA-705 deprecated delete_projects and delete_extra param and added new delete_mode (#1196)
 - Enable VCR under ruby >= 2.4
 - Add task for configuring git-flow extension
 - Revert "Fail when decrypting using an empty key" (#1197)
 - SETI-1082 localstack container now uses unique name and s3 the force_path_style param
 - fix VCR_ON evaluation
 - Refactor decrypting passwords (#1194)
 - TRIVIAL: move to vcr_enabled logic to single if
 - TMA-900: setup VCR for blueprint_with_grain_spec
 - TMA-900: setup VCR for blueprint_with_ca_spec
 - TMA-900: setup VCR for blueprint_updates_spec
 - TMA-900: setup VCR for ads_output_stage_spec
 - TMA-900: setup VCR for commands_projects_spec
 - TMA-831: create default dataproduct if it does not exist yet
 - Don't skip sleep when recording cassettes
 - Enable vcr for params spec
 - Split integration tests in two stages
 - Fail when decrypting using an empty key
 - Use travis to run integration tests
 - TMA-560: Merge appstore repo to gooddata-ruby
 - changelog:update doesn't rely on last tagged object
 - fix project role spec for new role implementation (#1188)
 - PI is viable environment for running tests
 - TMA-892: Fix passing results of sync_domain_client_workspaces
 - TMA-892: Fix user filters dry run when false
 - TMA-868: deprecated flag now propagates the value to the replacement param if the type is compatible
 - TMA-892: User filters brick dry run (#1156)
 - fix recovery from provision clients error
 - make sso backwards compatible
 - TMA-920: self contained goodfile spec

## 1.1.0
 - TMA-860: use new roles API (#1169)
 - test passed locally 
 - Avoid polling idle time in VCR tests
 - Enable vcr for metric specs
 - TMA-832: support for pluggable component process type
 - TMA-900: setup vcr for logging_spec
 - TMA-900: setup vcr for id_to_uri_spec
 - TMA-900: allow vcr to match uploads requests
 - TMA-900: setup vcr for project_spec
 - TMA-900: add VCR to connection_spec
 - TRIVIAL: add idea moudle to gitignore
 - TMA-904: allow to enable/disable VCR completely by ENV
 - TMA-712 if not run by test, the check_helper now only warns, not fails
 - TMA-895: MUFs work when shared between users
 - TMA-898: users brick deletes users from domain
 - Document the VCR usage in contribution guide
 - TMA-904: allow to set VCR record mode from environment
 - TEST: TMA-376 use VCR by user_group_spec
 - TEST: TMA-376 introduce VCR for integration testing
 - TMA-868: deprecated flag now propagates the value to the replacement param if the type is compatible
 - TMA-604: can put metrics in folders
 - TMA-843: avoid abuse of obj resource in partial md import export
 - TMA-892: User filters brick dry run (#1156)
 - * TMA-892: User filters brick dry run
 - TMA-761: add support for manual schedule execution
 - fix recovery from provision clients error
 - make sso backwards compatible
 - TMA-799: Introduce HLL functionality to LCM bricks
 - TMA-811 fixed wrong type in params specification in synchronize users action
 - rotate integration test projects
 - TMA-846 fixed bug in specification in synchronize_users action, unified access to the smart hash properties to symbol and fixed bug which caused some of the variablent to slip unchecked
 - TMA-601: Remove CLIENT_ID setting from LCM bricks
 - TMA-764: use POST for SSO
 - SETI-1643: rotated password for rubydevadmin account
 - No rake-notes quickfix
 - Rotated project tokens and rubydev admin password
 - TEST: introduce unit test for REST placeholders
 - TMA-732: all sync_multiple actions fail when filter set is empty
 - TMA-788: req of yard library ~> 0.9.11
 - TMA-683: add missing stats placeholders
 - * replace word and dash matching with not slash matching
 - * for domain dataproducts
 - * for outputStage
 - * for userGroups
 - TMA-819: requests to the profile/email@addr API always use downcase
 - This reverts commit 66b4b7ac5dc943e11c0e179490d27d6699603386.
 - Align active maintainers with reality
 - TMA- 712 actions now fail when unspecified param is acessed
 - TMA-785: Support excludeFactRule parameter
 - SETI-1595: rotating passwords
 - Make activesupport a runtime dependency
 - TMA-836: release brick takes deprecated objects into account
 - TMA-816: Make .execute_mufs work with symbolized hashes
 - TMA-824: Test filters created with .get_filters
 - TMA-818: executing mufs fails if api returns errors

## 1.0.2
 - TMA-775: smart attribute polling
 - TMA-809: Fix new visualization object in bricks
 - TMA-809: new visualizationObject in replace_from_mapping
 - TMA-690 && TMA-633 tests now verify that synchronize users action fails when supplied with unsupported sync_mode param
 - deprecations.txt is in .gitignore file
 - TMA-691 colect data product action has human readable output
 - TMA-732: fix edge cases for user input sanitized MUFs

## 1.0.1
 - Bump version to 1.0.1
 - TMA-776: Improve error handling of sync clients
 - TMA-775: platform agnostic lookup of label
 - TMA-762: Fix test for swapping date dimensions
 - TMA-494: Support for java platform
 - fix skip actions for bricks
 - move PH_MAP to separate file

## 1.0.0
 - TMA-575: Add support for raw export-report API
 - TMA-738: Update highline to v2
 - TMA-711: segments filter works correctly in users brick
 - TMA-662: Users Brick passes with empty input source
 - Rename travis.yml to .travis.yml

## 0.6.54
 - Generating changelog automatically from git
 - Fix resolving dataproduct
 - TMA-685: User filters and users bricks support data product
 - TMA-700: Fix executing empty report
 - TMA-696: Handle status 200 with no content type
 - TMA-632: Fix result for sync_domain_client_workspaces
 - TMA-680: Add option include_computed_attributes
 - mdidtouri spec has correct data types
 - TMA-686: filtering segments in release brick
 - TMA-663: synchronize_user_filters does not fail if the client set is empty
 - TMA-299: Data Product used in bricks
 - removed unused class params_inspect_middleware
 - Update list of dependencies
 - TMA-666: Generate junit-formatted test results
 - simplecov has to be initialized before any other code
 - enabling code coverage calculation during tests
 - TMA-366: Indicate replacement for technical_user

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
