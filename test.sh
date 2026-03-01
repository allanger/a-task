#/usr/bin/bash 

set -e

# Make sure state is not there
rm -f  ./terraform.tfstate
rm -f ./terraform.tfstate.backup

terraform init -upgrade

echo "INFO: Testing a first run"
terraform apply -auto-approve
PASSWORD_CURRENT_1=$(jq .test passwords.json)

echo "INFO: Testing a run withouth changes"
terraform apply -auto-approve
PASSWORD_NEW_1=$(jq .test passwords.json)

if [[ "${PASSWORD_CURRENT_1}" != "${PASSWORD_NEW_1}" ]]; then
  echo "ERROR: Password should not be changed"
  exit 1
fi

echo "INFO: Switch to a second password"
export TF_VAR_active_password=2
terraform apply -auto-approve
PASSWORD_NEW_2=$(jq .test passwords.json)

if [[ "${PASSWORD_CURRENT_1}" = "${PASSWORD_NEW_2}" ]]; then
  echo "ERROR: Password should be changed"
  exit 1
fi
PASSWORD_CURRENT_2="${PASSWORD_NEW_2}"

echo "INFO: Testing a run withouth changes"
export TF_VAR_active_password=2
terraform apply -auto-approve
PASSWORD_NEW_2=$(jq .test passwords.json)

if [[ "${PASSWORD_CURRENT_2}" != "${PASSWORD_NEW_2}" ]]; then
  echo "ERROR: Password should not be changed"
  exit 1
fi

echo "INFO: Rotate the backup password (1)"
export TF_VAR_active_password=2
export TF_VAR_rotate=true
terraform apply -auto-approve
PASSWORD_NEW_2=$(jq .test passwords.json)

if [[ "${PASSWORD_CURRENT_2}" != "${PASSWORD_NEW_2}" ]]; then
  echo "ERROR: Password should not be changed"
  exit 1
fi

echo "INFO: Switching to the password 1"
export TF_VAR_active_password=1
export TF_VAR_rotate=false
terraform apply -auto-approve
PASSWORD_NEW_1=$(jq .test passwords.json)

if [[ "${PASSWORD_CURRENT_1}" = "${PASSWORD_NEW_1}" ]]; then
  echo "ERROR: Password should be rotated"
  exit 1
fi
PASSWORD_CURRENT_1="${PASSWORD_NEW_1}"

echo "INFO: Switching to the password 2"
export TF_VAR_active_password=2
export TF_VAR_rotate=false
terraform apply -auto-approve
PASSWORD_NEW_2=$(jq .test passwords.json)

if [[ "${PASSWORD_CURRENT_1}" = "${PASSWORD_NEW_2}" ]]; then
  echo "ERROR: Password should be switched"
  exit 1
fi

if [[ "${PASSWORD_CURRENT_2}" != "${PASSWORD_NEW_2}" ]]; then
  echo "ERROR: Password (2) should not be rotated"
  exit 1
fi
PASSWORD_CURRENT_2="${PASSWORD_NEW_2}"


echo "INFO: Switching to the password 1"
export TF_VAR_active_password=1
export TF_VAR_rotate=false
terraform apply -auto-approve
PASSWORD_NEW_1=$(jq .test passwords.json)

if [[ "${PASSWORD_CURRENT_1}" != "${PASSWORD_NEW_1}" ]]; then
  echo "ERROR: Password should not be rotated"
  exit 1
fi
PASSWORD_CURRENT_1="${PASSWORD_NEW_1}"

if [[ "${PASSWORD_CURRENT_1}" = "${PASSWORD_CURRENT_2}" ]]; then
  echo "ERROR: Password should be changed"
  exit 1
fi

echo "INFO: Rotating the backup password (2)"
export TF_VAR_active_password=1
export TF_VAR_rotate=true
PASSWORD_NEW_1=$(jq .test passwords.json)

terraform apply -auto-approve
if [[ "${PASSWORD_CURRENT_1}" != "${PASSWORD_NEW_1}" ]]; then
  echo "ERROR: Password (1) should not be changed"
  exit 1
fi

echo "INFO: Switching to the password 2"
export TF_VAR_active_password=2
export TF_VAR_rotate=false
terraform apply -auto-approve
PASSWORD_NEW_2=$(jq .test passwords.json)

if [[ "${PASSWORD_CURRENT_2}" = "${PASSWORD_NEW_2}" ]]; then
  echo "ERROR: Password should be rotated"
  exit 1
fi
PASSWORD_CURRENT_2="${PASSWORD_NEW_2}"

echo "INFO: Testing both swapping and rotating"
export TF_VAR_active_password=1
export TF_VAR_rotate=true

if terraform apply -auto-approve ; then
  echo "ERROR: It shouldn't be possible to rotate and swap"
  exit 1
fi

echo "INFO: Cleaning up"
terraform destroy -auto-approve
rm -f  ./terraform.tfstate
rm -f ./terraform.tfstate.backup
