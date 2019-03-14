# Contributing

## Pull requests

Make pull requests to the `develop` branch. Once all tests are passing on `develop`, we will merge to `master` and release the gem.

## Tests
### CI setup
gooddata-ruby has a robust CI setup in place to ensure easy contributing by both GD employees and outsiders. The CI is based on travis-ci and all of the environment specifics is versioned in .travis.yml

The pipeline is split into two parts - before-merge and after-merge.
#### Before-merge
This pipeline has to pass before the merge of a PR. All of the checks included are runnable without special permissions or credentials (it is possible to run them as an outside contributor). It includes a suite of unit tests, automated code review tools and mocked (thru VCR) integration and E2E tests.
#### After-merge
This pipeline has to pass before a release is made. It extends the before-merge suite, running it against a live GD env (staging servers) and adds more thorough specs (load specs, slow specs). Special permissions and credentials are required (member of github GD organization, valid testing credentials).
#### Details & Caveats
It is possible to create a local "fork" of the CI environment on travis-ci.org or travis-ci.com. The forked environment will still use the versioned .travis.yml, so all of the settings (including email reporting) will be also valid on the fork. To see a solution to this, check https://confluence.intgdc.com/display/~jakub.mahnert/gooddata-ruby+CI+notification+setup (only applies to specific GD employees)
### Running tests manually 
#### Unit tests
`bundle exec rake test:unit`
#### Integration tests
Currently only GoodData employees can run integration tests for security reasons.

`GD_SPEC_PASSWORD=*** bundle exec rake test:integration`

[Integration tests](spec/integration) can be run against different GoodData [environments](spec/environment) or with 
[VCR](https://relishapp.com/vcr/vcr/docs). 

##### VCR test setup
When adding new integration test, always set `:vcr` metadata. 
```ruby
describe 'New integration test', :vcr
``` 
The VCR `record` mode can be set via `VCR_RECORD_MODE` environment variable. Set it to `all` to make a new recording.
Please check the recorded payloads for possible sensitive data before submitting to github.

##### PI test setup 
If you are so lucky and have acces to PI, you can run the test agains it ... there is guide in [confluence](https://confluence.intgdc.com/display/SCRUM/Running+Tests+on+PI)

## Static analysis
We use [Pronto](https://github.com/prontolabs/pronto) to detect code smells using static analysis.

#### Running locally
`bundle exec pronto run --unstaged -c upstream/develop`

#### Editor integrations:
- [Rubocop](https://rubocop.readthedocs.io/en/latest/integration_with_other_tools/)
- [Reek](https://github.com/troessner/reek#editor-integrations)
- [Flay](https://github.com/seattlerb/flay)

## Documentation

#### Yard

We use `yard` to auto-generate [documentation from comments](https://www.rubydoc.info/gems/gooddata/). Document all new and modified public methods using [`yard` tags](https://www.rubydoc.info/gems/yard/file/docs/Tags.md). Run `./yard-server.sh` to see the result.

#### Cookbook

Usage examples can be found [here](https://sdk.gooddata.com/gooddata-ruby-doc). If your change deserves an example, make a PR to [this repo](https://github.com/gooddata/gooddata-ruby-doc).

## Acceptance criteria

1. The change is as small as possible. It fixes one specific issue or implements
   one specific feature. Do not combine things, send separate pull requests if needed.
1. Include proper tests and make all tests pass (unless it contains a test
   exposing a bug in existing code). Every new class should have corresponding
   unit tests, even if the class is exercised at a higher level, such as a feature test.
1. Every bug-fix has a regression test.
1. If you suspect a failing CI build is unrelated to your contribution, you may
   try and restart the failing CI job or ask a developer to fix the
   aforementioned failing test.
1. Code conforms to this [style guide](https://github.com/bbatsov/ruby-style-guide).
1. When writing tests, please follow [these guidelines](http://betterspecs.org/).
1. Changes do not adversely degrade performance.
1. Your PR contains a single commit (please use `git rebase -i` to squash commits)
1. When writing commit messages, please follow
   [these](http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html)
   [guidelines](http://chris.beams.io/posts/git-commit/).
1. Your changes can merge without problems (if not please rebase if you're the
   only one working on your feature branch, otherwise, merge `master`).
1. If the pull request adds any new libraries, they should be in line with our
   [license](/LICENSE).
1. Use `GoodData.logger` for logging instead of `puts`.
1. Public methods [are documented](#documentation) and examples are added to the [cookbook](#cookbook) when applicable.

_Based on [GitLab's contribution guide](https://github.com/gitlabhq/gitlabhq/blob/master/CONTRIBUTING.md)._
