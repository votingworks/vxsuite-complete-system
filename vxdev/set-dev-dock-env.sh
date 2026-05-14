#!/bin/bash
#

env_file="/vx/config/.env.local"

# Regardless of the final state of dev dock, delete the current
# var, if present
sed -i '/REACT_APP_VX_ENABLE_DEV_DOCK/d' $env_file

# Set the variables to enable/disable dev dock as requested
if [[ $1 == "yes" ]]; then
  echo "REACT_APP_VX_ENABLE_DEV_DOCK=TRUE" >> $env_file
else
  echo "REACT_APP_VX_ENABLE_DEV_DOCK=FALSE" >> $env_file
fi

exit 0
