### Contribution acceptance criteria

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

_Based on [GitLab's contribution guide](https://github.com/gitlabhq/gitlabhq/blob/master/CONTRIBUTING.md)._
