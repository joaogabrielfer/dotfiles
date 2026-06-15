#!/usr/bin/env python3
import os
import subprocess
import tempfile
import time
import json
import yaml
import urllib.parse
from datetime import datetime, timedelta

VAULT_PATH = os.path.expanduser("~/personal/notas")
BOOKMARKS_REL_PATH = "/misc/bookmarks.md"
BOOKMARKS_ABS_PATH = f"{VAULT_PATH}{BOOKMARKS_REL_PATH}"
TASKS_FILE_DIR = "/tasks/file"
TASKS_FILE_PATH = f"{VAULT_PATH}{BOOKMARKS_REL_PATH}"

def run_cmd(cmd, input_data=None):
    """Runs a shell command and returns the output."""
    try:
        if input_data:
            result = subprocess.run(cmd, input=input_data.encode(), stdout=subprocess.PIPE, shell=True)
        else:
            result = subprocess.run(cmd, stdout=subprocess.PIPE, shell=True)
        return result.stdout.decode().strip()
    except Exception as e:
        print(f"Command failed: {e}")
        return ""

def create_fuzzel_conf(keybindings):
    """Creates a temporary fuzzel config with custom keybindings."""
    conf = "include=~/.config/fuzzel/fuzzel.ini\n[colors]\nselection=\"#231e1eff\"\n[key-bindings]\n"
    for idx, key in enumerate(keybindings, 1):
        conf += f"custom-{idx}={key}\n"

    fd, path = tempfile.mkstemp()
    with os.fdopen(fd, 'w') as f:
        f.write(conf)
    return path

def show_fuzzel(options, conf_path, prompt="", extra_args=""):
    """Displays a fuzzel menu and returns the exit code and selected text."""
    options_str = "\n".join(options)
    lines = len(options)
    cmd = f"fuzzel --dmenu --lines {lines} --config='{conf_path}' {extra_args}"

    if prompt:
        cmd += f" --prompt='{prompt}'"
    else:
        cmd += " --hide-prompt"

    process = subprocess.run(cmd, input=options_str.encode(), stdout=subprocess.PIPE, shell=True)
    return process.returncode, process.stdout.decode().strip()

def abrir_e_focar(uri):
    """Opens an obsidian URI and focuses the window via Niri."""
    subprocess.Popen(["xdg-open", uri])
    time.sleep(0.3)

    windows_json = run_cmd("niri msg -j windows")
    if not windows_json: return

    try:
        windows = json.loads(windows_json)
        for win in windows:
            if win.get("app_id") and "obsidian" in win["app_id"].lower():
                run_cmd(f"niri msg action focus-window --id {win['id']}")
                break
    except json.JSONDecodeError:
        pass

def get_url():
    """Simulates Ctrl+Shift+C and grabs clipboard."""
    run_cmd("wlrctl keyboard type c modifiers CTRL,SHIFT")
    time.sleep(0.1)
    return run_cmd("wl-paste")

def handle_bookmarks():
    options = ["(S) Salvar", "(A) Abrir", "(E) Editar"]
    conf_path = create_fuzzel_conf(['s', 'a', 'e'])
    code, _ = show_fuzzel(options, conf_path)
    os.remove(conf_path)

    if code == 10:
        nome = run_cmd("fuzzel --dmenu --lines 2 --prompt='Insira o nome: '")
        if not nome: return
        url = get_url()
        run_cmd(f"~/.config/scripts/obsidian//add_bookmark.py '{BOOKMARKS_ABS_PATH}' '{nome}' '{url}' ''")

    elif code == 11:
        selected_name = run_cmd(f"~/.config/scripts/obsidian/get_bookmarks_names.py '{BOOKMARKS_ABS_PATH}' | fuzzel --dmenu --width 70")
        if not selected_name: return
        url = run_cmd(f"~/.config/scripts/obsidian/get_url_by_name.py '{BOOKMARKS_ABS_PATH}' '{selected_name}'")

        tab_id_out = run_cmd(f"tabctl list | grep '{url}'")
        if tab_id_out:
            tab_id = tab_id_out.split()[0]
            run_cmd(f"tabctl activate '{tab_id}'")
            win_json = run_cmd("niri msg --json windows")
            windows = json.loads(win_json)
            for win in windows:
                if win.get("app_id") == "zen":
                    run_cmd(f"niri msg action focus-window --id {win['id']}")
                    break
        else:
            subprocess.Popen(["zen-browser", url])
    elif code == 12:
        pass
        # processar editor -> D para apagar e R para renomear. cada um desse puxa uma nova função recursiva que mostra o fuzzel de novo

