# capistrano-env

Manage a `.env` file stored on S3 for deployment with `capistrano`.

## Installation

Add this line to your application's Gemfile:

    gem 'capistrano-env'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install capistrano-env

## Usage

Require `capistrano/env` in your `Capfile`.

```ruby
require 'capistrano/env'
```

Set the `aws_credentials` and `env_bucket_name` properties in your configuration:

```ruby
set :aws_credentials, {
  aws_access_key_id: 'xxx'
  aws_secret_access_key: 'xxx'
}
set :env_bucket_name, 'my-bucket'
```

`env_bucket_name` will default to the `ENV` variables `AWS_BUCKET_NAME`,
`BUCKET_NAME` or `FOG_DIRECTORY`. If the environment variables
`AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` are set, then the `aws-sdk`
will use them to authenticate so `aws_credentials` will not need to be set.

The object key that will be used defaults to `#{application}-#{stage}` or just
`application` if `stage` is not defined. You can set `env_object_key` to
customize it.

With all the configuration in place, you can begin to set, unset and read values.

```shell
$ cap env:set FOO=bar BAZ=buz

$ cap env:read
FOO=bar
BAZ=buz

$ cap env:unset FOO BAZ
```

The `env:set` and `env:unset` tasks are followed by `env:export` which commits
your changes to S3 and uploads the to `#{latest_release}/.env`.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
