// This is supposed to be used for debugging.
// For multiple user management it would be more convenient
// to define directly in locals in my opinion
variable "active_password" {
  type    = number
  default = 1
}

// This is supposed to be used for debugging.
// For multiple user management it would be more convenient
// to define directly in locals in my opinion
variable "rotate" {
  type    = bool
  default = false
}

locals {
  // Support multiple user management
  users = {
    "test" = {
      active_password = var.active_password
      rotate          = var.rotate
    }
  }
  // This file is created by this module to persist the index
  // of a current active password
  // The logic makes the code not CD friendly, but if this logic
  // is replaced by some extrernal storage (maybe S3),
  // which is accessible by the runners, it can be used in CD
  filename = "${path.module}/users.json"
}

data "local_file" "index_storage" {
  // Only read the data if the file exists, otherwise it's
  // most probably the first run
  count    = fileexists(local.filename) ? 1 : 0
  filename = local.filename
}

terraform {}

module "passwords" {
  for_each        = local.users
  source          = "./module/"
  rotate          = try(each.value.rotate, false)
  active_password = try(each.value.active_password, 1)
  // Passing the currently active password
  // to prevent swapping and rotating at the same time
  currently_active_password = fileexists(local.filename) ? jsondecode(data.local_file.index_storage[0].content)[each.key] : 0
}

// This file is a target for the passwords, in real environment
// it would be replaced by a service that requires a password
resource "local_file" "passwords" {
  content = jsonencode({
    for k, u in local.users :
    k => module.passwords[k].active_password.password
  })
  filename = "${path.module}/passwords.json"
}

// The storage for indexes of currently active passwords
resource "local_file" "passwords_indexes" {
  content = jsonencode({
    for k, u in local.users :
    k => module.passwords[k].active_password.index
  })
  filename = "${path.module}/users.json"
}
