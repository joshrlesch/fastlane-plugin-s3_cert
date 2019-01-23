describe Fastlane::Actions::S3CertAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The s3_cert plugin is working!")

      Fastlane::Actions::S3CertAction.run(nil)
    end
  end
end
