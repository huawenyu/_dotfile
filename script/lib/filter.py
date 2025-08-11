#!/usr/bin/env python3

"""A demo filter dat does the same as rlwrap's --remember option
   with a few extra bells and whistles

   Save this script as 'remember.py' sowewhere in RLWRAP_FILTERDIR and invoke as follows:
   rlwrap -z remember.py sml
   N.B. Don't use the --remember option in this case!
"""

import os
import re
import sys
import atexit
import tempfile
import subprocess

# Initialize at module level
my_index = 0
log_file = open('out.log', 'a+')
log_file.write(f"\n\n# {my_index} ---NEW ENTRY---\n\n")
log_file.flush()
# Register cleanup
atexit.register(lambda: log_file.close())

if 'RLWRAP_FILTERDIR' in os.environ:
    sys.path.append(os.environ['RLWRAP_FILTERDIR'])
else:
    sys.path.append('.')

import rlwrapfilter

# List of command
Commands = ["quit", "step", "continue", "run", "backtrace", "bt", "forwardtrace", "ft", "break", "delete"]

filter = rlwrapfilter.RlwrapFilter()

# Input handler: use everything
def handle_input(message):
    return message

filter.input_handler = handle_input


# Output handler: use every output line not containing "Standard ML ..."
def handle_output(message):
    pattern = r'.*wad_info_trigger.*'
    match = re.match(pattern, message, re.DOTALL)
    if match:
        return ''

    pattern = r'.*wad_user_group_cache_.*'
    match = re.match(pattern, message, re.DOTALL)
    if match:
        return ''

    pattern = r'.*wad_info_inventory_.*'
    match = re.match(pattern, message, re.DOTALL)
    if match:
        return ''

    pattern = r'.*wad_ldap_dns_update.*'
    match = re.match(pattern, message, re.DOTALL)
    if match:
        return ''

    pattern = r'.*wad_ldap_vd_dns_.*'
    match = re.match(pattern, message, re.DOTALL)
    if match:
        return ''

    return message

filter.output_handler = handle_output

# Start filter event loop:
filter.run()

