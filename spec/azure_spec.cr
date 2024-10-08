require "./spec_helper"

describe UploadSigner::AzureStorage do
  it "should perform AzureStorage request signing for getting object" do
    az = UploadSigner.azure("myteststorage", "Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==")
    result = az.get_object("test-bucket", "test.jpg")
    uri = URI.parse(result)
    uri.host.should eq(sprintf("%s.blob.core.windows.net", "myteststorage"))
    uri.port.should be_nil
    uri.path.should eq("/test-bucket/test.jpg")
    params = URI::Params.parse(uri.query || "")
    start = Time::Format::ISO_8601_DATE_TIME.parse(params["st"])
    expiry = Time::Format::ISO_8601_DATE_TIME.parse(params["se"])
    (expiry - start).should eq(300.seconds)
    params["sp"].should eq("rl")
    params["sig"]?.should_not be_nil
  end

  it "should perform AzureStorage request signing with connection string" do
    connect_str = %(DefaultEndpointsProtocol=http;AccountName=myteststorage;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/myteststorage)
    az = UploadSigner.azure(connect_str)
    result = az.get_object("test-bucket", "test.jpg")
    uri = URI.parse(result)
    uri.host.should eq("127.0.0.1")
    uri.port.should eq(10000)
    uri.path.should eq("/myteststorage/test-bucket/test.jpg")
    params = URI::Params.parse(uri.query || "")
    start = Time::Format::ISO_8601_DATE_TIME.parse(params["st"])
    expiry = Time::Format::ISO_8601_DATE_TIME.parse(params["se"])
    (expiry - start).should eq(300.seconds)
    params["sp"].should eq("rl")
    params["sig"]?.should_not be_nil
  end

  it "should perform AzureStorage request signing for uploading object" do
    az = UploadSigner.azure("myteststorage", "Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==")
    res = az.sign_upload("test-bucket", "test.jpeg", 70593, "0rCswYQrAETaZ/PvH0zUAA==")

    res["verb"].should eq("PUT")
    res["url"].size.should be > 0
    res["headers"].size.should be > 0
    res["headers"]["x-ms-blob-content-md5"].should eq("0rCswYQrAETaZ/PvH0zUAA==")
    res["headers"]["x-ms-blob-content-type"].should eq("binary/octet-stream")
  end

  it "should perform AzureStorage request signing for uploading multi-part object" do
    az = UploadSigner.azure("myteststorage", "Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==")
    res = az.sign_upload("test-bucket", "test.jpeg", 70593_0000, "0rCswYQrAETaZ/PvH0zUAA==")
    az.multipart?.should be_true
    res["verb"].should eq("PUT")
    res["url"].size.should eq(0)
    res["headers"].size.should be > 0
    res["headers"]["x-ms-blob-content-md5"].should eq("0rCswYQrAETaZ/PvH0zUAA==")
    res["headers"]["x-ms-blob-content-type"].should eq("binary/octet-stream")
  end
end
