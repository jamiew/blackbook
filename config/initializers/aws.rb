Aws.config.update({
  region: 'us-east-1',
  credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY']),
})

S3_BUCKET = if ENV['S3_BUCKET'].present?
  Aws::S3::Resource.new.bucket(ENV['S3_BUCKET'])
else
  nil
end
