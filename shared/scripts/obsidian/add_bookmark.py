#!/usr/bin/env python

import sys

if len(sys.argv) < 5:
    exit(1)
bookmark_path = sys.argv[1]
bookmark_name = sys.argv[2]
bookmark_url = sys.argv[3]
bookmark_tags = sys.argv[4]

line = f"\n- [{bookmark_name}]({bookmark_url}):{bookmark_tags}"
# print(line)
with open(bookmark_path, "a") as f:
    f.write(line)
