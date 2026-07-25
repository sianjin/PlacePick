fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios test

```sh
[bundle exec] fastlane ios test
```

Run tests

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Upload to TestFlight (internal testers)

### ios beta_external

```sh
[bundle exec] fastlane ios beta_external
```

Upload to TestFlight and distribute to external testers

### ios release

```sh
[bundle exec] fastlane ios release
```

Submit the latest TestFlight build for App Store review

### ios release_full

```sh
[bundle exec] fastlane ios release_full
```

Build, upload, and submit a fresh build to the App Store

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
