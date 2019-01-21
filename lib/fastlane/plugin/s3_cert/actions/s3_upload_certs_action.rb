require 'fastlane/action'
require 'fastlane_core/cert_checker'
require_relative '../helper/s3_cert_helper'

module Fastlane
  module Actions
    class S3UploadCertsAction < Action
      def self.run(params)
        require 'aws-sdk-s3'
        Helper::S3CertHelper.check_required_options(params)
        access_key = params[:aws_access_key_id]
        secret_key = params[:aws_secret_access_key]
        region = params[:aws_region]
        s3_bucket = params[:bucket]
        s3_object_key = params[:object_key]
        kms_key_id = params[:kms_key_id]

        if access_key
          Aws.config.update({
            region: region,
            credentials: Aws::Credentials.new(access_key, secret_key)
          })
        end

        kms = Aws::KMS::Client.new

        client = Aws::S3::Encryption::Client.new(
          kms_key_id: kms_key_id,
          kms_client: kms)

        files = Dir[File.join(params[:local_file_location], "*")]
        for f in files
            if File.extname(f).include? "cer"
              UI.important("Uploading: #{f}")
              File.open(f, 'rb') do |file|
                client.put_object(
                  body: file,
                  bucket: s3_bucket,
                  key: File.join(s3_object_key, File.basename(f))
                )
              end
            end
        end

        UI.message("Successfully uploaded all the certs in #{params[:local_file_location]}")
      end

      def self.description
        "Upload encrypted certs to s3"
      end

      def self.authors
        ["Josh Lesch"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "Store your certificates securely in s3 and pull down automatically when needed."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :aws_access_key_id,
                                       env_name: "AWS_ACCESS_KEY_ID",
                                       description: "Aws access key id",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :aws_secret_access_key,
                                       env_name: "AWS_SECRET_ACCESS_KEY",
                                       description: "Aws secret access key",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :aws_region,
                                       env_name: "AWS_REGION",
                                       description: "Aws region",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :bucket,
                                       env_name: "S3_BUCKET",
                                       description: "S3 bucket",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :object_key,
                                       env_name: "S3_OBJECT_KEY",
                                       description: "S3 object key",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :kms_key_id,
                                       env_name: "KMS_KEY_ID",
                                       description: "KMS key id to encrypt and decrypt files in S3",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :local_file_location,
                                       env_name: "FILE_LOCATION",
                                       description: "KMS key id to encrypt and decrypt files in S3",
                                       optional: true,
                                       type: String),
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        # [:ios, :mac, :android].include?(platform)
        true
      end
    end
  end
end