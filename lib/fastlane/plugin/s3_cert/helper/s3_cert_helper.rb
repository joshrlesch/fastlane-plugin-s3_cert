require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?("UI")

  module Helper
    class S3CertHelper
      def self.check_required_options(params)
        UI.user_error!("No KMS key id provided, please use kms_key_id: or with ENV['KMS_KEY_ID']") unless params[:kms_key_id].to_s.length > 0
        UI.user_error!("No bucket provided, please use bucket: or with ENV['S3_BUCKET']") unless params[:bucket].to_s.length > 0
        UI.user_error!("No object_key provided, please use object_key: or with ENV['S3_OBJECT_KEY']") unless params[:object_key].to_s.length > 0

        if params[:aws_access_key_id]
          UI.user_error!("No secret access key provided, please use aws_secret_access_key: or with ENV['AWS_SECRET_ACCESS_KEY']") unless params[:aws_secret_access_key].to_s.length > 0
          UI.user_error!("No region provided, please use aws_region: or with ENV['AWS_REGION']") unless params[:aws_region].to_s.length > 0
        end

        if params[:aws_secret_access_key]
          UI.user_error!("No access key id provided, please use aws_access_key_id: or with ENV['AWS_ACCESS_KEY_ID']") unless params[:aws_access_key_id].to_s.length > 0
          UI.user_error!("No region provided, please use aws_region: or with ENV['AWS_REGION']") unless params[:aws_region].to_s.length > 0
        end
      end
    end
  end
end
