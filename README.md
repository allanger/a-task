# Password generator with terraform

## A couple of notes

The module is not 100% idempotent, but it designed in a way that it shouldn't affect the state of the infrastructure.

It's only possible to rotate the "backup" password as stated in the task, and the rotation is triggered by a variable that is passed to the module. If the value of that input is persisted to `true`, on each `terraform apply` the backup password will be regenerated.

But because of the **active/backup** logic, the active password is always set in the target service (in this case in a file), so even if the backup password is constantly regenerated, the service will be accessible with the password that was set during the last real change.

In order to make the swapping and rotating impossible at the same run, the root module is sending the `currently_active_password` variable to the target module. If this file doesn't exist, the value is set to 0, and the validation is disabled.

Password generator is checking if `currently_active_password` is the same as `active_password` (which in this case a desired active password), and if they are not equal, is not allowing `rotate` to be set to `true`

```hcl
  lifecycle {
    precondition {
      condition     = var.currently_active_password == 0 || var.currently_active_password == var.active_password || !var.rotate
      error_message = "Rotating and swapping at the same time are not allowed"
    }
  }
```

Passing the `currently_active_password` is a responsibility of the root module, and hence it's value is not used for detecting which password is currently active.

## Testing

I've created a script that is checking possible cases and this script is executed on osx and Linux github runners to ensure cross-platform support.

To run it locally, simple execute `./test.sh`
