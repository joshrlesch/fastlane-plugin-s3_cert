require 'fastlane/action'
require 'fastlane_core/cert_checker'
require_relative '../helper/s3_cert_helper'


module Fastlane
  module Actions
    class S3CertAction < Action
      def self.run(params)
        require 'aws-sdk-s3'
        require 'spaceship'
        Helper::S3CertHelper.check_required_options(params)
        access_key = params[:aws_access_key_id]
        secret_key = params[:aws_secret_access_key]
        region = params[:aws_region]
        s3_bucket = params[:bucket]
        s3_object_key = params[:object_key]
        kms_key_id = params[:kms_key_id]
        spaceship_username = params[:spaceship_username]

        UI.user_error!("No spaceship username provided, please use spaceship_username: or with ENV['SPACESHIP_USERNAME']") unless spaceship_username.to_s.length > 0

        if access_key
          Aws.config.update({
            region: region,
            credentials: Aws::Credentials.new(access_key, secret_key)
          })
        end
        s3 = Aws::S3::Resource.new
        kms = Aws::KMS::Client.new
        Spaceship.login(spaceship_username)
        
        if params[:spaceship_team_id]
          Spaceship.select_team(team_id: params[:spaceship_team_id])
        end

        client = Aws::S3::Encryption::Client.new(
          kms_key_id: kms_key_id,
          kms_client: kms
        )

        resp = s3.bucket(s3_bucket).objects(prefix: s3_object_key).collect(&:key)
        Dir.mktmpdir { |dir|
          for r in resp
            if File.extname(r).include? "cer"
              obj = s3.bucket(s3_bucket).object(r)
              obj.get(response_target: File.join(dir, File.basename(r)))
              client.get_object(
                response_target: File.join(dir, File.basename(r)),
                bucket: s3_bucket,
                key: File.join(s3_object_key, File.basename(r))
              )

              raw_cert = File.read(File.join(dir, File.basename(r)))
              parsed_cert = OpenSSL::X509::Certificate.new(raw_cert)

              uid = parsed_cert.subject.to_s.match(/UID=([A-Z0-9]+)/).captures[0]
              found = false
              # Would really like to make this call once
              Spaceship.certificate.all.find do |cert|
                if cert.owner_id == uid
                  UI.success("Found the cert #{r} in the Apple Developer Portal.")
                  now = Time.now
                  if parsed_cert.not_after - now < 0
                    UI.important("The cert: #{r} with UID: #{uid} is expired and wont be installed. Create a new one and upload it to s3")
                    break
                  end
                  found = true
                end
              end

              unless found
                UI.important("Unable to find cert: #{r} in the Apple Developer Portal, skipping install..")
                next
              end
              
              if FastlaneCore::CertChecker.installed?(File.join(dir, File.basename(r)), in_keychain: params[:keychain_name])
                UI.important("Certificate '#{File.join(dir, File.basename(r))}' is already installed on this machine")
              else
                if params[:delete_expired_cert]
                  UI.message("Checking to see if its expired..")
                  expired_cert = self.check_for_expired_cert(File.join(dir, File.basename(r)), params[:keychain_name])
                  if expired_cert
                    self.delete_cert(expired_cert)
                  else
                    UI.message("Certificate is valid!")
                  end
                end
                keychain_path = FastlaneCore::Helper.keychain_path(params[:keychain_name])
                FastlaneCore::KeychainImporter.import_file(File.join(dir, File.basename(r)), 
                                                          keychain_path, 
                                                          keychain_password: params[:keychain_password], 
                                                          output: FastlaneCore::Globals.verbose?)

                UI.success("Installed cert: '#{File.join(dir, File.basename(r))}'")
              end
            end
          end
        }
      end

      def self.check_for_expired_cert(path, keychain)
        cert_name = OpenSSL::X509::Certificate.new(File.read(path)).subject.to_s.match(/CN=(.*?)\//)[1]
        installed_certs = sh("security find-identity -p codesigning #{keychain}")
        installed_certs.split("\n").each do |c|
          if c.include?("CSSMERR_TP_CERT_EXPIRED")
            expired_cert_name = c.match(/\"(.*)\"/)[1]
            if expired_cert_name == cert_name
              UI.important("#{cert_name} is expired")
              return expired_cert_name
            else
              return nil
            end
          end
        end
      end

      def self.delete_cert(cert_name)
        UI.important("Deleting cert #{cert_name}")
        sh("security delete-certificate -c '#{cert_name}'")
      end

      def self.description
        "Pull Certs from s3 and install them into keychain."
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
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :object_key,
                                       env_name: "S3_OBJECT_KEY",
                                       description: "S3 object key",
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :kms_key_id,
                                       env_name: "KMS_KEY_ID",
                                       description: "KMS key id to encrypt and decrypt files in S3",
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :spaceship_team_id,
                                       env_name: "SPACESHIP_TEAM_ID",
                                       description: "Team id to select dev portal team if on multiple teams",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :spaceship_username,
                                       env_name: "SPACESHIP_USERNAME",
                                       description: "Username required for Spaceship to log into the Apple Dev Portal",
                                       optional: false,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :keychain_password,
                                       env_name: "KEYCHAIN_PASSWORD",
                                       description: "Password to keychain",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :keychain_name,
                                       env_name: "KEYCHAIN_NAME",
                                       description: "Name of keychain where certs will be installeds",
                                       default_value: "login.keychain",
                                       optional: true,
                                       type: String),
          FastlaneCore::ConfigItem.new(key: :delete_expired_cert,
                                       description: "Option to delete existing cert if expired",
                                       optional: true,
                                       default_value: false,
                                       is_string: false)

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