def handle_tasks():
    options = ["(N) Nova Task", "(D) Dashboard", "(S) Buscar"]
    conf_path = create_fuzzel_conf(['n', 'd', 's'])
    code, _ = show_fuzzel(options, conf_path)
    os.remove(conf_path)

    if code == 10:
        abrir_e_focar("obsidian://adv-uri?vault=notas&commandid=tasknotes%3Acreate-new-task")

    elif code == 11:
        abrir_e_focar("obsidian://adv-uri?vault=notas&filepath=tasks%2Ftasks-dashboard.base")

    elif code == 12:
        search_query = run_cmd("fuzzel --dmenu --lines 1 --prompt='Search: '")
        if not search_query: return

        now = datetime.now()
        today_str = now.strftime("%Y-%m-%d")
        tomorrow_str = (now + timedelta(days=1)).strftime("%Y-%m-%d")
        days_to_sunday = 6 - now.weekday()
        end_of_week_str = (now + timedelta(days=days_to_sunday)).strftime("%Y-%m-%d")
        current_month_str = now.strftime("%Y-%m")

        req_tags = []
        req_due_raw = None
        req_sched_raw = None

        for token in search_query.split():
            token = token.lower()
            if token.startswith('#'):
                req_tags.append(token[1:])
            elif token.startswith('d:'):
                req_due_raw = token[2:]
            elif token.startswith('s:'):
                req_sched_raw = token[2:]

        def check_date_match(req_raw, fm_date):
            if not req_raw: return True
            if not fm_date: return False
            if req_raw == "today": return fm_date == today_str
            if req_raw == "tomorrow": return fm_date == tomorrow_str
            if req_raw == "over": return fm_date < today_str
            if req_raw == "week": return today_str <= fm_date <= end_of_week_str
            if req_raw == "month": return fm_date.startswith(current_month_str)
            if "/" in req_raw:
                try:
                    d, m = req_raw.split('/')
                    target = f"{now.year}-{int(m):02d}-{int(d):02d}"
                    return fm_date == target
                except: pass
            return fm_date == req_raw

        results_map = {}
        display_options = []
        matched_tasks = []

        for root, _, files in os.walk(VAULT_PATH):
            for file in files:
                if not file.endswith(".md"): continue
                filepath = os.path.join(root, file)

                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                    if content.startswith("---"):
                        try:
                            fm_str = content.split("---")[1]
                            fm = yaml.safe_load(fm_str) or {}

                            raw_tags = fm.get('tags', [])
                            if isinstance(raw_tags, str): raw_tags = [raw_tags]
                            fm_tags = [str(t).lower().lstrip('#') for t in raw_tags if t]

                            tag_found = any('task' in t for t in fm_tags)
                            if not tag_found:
                                continue

                            def extract_date_str(val):
                                if not val: return None
                                if hasattr(val, 'strftime'): return val.strftime("%Y-%m-%d")
                                return str(val)[:10]

                            fm_due = extract_date_str(fm.get('due'))
                            fm_sched = extract_date_str(fm.get('scheduled'))

                            match = check_date_match(req_due_raw, fm_due)
                            if match: match = check_date_match(req_sched_raw, fm_sched)

                            if match and req_tags:
                                for r_tag in req_tags:
                                    tag_match = any(r_tag in t for t in fm_tags)
                                    if not tag_match:
                                        match = False
                                        break

                            if match:
                                relative_path = os.path.relpath(filepath, VAULT_PATH)
                                title = fm.get('title', file.replace('.md', ''))
                                
                                matched_tasks.append({
                                    "title": title,
                                    "due": fm_due,
                                    "sched": fm_sched,
                                    "path": relative_path
                                })
                        except Exception:
                            pass

        if matched_tasks:
            # Sort by scheduled date ascending. Tasks with no scheduled date go to the end.
            matched_tasks.sort(key=lambda x: x["sched"] if x["sched"] else "9999-99-99")

            # Get maximum title length to pad visually
            max_title_len = max(len(m["title"]) for m in matched_tasks)
            has_due = any(m["due"] for m in matched_tasks)
            has_sched = any(m["sched"] for m in matched_tasks)

            for m in matched_tasks:
                title_padded = m["title"].ljust(max_title_len)
                parts = [title_padded]

                if has_due:
                    due_str = f"D:{m['due'][8:10]}/{m['due'][5:7]}" if m['due'] and len(m['due']) >= 10 else ""
                    # Pad to 7 characters so the next column is perfectly aligned
                    parts.append(due_str.ljust(7))

                if has_sched:
                    sched_str = f"S:{m['sched'][8:10]}/{m['sched'][5:7]}" if m['sched'] and len(m['sched']) >= 10 else ""
                    parts.append(sched_str)

                # Strip trailing empty columns so tasks missing dates don't end with a floating "|"
                while len(parts) > 1 and parts[-1].strip() == "":
                    parts.pop()

                display_text = " | ".join(parts)
                display_options.append(display_text)
                results_map[display_text] = m["path"]

        if display_options:
            options_str = "\n".join(display_options)
            lines_to_show = min(len(display_options), 10)

            selected_text = run_cmd(
                f"fuzzel --dmenu --lines {lines_to_show} --width 80 --prompt='Select Task: '",
                input_data=options_str
            )

            if selected_text and selected_text in results_map:
                target_file = results_map[selected_text]
                encoded_file = urllib.parse.quote(target_file)
                abrir_e_focar(f"obsidian://open?vault=notas&file={encoded_file}")
        else:
            run_cmd("notify-send -u normal 'Obsidian Tasks' 'No tasks matched your query.'")

