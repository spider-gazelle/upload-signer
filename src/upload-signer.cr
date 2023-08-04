module UploadSigner
  VERSION = {{ `shards version "#{__DIR__}"`.chomp.stringify.downcase }}

  class SignerException < Exception
  end
end

require "./backends/**"
