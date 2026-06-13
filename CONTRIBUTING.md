# Contributing

Maintainers:

- crueter <crueter@eden-emu.dev>

Thanks for your interest in contributing! Before you begin, make sure that you're in the right place. If you want to contribute to Eden, go to [its dedicated repository](https://git.eden-emu.dev/eden-emu/eden). If you want to contribute directly to the CI/build scripts for Eden, then continue on here.

## Layout

Make sure to follow the general layout already present in this repository.

- Scripts and programs should go in `.ci` and be organized by category (`build/`, `package/`, `release/`, `store/`, `config/`, `deps/`, `fj/`, `matrix/`).
- GitHub workflows go in `.github/workflows`. Follow standard conventions there, nothing in particular is nonstandard here.

## Conventions

These are not hard and fast rules, but you are very strongly encouraged to follow them.

- Scripts should be POSIX shell, unless you absolutely need bash features such as arrays, or Python features.
- External dependencies should be minimized if possible. Script suites that manage complex request tasks such as Forgejo releases are okay.
- Conditional CMake configuration options should be placed within files in `.ci/build`, either hijacking existing files or adding new ones.

## Policies

- Absolutely no AI-generated or assisted code is allowed.
- Packages are only to be produced for platforms or targets with a significant and measurable user base.
- Distribution channels are only to be added if they have a significant and measurable impact or benefit.

## Okay, so how do I contribute?

Open a pull request with your changes. Your changes will be reviewed as soon as a maintainer is available, and you are required to allow edits by maintainers.

Maintainers reserve the following rights once you have opened a pull request containing a patch:

- To modify the content contained within your patchset
- To remove channels, packages, or code considered to be unnecessary or detrimental
- To close your pull request in cases of low code quality or suspected AI-generated code
- To cherry-pick specific changes from your PR into other, smaller PRs, or extended PRs