def quick_capture_to_daily():
    task_text = run_cmd("fuzzel --dmenu --lines 1 --width 80 --prompt='Escrever ideia: '")
    if not task_text: return

    now = datetime.now()

    meses = {
        1: "janeiro", 2: "fevereiro", 3: "março", 4: "abril",
        5: "maio", 6: "junho", 7: "julho", 8: "agosto",
        9: "setembro", 10: "outubro", 11: "novembro", 12: "dezembro"
    }

    dias_semana = {
        0: "seg", 1: "ter", 2: "qua", 3: "qui", 4: "sex", 5: "sáb", 6: "dom"
    }

    ano = now.strftime("%Y")
    mes_nome = meses[now.month]
    dia_mes = now.strftime("%d-%m")
    dia_semana_nome = dias_semana[now.weekday()]

    today_file = f"{dia_mes} {dia_semana_nome}.md"

    daily_note_path = os.path.join(VAULT_PATH, "diarias", ano, mes_nome, today_file)

    os.makedirs(os.path.dirname(daily_note_path), exist_ok=True)

    if not os.path.exists(daily_note_path):
        with open(daily_note_path, 'w', encoding='utf-8') as f:
            f.write(f"---\ntitle: {today_file.replace('.md', '')}\n---\n\n## Tasks\n")

    with open(daily_note_path, 'a', encoding='utf-8') as f:
        f.write(f"\n- [ ] {task_text} #ideia")

    run_cmd(f"notify-send -u low -a 'Obsidian Quick Capture' 'Ideia Salva' '{task_text}'")

def main():
    options = [
        "(O) Abrir obsidian",
        "(N) Abrir nota",
        "(D) Abrir nota diária",
        "(B) Bookmarks",
        "(T) Tasks",
        "(C) Capturar Ideia"
    ]
    conf_path = create_fuzzel_conf(['o', 'n', 'd', 'b', 't', 'c'])

    code, _ = show_fuzzel(options, conf_path, extra_args="--width 30")
    os.remove(conf_path)

    if code == 10:
        abrir_e_focar("obsidian://open?vault=notas")
    elif code == 11:
        notas_list = ["nova nota"]
        files = run_cmd(f"fd -t f . '{VAULT_PATH}'").split("\n")
        for f in files:
            if "/compras/" not in f and f:
                notas_list.append(f.replace(f"{VAULT_PATH}/", ""))

        selected_file = run_cmd(f"echo '{chr(10).join(notas_list)}' | fuzzel --dmenu --width 70%")
        if selected_file:
            encoded_file = urllib.parse.quote(selected_file)
            abrir_e_focar(f"obsidian://open?vault=notas&file={encoded_file}")
    elif code == 12:
        abrir_e_focar("obsidian://daily")
    elif code == 13:
        handle_bookmarks()
    elif code == 14:
        handle_tasks()
    elif code == 15:
        quick_capture_to_daily()

if __name__ == "__main__":
    main()
