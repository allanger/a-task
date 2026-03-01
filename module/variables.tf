variable "rotate" {
  type        = bool
  description = "If true, the backup password will be rotated"
  default     = false
}

variable "active_password" {
  description = "Which password should be set as active"
  type        = number
  validation {
    condition     = contains([1, 2], var.active_password)
    error_message = "only 1 and 2 can be set as an active password"
  }
}

variable "currently_active_password" {
  description = "Which password was set as active before applying"
  type        = number
  validation {
    condition     = contains([0, 1, 2], var.currently_active_password)
    error_message = "only 1 and 2 can be set as an active password, or 0 if currently_active_password is not used"
  }
}
