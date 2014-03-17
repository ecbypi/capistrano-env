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
      bucket = s3.buckets[env_bucket_name]
      bucket = s3.buckets.create(env_bucket_name) unless bucket.exists?
      bucket
    end

    _cset :env_object_key do
      if defined?(stage)
        "#{application}-#{stage}"
      else
        application
      end
    end

    namespace :env do
      _cset :object do
        env_bucket.objects[env_object_key]
      end

      _cset :pairs do
        content = object.read rescue ""
        Hash[content.split(/\n/).map { |line| line.split('=', 2) }]
      end

      desc <<-DOC
        Reads the .env file from S3.
      DOC
      task :read do
        begin
          $stdout.puts object.read
        rescue
          $stdout.puts "the object #{env_object_key} in bucket #{env_bucket_name} does not exist, set some values first"
        end
      end

      desc "Set a value"
      task :set do
        ARGV.shift

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
        object.write pairs.map { |key, value| "#{key}=#{value}" }.join("\n") << "\n"
        put object.read, "#{current_path}/.env", via: :scp
      end

      desc <<-DOC
        Unset values from the .env file. Has the slight drawback that the recommended
        usage causes capistrano to print an error about being unable to find tasks with
        the name of the environment variable(s) being unset.
      DOC
      task :unset do
        ARGV.shift

        ARGV.each { |key| pairs.delete(key) }
      end
    end

    after 'env:set', 'env:export'
    after 'env:unset', 'env:export'
    after 'deploy:finalize_update', 'env:export'
  end
end
