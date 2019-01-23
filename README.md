# s3_cert plugin

[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-s3_cert)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-s3_cert`, add it to your project by running:

```bash
fastlane add_plugin s3_cert
```

## About s3_cert

Store and install KMS encrypted Certs from s3.

To use this plugin, you will need read/write access to AWS S3 and a KMS key.

First create a bucket or object in an existing bucket to store your certs,

Generate a KMS key to encrypt the certs that are going to be uploaded.

Gather any certs you want uploaded into a directory. Currently only unencyrpted certs downloaded from the Dev Portal ending in `.cer` are supported.

You can then upload your certs by using the `s3_upload_cert` action

```ruby
    s3_upload_certs(
      bucket: "<your_bucket>",
      object_key: "<your_object_key>",
      kms_key_id: "<kms_key_id>",
      local_file_location: "/path/to/certs"
    )
```

To download and install certs, use the `s3_cert` action

```ruby
    s3_cert(
      spaceship_username: "<login_to_dev_portal>",
      bucket: "<your_bucket>",
      object_key: "<your_object_key",
      kms_key_id: "<kms_key_id>"
    )
```

## Example

Check out the [example `Fastfile`](fastlane/Fastfile) to see how to use this plugin. Try it by cloning the repo, running `fastlane install_plugins` and `bundle exec fastlane test`.

**Note to author:** Please set up a sample project to make it easy for users to explore what your plugin does. Provide everything that is necessary to try out the plugin in this project (including a sample Xcode/Android project if necessary)

## Run tests for this plugin

To run both the tests, and code style validation, run

```
rake
```

To automatically fix many of the styling issues, use
```
rubocop -a
```

## Issues and Feedback

For any other issues and feedback about this plugin, please submit it to this repository.

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
