#!/bin/bash

# This script will output a list of randomly generated passwords

# A random number as a password.
PASSWORD="${RANDOM}"
echo "${PASSWORD}"

# Three random numbers.
PASSWORD="${RANDOM}${RANDOM}${RANDOM}"
echo "${PASSWORD}"

# Use date/time as basis for password.
PASSWORD=$(date +%S)
echo "${PASSWORD}"
