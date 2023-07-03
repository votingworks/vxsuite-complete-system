#!/usr/bin/env bash

set -euo pipefail

# the extra space at the start of the regexp is to make this idempotent
sed -i 's/ errors=remount/ ro,errors=remount/' /etc/fstab
