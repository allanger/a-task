locals {
  // Rotate can only happen if the password is not active
  force_rotate_1 = var.active_password == 2 && var.rotate
  force_rotate_2 = var.active_password == 1 && var.rotate
}

resource "random_password" "password_1" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  // Rotate only when current is not active and rotate is set to true
  keepers = {
    // If we want to rotate, set the keeper to a timestamp(), that would force rotation
    rotate = local.force_rotate_1 && var.rotate ? timestamp() : "placeholder"
  }
  lifecycle {
    precondition {
      // If currently_active_password is 0, then the code is not aware of the currently active password,
      // otherwise we can make sure that we are not rotating and changing the password at the same time
      condition     = var.currently_active_password == 0 || var.currently_active_password == var.active_password || !var.rotate
      error_message = "Rotating and swapping at the same time are not allowed"
    }
  }
}

resource "random_password" "password_2" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  // Rotate only when current is not active and rotate is set to true
  keepers = {
    rotate = local.force_rotate_2 && var.rotate ? timestamp() : "placeholder"
  }
  lifecycle {
    precondition {
      condition     = var.currently_active_password == 0 || var.currently_active_password == var.active_password || !var.rotate
      error_message = "Rotating and swapping at the same time are not allowed"
    }
  }
}
