resource "tls_private_key" "tf-key" {
  algorithm   = "RSA"
}

resource "local_file" "key-file" {
    content     = tls_private_key.tf-key.private_key_pem
    filename = "tf-key.pem"
    file_permission = "0400"
}