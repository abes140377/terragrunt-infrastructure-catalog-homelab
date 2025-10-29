locals {
  use_path_style = true
  skip_credentials_validation = true
  region = "eu-central-1"
  endpoint  = "http://minio.home.sflab.io:9000"
  prefix  = "examples-terragrunt"
  access_key = get_env("MINIO_ACCESS_KEY")
  secret_key = get_env("MINIO_SECRET_KEY")
}
