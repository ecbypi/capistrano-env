require 'capistrano'
require "capistrano/env/version"

if Capistrano::Configuration.instance
  Capistrano::Configuration.instance.load do
    require 'aws'

    _cset :aws_credentials, {}
    _cset(:s3) { AWS::S3.new(aws_credentials) }

    _cset :env_bucket_name do
      name = ENV['AWS_BUCKET_NAME'] || ENV['BUCKET_NAME'] || ENV['FOG_DIRECTORY']
      if name.nil?
        $stdout.puts <<-MESSAGE
:env_bucket_name must be specified explicitly if not in any of the ENV
variables:
* AWS_BUCKET_NAME
* BUCKET_NAME
* FOG_DIRECTORY
        MESSAGE
        exit 1
      end

      name
    end

    _cset :env_bucket do
      bucket_name = fetch(:env_bucket_name)

      bucket = s3.buckets[bucket_name]
      bucket = s3.buckets.create(bucket_name) unless bucket.exists?
      bucket
    end

    _cset :env_object_key do
      stage_name = fetch(:stage, nil)
      app_name = fetch(:application)

      stage_name ? "#{app_name}-#{stage_name}" : app_name
    end

    _cset :env_object do
      fetch(:env_bucket).objects[fetch(:env_object_key)]
    end

    _cset :env_hash do
      content = fetch(:env_object).read rescue ""
      Hash[content.split(/\n/).map { |line| line.split('=', 2) }]
    end

    namespace :env do
      def using_capistrano_multistage?
        stage_name = fetch(:stage, nil)
        default_stage_name = fetch(:default_stage, nil)

        stage_name && default_stage_name && stage_name.to_s != default_stage_name.to_s
      end

      desc <<-DOC
        Reads the .env file from S3.
      DOC
      task :read do
        begin
          $stdout.puts fetch(:env_object).read
        rescue
          $stdout.puts "the object #{fetch(:env_object_key)} in bucket #{fetch(:env_bucket_name)} does not exist, set some values first"
        end
      end

      desc "Set a value"
      task :set do
        pairs = fetch(:env_hash)

        ARGV.shift

        if using_capistrano_multistage?
          ARGV.shift
        end

        ARGV.map do |pair|
          key, value = pair.split('=', 2)
          pairs[key] = value
        end
      end

      desc <<-DOC
        Persists any changes made to the .env file and uploads it to the instances via
        scp.
      DOC
      task :export do
        pairs = fetch(:env_hash)
        object = fetch(:env_object)

        content = pairs.map { |key, value| "#{key}=#{value}" }.join("\n") << "\n"

        object.write content
        put content, "#{latest_release}/.env", via: :scp
      end

      desc <<-DOC
        Unset values from the .env file. Has the slight drawback that the recommended
        usage causes capistrano to print an error about being unable to find tasks with
        the name of the environment variable(s) being unset.
      DOC
      task :unset do
        pairs = fetch(:env_hash)

        if using_capistrano_multistage?
          ARGV.shift
        end

        ARGV.shift
        ARGV.each { |key| pairs.delete(key) }
      end
    end

    after 'env:set', 'env:export'
    after 'env:unset', 'env:export'
    after 'deploy:finalize_update', 'env:export'
  end
end
