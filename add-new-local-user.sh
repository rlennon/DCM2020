#!/bin/bash
#
# This script creates a new user on the local machine.
# Supply a username as an argument for the scipt.
# A password will be automatically generated.
# The username, password and host for the account will be displayed.

# The script must be executed with superuser privileges.
if [[ "${UID}" -ne 0 ]]
then
echo 'Please run with sudo or as root.'
exit 1
fi

# If at least one argument isn't supplied, offer help.
if [[ "${#}" -lt 1 ]]
then
echo "Usage: ${0} USER_NAME [COMMENT]..."
echo 'Create an account on local system with USER_NAME.'
exit 1
fi

# The first parameter is user name
USER_NAME="${1}"

# The rest of parameter are for comments.
shift
COMMENT="${@}"

# Password generated.
PASSWORD=$(date +%s%N | sha256sum | head -c48)

# Create the user with a password.
useradd -c "${COMMENT}" -m ${USER_NAME}

# Check for useradd command was successful.
if [[ "${?}" -ne 0 ]]
then
echo 'The account could not be created.'
exit 1
fi

# Set password.
echo ${PASSWORD} | passwd --stdin ${USER_NAME}

# Check if password command succeeded.
if [[ "${?}" -ne 0 ]]
then
echo 'The password for the account could not be set.'
exit 1
fi

# Force password change.
passwd -e ${USER_NAME}

# Display the username, password and host where user was created.
echo
echo 'username:'
echo "${USER_NAME}"
echo
echo 'password:'
echo "${PASSWORD}"
echo
echo 'host:'
echo "${HOSTNAME}"

exit 0


