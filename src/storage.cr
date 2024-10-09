module UploadSigner
  abstract class Storage
    UPLOAD_THRESHOLD = 5_000_000 # 5mb

    alias SignResp = NamedTuple(verb: String, url: String, headers: Hash(String, String))

    def self.signer(type : StorageType, account_name : String, account_key : String, region : String? = nil, endpoint : String? = nil)
      case type
      in .s3?
        AmazonS3.new(account_name, account_key, region, endpoint: endpoint)
      in .azure?
        AzureStorage.new(account_name, account_key)
      in .google?
        raise SignerException.new("not implemented")
      end
    end

    getter? multipart : Bool = false

    # Create a signed URL for access a private file
    abstract def get_object(bucket : String, filename : String, expires = 5 * 60)
    # Creates a new upload request (either single shot or multi-part)
    abstract def sign_upload(bucket : String, object_key : String, size : Int64, md5 : String, mime = "binary/octet-stream", permissions = :public, expires = 5 * 60, headers = {} of String => String) : SignResp
    # Returns the request to get the parts of a resumable upload
    abstract def get_parts(bucket : String, object_key : String, size : Int64, resumable_id : String, headers = {} of String => String)

    abstract def set_part(bucket : String, object_key : String, size : Int64, md5 : String?, part : String, resumable_id : String, headers = {} of String => String)
    abstract def commit_file(bucket : String, object_key : String, resumable_id : String, headers = {} of String => String)
    abstract def delete_file(bucket : String, object_key : String, resumable_id : String? = nil)
    abstract def name : String
  end
end

require "./backends/*"
