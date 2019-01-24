module Support
  class S3Helper
    LOCALSTACK_ENDPOINT = 'http://localstack:4572'.freeze
    S3_ENDPOINT = 'https://s3.amazonaws.com'.freeze
    USER_FILTERS_KEY = 'user_filters'
    USERS_KEY = 'users_brick_input'
    REGION = 'us-east-1'

    class << self
      include GoodData::Environment::ConnectionHelper

      def upload_file(file, object_name)
        bucket_name = SECRETS[:s3_bucket_name]
        s3_endpoint = if GoodData::Environment::LOCALSTACK
                        Support::S3Helper::LOCALSTACK_ENDPOINT
                      else
                        Support::S3Helper::S3_ENDPOINT
                      end

        s3 = Aws::S3::Resource.new(
          access_key_id: SECRETS[:s3_access_key_id],
          secret_access_key: SECRETS[:s3_secret_access_key],
          endpoint: s3_endpoint,
          region: REGION,
          force_path_style: true
        )

        bucket = s3.bucket(bucket_name)
        bucket = s3.create_bucket(bucket: bucket_name) unless bucket.exists?
        obj = bucket.object(object_name)
        obj.upload_file(Pathname.new(file))

        {
          s3_bucket: bucket_name,
          s3_endpoint: s3_endpoint,
          s3_access_key: SECRETS[:s3_access_key_id],
          s3_secret_access_key: SECRETS[:s3_secret_access_key]
        }
      end
    end
  end
end
