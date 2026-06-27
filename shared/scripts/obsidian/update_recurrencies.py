#!/usr/bin/env python

import sys
import re
from pathlib import Path
from datetime import datetime

if len(sys.argv) < 3:
    print("""ERRO: Argumentos insuficientes.
Insira o path para o dir de compras e o mês para fazer isso.

Ex:
./update_recurrencies.py ~/personal/notas/misc/dinheiro/compras/ 06/26 """)
    exit(1)
dir_path = sys.argv[1]
dir_path = Path(dir_path)
card_date = sys.argv[2]

number_of_new_files = 0

def handle_file(f_path, file_content, n):
    if n != -1:
        n -= 1
    global number_of_new_files

    today = int(datetime.now().strftime("%Y%m%d%H%M"))
    new_file_path = dir_path / f"{today + number_of_new_files}.md"
    while new_file_path.exists():
        number_of_new_files += 1
        new_file_path = dir_path / f"{today + number_of_new_files}.md"
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

    with open(new_file_path, "w") as f:
        f.write(file_content)

for file in dir_path.iterdir():
    if not file.is_file():
        continue
    with open(file, "r") as f:
        file_content = f.read()

    file_card_date = re.search(r"^card_date: (\d{2}/\d{2})$", file_content, re.MULTILINE)
    if file_card_date == None or file_card_date.group(1) != card_date:
        continue

    remaining_mo = re.search(r"^remaining_mo: (-?\d+)$", file_content, re.MULTILINE)
    if remaining_mo != None and int(remaining_mo.group(1)) != 0:
        handle_file(file, file_content, int(remaining_mo.group(1)))
