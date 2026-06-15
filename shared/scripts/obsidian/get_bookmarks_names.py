#!/usr/bin/env python

import sys
import re

if len(sys.argv) < 2:
    exit(1)
bookmark_path = sys.argv[1]

result = []
with open(bookmark_path, "r") as f:
    for line in f:
        name = re.search(r"\[.*\]", line)
        if name != None:
            result.append(name.group()[1:-1])

for item in result:
    print(item)
