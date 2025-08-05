#!/bin/bash
#

env_file="/vx/config/.env.local"

# Regardless of the final state of HWTA vars, delete the current
# vars, if present
sed -i '/REACT_APP_VX_ENABLE_HARDWARE_TEST_APP/d' $env_file

# Set the variables to enable HWTA if requested
if [[ $1 == "yes" ]]; then
  echo "REACT_APP_VX_ENABLE_HARDWARE_TEST_APP=TRUE" >> $env_file
  echo "REACT_APP_VX_ENABLE_HARDWARE_TEST_APP_INTERNAL_FUNCTIONS=TRUE" >> $env_file
fi

exit 0
