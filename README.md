# Uploadsigner

Crystal shard to provide API for generating pre-signed URLs for file uploads to cloud storage. This shard was created to provide direct to cloud uploads using browser functionality to [PlaceOS](https://github.com/PlaceOS/PlaceOS), but is designed to be generic and can be used with any library and/or application.

> Currently only supports Amazon S3


Benefits of moving file uploads functionality near to end user are:

* Off-loads processing to client machines
* Better guarantees against upload corruption
* file hashing on the client side
* Upload results are guaranteed
* user is always aware of any failures in the process
* Detailed progress and control over the upload

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     upload-signer:
       github: spider-gazelle/upload-signer
   ```

2. Run `shards install`

## Usage

```crystal
require "upload-signer"
```

## Development

```crystal
crystal spec
```
## Contributing

1. Fork it (<https://github.com/spider-gazelle/upload-signer/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

