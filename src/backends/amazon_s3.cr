require "awscr-s3"
require "awscr-signer"

module UploadSigner
  class AmazonS3
    UPLOAD_THRESHOLD = 5_000_000 # 5mb

    getter region : String
    getter? multipart : Bool = false

    def initialize(@aws_access_key : String, @aws_secret_key : String, region : String? = nil, @endpoint : String? = nil, @signer_version : Symbol = :v4)
      @region = region || "us-east-1"
      @signer = case @signer_version
                when :v4
                  Awscr::Signer::Signers::V4.new(
                    service: "s3",
                    region: @region,
                    aws_access_key: @aws_access_key,
                    aws_secret_key: @aws_secret_key
                  )
                when :v2
                  Awscr::Signer::Signers::V2.new(
                    service: "s3",
                    region: @region,
                    aws_access_key: @aws_access_key,
                    aws_secret_key: @aws_secret_key
                  )
                else
                  raise SignerException.new("Unknown signer version: #{@signer_version}")
                end
    end

    # Create a signed URL for access a private file
    def get_object(bucket : String, filename : String, expires = 5 * 60)
      filename = "/#{filename}" unless filename.starts_with?('/')
      res = presign_url(:get, bucket, filename, expires: expires)
      res[:url]
    end

    # Creates a new upload request (either single shot or multi-part)
    def sign_upload(bucket : String, object_key : String, size : Int64, md5 : String, mime = "binary/octet-stream", permissions = :public, expires = 5 * 60, headers = {} of String => String)
      unless headers.has_key?("x-amz-acl")
        headers["x-amz-acl"] = (permissions == :public) ? "public-read" : "private"
      end

      verb = :put
      params = {} of String => String?
      if size > UPLOAD_THRESHOLD
        params["uploads"] = nil
        verb = :post
        @multipart = true
      else
        headers["Content-MD5"] = md5
        headers["Content-Type"] = mime
        @multipart = false
      end
      presign_url(verb, bucket, object_key, params, expires, headers)
    end

    # Returns the request to get the parts of a resumable upload
    def get_parts(bucket : String, object_key : String, size : Int64, resumable_id : String, headers = {} of String => String)
      params = {"uploadId" => resumable_id}
      @multipart = true
      presign_url(:get, bucket, object_key, params, headers: headers)
    end

    def set_part(bucket : String, object_key : String, size : Int64, md5 : String?, part : String, resumable_id : String, headers = {} of String => String)
      headers["Content-MD5"] = md5 if md5 && !headers.has_key?("Content-MD5")
      headers["Content-Type"] = "binary/octet-stream"
      params = {"partNumber" => part, "uploadId" => resumable_id}
      presign_url(:put, bucket, object_key, params, headers: headers)
    end

    def commit_file(bucket : String, object_key : String, resumable_id : String, headers = {} of String => String)
      params = {"uploadId" => resumable_id}
      headers["Content-Type"] = "application/xml; charset=UTF-8"
      presign_url(:post, bucket, object_key, params, headers: headers)
    end

    def delete_file(bucket : String, object_key : String, resumable_id : String? = nil)
      client = Awscr::S3::Client.new(@region, @aws_access_key, @aws_secret_key, endpoint: @endpoint)
      resp = client.delete_object(bucket, object_key)
      unless resp
        client.abort_multipart_upload(bucket, object_key, resumable_id) unless resumable_id.nil?
      end
      true
    end

    def name : String
      "AmazonS3"
    end

    # :nodoc:
    private def endpoint : URI
      return URI.parse(@endpoint.to_s) if @endpoint
      return default_endpoint if @region == standard_us_region
      URI.parse("https://s3-#{@region}.amazonaws.com")
    end

    # :nodoc:
    private def standard_us_region
      "us-east-1"
    end

    # :nodoc:
    private def default_endpoint : URI
      URI.parse("https://s3.amazonaws.com")
    end

    # :nodoc
    private def presign_url(verb : Symbol, bucket : String, object : String, params = {} of String => String?, expires = 5 * 60, headers = {} of String => String)
      verb = verb.to_s.upcase
      request = build_request(verb, bucket, object, params, expires)
      headers.each do |k, v|
        request.query_params.add(k, v)
      end
      @signer.presign(request)

      url = String.build do |str|
        str << protocol
        {% if compare_versions(Crystal::VERSION, "0.36.0") < 0 %}
          str << request.host
        {% else %}
          str << request.hostname
        {% end %}
        str << ":#{port}" if port
        str << request.resource
      end
      {verb: verb, url: url, headers: headers}
    end

    # :nodoc
    private def build_request(method : String, bucket : String, object : String, params = {} of String => String?, expires = 5 * 60)
      headers = HTTP::Headers{"Host" => host}

      body = @signer_version == :v4 ? "UNSIGNED-PAYLOAD" : nil

      request = HTTP::Request.new(
        method,
        "/#{bucket}#{object}",
        headers,
        body
      )

      params.each do |k, v|
        request.query_params.add(k, v || "")
      end

      if @signer_version == :v4
        request.query_params.add("X-Amz-Expires", expires.to_s)
      else
        request.query_params.add("Expires", (Time.utc.to_unix + expires).to_s)
      end

      request
    end

    private def protocol
      return "https://" if @endpoint.nil? || endpoint.scheme == "https"
      "#{endpoint.scheme}://"
    end

    private def port
      return nil if @endpoint.nil?
      endpoint.port
    end

    private def host
      return "s3-#{@region}.amazonaws.com" if @endpoint.nil?
      h = endpoint.host if endpoint.host
      h += ":#{endpoint.port}" if h && endpoint.port
      h.nil? ? "s3-#{@region}.amazonaws.com" : h
    end
  end
end
