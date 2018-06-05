module Support
  class S3Helper
    S3_ENDPOINT = 'http://localstack:4572'.freeze
    BUCKET_NAME = 'testbucket'.freeze

    class << self
      def upload_file(file, object_name)
        s3 = Aws::S3::Resource.new(access_key_id: 'foo',
                                   secret_access_key: 'foo',
                                   endpoint: S3_ENDPOINT,
                                   region: 'us-west-2',
                                   force_path_style: true)

        bucket = s3.bucket(BUCKET_NAME)
        bucket = s3.create_bucket(bucket: BUCKET_NAME) unless bucket.exists?
        obj = bucket.object(object_name)
        obj.upload_file(Pathname.new(file))
      end
    end
  end
end
