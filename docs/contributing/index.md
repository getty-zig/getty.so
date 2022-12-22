# Contributing

Contributions to Getty are very welcome! 😄

This document contains some information and a few guidelines to help get you
started. If you have questions about contributing or Getty, feel free to reach out on the [Getty Discord](https://discord.gg/njDA67U5ph).

## Zig

- Getty currently tracks the `master` release of Zig, so make sure your version is updated.

## Issues

- [GitHub Issues](https://github.com/getty-zig/getty/issues) are used exclusively for tracking bugs and feature requests for Getty.

- When filing an issue, please provide a brief explanation on how to reproduce your issue.

- When filing a feature request, please check if the latest version of Getty already implements the feature beforehand and whether there's already an issue filed for your feature.

## Pull Requests

- Please follow our [Style Guide](/contributing/style-guide) whenever contributing code.

- Before submitting a PR, please test your changes and ensure that the test suite passes locally.

- When submitting a PR, please have it be relative to a recent Git tip.

- If you push a new version of a PR, please add a comment about the new
  version. Notifications aren't sent for commits, so it's easy to miss updates
  without an explicit comment.

## Workflow

Getty uses the [Git Flow](https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow) model for its development. Essentially, what that means is:

- The `main` branch is strictly for releases. __Do not work on or branch off of it.__

- The `develop` branch is an integration branch for features and fixes. __Do not work on it.__

- Features are developed on `feature/<name>` branches, which branch off of `develop`.

- Fixes are developed on `fix/<name>` branches, which branch off of `develop`.