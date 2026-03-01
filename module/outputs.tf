output "active_password" {
  description = "the active password"
  value = {
    password = var.active_password == 1 ? random_password.password_1.result : random_password.password_2.result
    index    = var.active_password
  }
}
