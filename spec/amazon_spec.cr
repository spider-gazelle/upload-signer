require "./spec_helper"

describe UploadSigner::AmazonS3 do
  it "should perform AmazonS3 request signing for getting object" do
    s3 = UploadSigner.s3("AhhSVNklLpaQhpweyU6i", "3mbWqbZ1bjF47nTZD1KHaWUaT4cLkngZ1mFGH3k3")
    result = s3.get_object("test-bucket", "test.jpg")
    uri = URI.parse(result)
    uri.host.should eq("s3-us-east-1.amazonaws.com")
    uri.port.should be_nil
    uri.path.should eq("/test-bucket/test.jpg")
    params = URI::Params.parse(uri.query || "")
    params["X-Amz-Expires"]?.should eq("300")
    params["X-Amz-Algorithm"]?.should eq("AWS4-HMAC-SHA256")
    params["X-Amz-Credential"]?.should eq("AhhSVNklLpaQhpweyU6i/#{Time.utc.to_s("%Y%m%d")}/us-east-1/s3/aws4_request")
    params["X-Amz-Date"]?.should eq(Time.utc.to_s("%Y%m%dT%H%M%SZ"))
    params["X-Amz-SignedHeaders"]?.should eq("host")
    params["X-Amz-Signature"]?.should_not be_nil
  end

  it "should perform AmazonS3 request signing for custom endpoints" do
    s3 = UploadSigner.s3("AhhSVNklLpaQhpweyU6i", "3mbWqbZ1bjF47nTZD1KHaWUaT4cLkngZ1mFGH3k3", endpoint: "http://127.0.0.1:9000")
    result = s3.get_object("test-bucket", "test.jpg")
    uri = URI.parse(result)
    uri.host.should eq("127.0.0.1")
    uri.port.should eq(9000)
    uri.path.should eq("/test-bucket/test.jpg")
    params = URI::Params.parse(uri.query || "")
    params["X-Amz-Expires"]?.should eq("300")
    params["X-Amz-Algorithm"]?.should eq("AWS4-HMAC-SHA256")
    params["X-Amz-Credential"]?.should eq("AhhSVNklLpaQhpweyU6i/#{Time.utc.to_s("%Y%m%d")}/us-east-1/s3/aws4_request")
    params["X-Amz-Date"]?.should eq(Time.utc.to_s("%Y%m%dT%H%M%SZ"))
    params["X-Amz-SignedHeaders"]?.should eq("host")
    params["X-Amz-Signature"]?.should_not be_nil
  end

  it "should perform AmazonS3 request signing for uploading object" do
    s3 = UploadSigner.s3("AhhSVNklLpaQhpweyU6i", "3mbWqbZ1bjF47nTZD1KHaWUaT4cLkngZ1mFGH3k3")
    res = s3.sign_upload("test-bucket", "test.jpeg", 70593, "0rCswYQrAETaZ/PvH0zUAA==")

    res["verb"].should eq("PUT")
    res["url"].size.should be > 0
    res["headers"].size.should be > 0
    res["headers"]["x-amz-acl"].should eq("public-read")
    res["headers"]["Content-MD5"].should eq("0rCswYQrAETaZ/PvH0zUAA==")
    res["headers"]["Content-Type"].should eq("binary/octet-stream")
  end

  it "should perform AmazonS3 request signing for uploading multi-part object" do
    s3 = UploadSigner.s3("AhhSVNklLpaQhpweyU6i", "3mbWqbZ1bjF47nTZD1KHaWUaT4cLkngZ1mFGH3k3")
    res = s3.sign_upload("test-bucket", "test.jpeg", 70593_000, "0rCswYQrAETaZ/PvH0zUAA==")
    s3.multipart?.should be_true
    res["verb"].should eq("POST")
    res["url"].size.should be > 0
    res["headers"].size.should be > 0
    res["headers"]["x-amz-acl"].should eq("public-read")
  end
end
