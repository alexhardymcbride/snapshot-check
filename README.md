# snapshot-check
This script connects to a vCenter server, checks for both open snapshots and VMs with "Consolidation needed" flags, and emails a list of these VMs to a specified recipient.

The server running the script needs to have VMware's PowerCLI 6.0 or later installed.

This script is intended to be run as a scheduled task, with an account that has the following permissions:
1. Logon as a batch job on the server running the script.
2. At least read-only access to vCenter.
