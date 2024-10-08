require "azblob"
require "log"

module UploadSigner
  class AzureStorage < Storage
    Log = ::Log.for(self)
    getter client : AZBlob::Client

    def initialize(account_name : String, account_key : String, endpoint : String? = nil)
      config = if ep = endpoint
                 AZBlob::Client::Config.new(account_name, account_key, ep)
               else
                 AZBlob::Client::Config.with_shared_key(account_name, account_key)
               end
      @client = AZBlob::Client.new(config)
    end

    def initialize(connection_string : String)
      @client = AZBlob.client(connection_string)
    end

    def get_object(bucket : String, filename : String, expires = 5 * 60)
      client.blob_sas(bucket, filename, expires.seconds)
    end

    def sign_upload(bucket : String, object_key : String, size : Int64, md5 : String, mime = "binary/octet-stream", permissions = :public, expires = 5 * 60, headers = {} of String => String) : SignResp
      # headers = headers.transform_keys { |key| key.downcase.starts_with?("x-ms-blob") ? key.downcase : "x-ms-blob-#{key.downcase}" }
      @multipart = size > AZBlob::MaxUploadBlobBytes
      headers.put("x-ms-blob-type", "BlockBlob") { } unless multipart?
      headers.put("x-ms-blob-content-type", mime) { }
      headers.put("x-ms-blob-content-md5", md5) { }

      url = multipart? ? "" : client.blob_sas(bucket, object_key, expires.seconds, AZBlob::BlobPermissions.write | AZBlob::BlobPermissions.create)
      {verb: "PUT", url: url, headers: headers}
    end

    def get_parts(bucket : String, object_key : String, size : Int64, resumable_id : String, headers = {} of String => String)
      @multipart = true
      sas = get_object(bucket, object_key)
      {verb: "GET", url: "#{sas}&comp=blocklist&blocklisttype=all", headers: headers}
    end

    def set_part(bucket : String, object_key : String, size : Int64, md5 : String?, part : String, resumable_id : String, headers = {} of String => String)
      sas = get_object(bucket, object_key)
      {verb: "PUT", url: "#{sas}&comp=block&blockid=#{URI.encode_path_segment(part)}", headers: headers}
    end

    def commit_file(bucket : String, object_key : String, resumable_id : String, headers = {} of String => String)
      sas = get_object(bucket, object_key)
      {verb: "PUT", url: "#{sas}&comp=blocklist", headers: headers}
    end

    def delete_file(bucket : String, object_key : String, resumable_id : String? = nil)
      client.delete_blob(bucket, object_key)
    rescue ex : Exception
      Log.error(exception: ex) { {message: "Unable to delete blob", container: bucket, blob: object_key, block_id: resumable_id} }
    end

    def name : String
      "AzureStorage"
    end
  end
end
