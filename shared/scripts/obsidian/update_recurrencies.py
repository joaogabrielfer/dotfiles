#!/usr/bin/env python

import sys
import re
from pathlib import Path
from datetime import datetime

if len(sys.argv) < 2:
    print("Insira o path para o dir de compras")
    exit(1)
dir_path = sys.argv[1]
dir_path = Path(dir_path)

number_of_new_files = 0

def handle_file(f_path, n):
    if n != -1:
        n -= 1
    global number_of_new_files
    with open(f_path, "r") as f:
        file_content = f.read()

    today = datetime.now().strftime("%Y%m%d%H%M")
    file_name = str(int(today) + number_of_new_files)
    number_of_new_files += 1

    file_content = re.sub(r"(remaining_mo: )\d+", rf"\g<1>{n}", file_content)

    def increment_date(match):
        prefix = match.group(1)
        date_str = match.group(2)
        m, y = map(int, date_str.split('/'))

        new_m = m + 1
        new_y = y
        if new_m > 12:
            new_m = 1
            new_y += 1
        return f"{prefix}{new_m:02d}/{new_y:02d}"
    file_content = re.sub(r"(card_date: )(\d{2}/\d{2})", increment_date, file_content)

    with open(f"{dir_path}/{file_name}.md", "w") as f:
        f.write(file_content)

for file in dir_path.iterdir():
    if not file.is_file():
        continue
    with open(file, "r") as f:
        idx = 0
        for line in f:
            if idx == 8:
                number = re.search(r"-?[0-9]", line)
                if number != None and int(number.group()) != 0:
                    handle_file(file, int(number.group()))
                break
            idx += 1

