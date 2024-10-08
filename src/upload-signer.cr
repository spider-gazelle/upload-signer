module UploadSigner
  VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify.downcase }}

  class SignerException < Exception
  end

  enum StorageType
    S3
    Azure
    Google
  end

  def self.signer(type : StorageType, account_name : String, account_key : String, region : String? = nil, endpoint : String? = nil)
    Storage.signer(type, account_name, account_key, region, endpoint)
  end

  def self.s3(account_name : String, account_key : String, region : String? = nil, endpoint : String? = nil)
    signer(StorageType::S3, account_name, account_key, region, endpoint)
  end

  def self.azure(account_name : String, account_key : String)
    signer(StorageType::Azure, account_name, account_key)
  end

  def self.azure(connection_string : String)
    AzureStorage.new(connection_string)
  end
end

require "./storage"
