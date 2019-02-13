# Defining the values for the variables declared in "variables.tf" file

aws_access_key = "AKIAIWRMKQCAGUWH7OGA"
aws_secret_key = "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"
region = "us-east-2"
instance_type = "t2.micro"
ami_id = {
  us-east-1 = "ami-035be7bafff33b6b6"
  us-east-2 = "ami-0cd3dfa4e37921605"
}
key_name = "Ohio region key pair"
pub_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAmVH2cX7kMjmVMTpXsEFmeSGt96/NqVHs00ymA2yMLIOqQ9WpVnYE1C5GM9NC7tr3pUeWH37s0ih2KVVtU+D+rdZ7MEzQ4M/7m0I5xrYd6dT8Mhcc4it2OqPdBVMQDO0SK7uGm38KjSJxTWRjNIuoLPkO5UoFfnND0WU1eev2uEZBlfvlargF8mNtFEAEaqyHw5Ehcobe+R3SGDUNgqvvfCtNyXG9ArcNyYhNQ4F0rnGGGEz5jaYJGSvWdQzg8aP0DKsLzsAUNEYUjFvYPBeDnjflrDuII8zFTFeHiSviVg2yknoZ7JNFo98iO3eAaZXkL93sIM5Ao20d4cbFkHjoow== rsa-key-20190205"
vpc_cidr_range = "10.0.0.0/16"
pubsubs_cidr_range = {
    pubsub1 = "10.0.1.0/24"
    pubsub2 = "10.0.2.0/24"
}
prisubs_cidr_range = {
    prisub1 = "10.0.3.0/24"
    prisub2 = "10.0.4.0/24"
}