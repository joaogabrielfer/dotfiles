#!/usr/bin/env python

import sys
import re

if len(sys.argv) < 3:
    exit(1)
bookmark_path = sys.argv[1]
bookmark_name = sys.argv[2]

result = []
with open(bookmark_path, "r") as f:
    for line in f:
        line_name = re.search(r"\[.*\]", line)
        if line_name != None and line_name.group()[1:-1] == bookmark_name:
            url = re.search(r"\(.*\)", line)
            if url != None:
                print(url.group()[1:-1])
