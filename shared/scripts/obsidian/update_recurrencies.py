#!/usr/bin/env python3

import argparse
import re
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Sequence


PROCESSED_MARKER = "NOTE UPDATED"
CARD_DATE_PATTERN = re.compile(r"^(card_date:\s*)(\d{2}/\d{2})\s*$", re.MULTILINE)
REMAINING_MONTHS_PATTERN = re.compile(
    r"^(remaining_mo:\s*)(-?\d+)\s*$", re.MULTILINE
)
TITLE_PATTERN = re.compile(r"^title:\s*(.*?)\s*$", re.MULTILINE)
ADDITIONAL_INFO_PATTERN = re.compile(
    r"^# Informação adicional:?\s*$", re.MULTILINE
)
PROCESSED_MARKER_PATTERN = re.compile(
    rf"^{re.escape(PROCESSED_MARKER)}\s*$", re.MULTILINE
)


@dataclass
class RunSummary:
    scanned: int = 0
    matching: int = 0
    created: int = 0
    updated: int = 0
    recovered_stale_markers: int = 0
    already_processed: int = 0
    existing_recurrences: int = 0
    completed: int = 0
    warnings: int = 0
    errors: int = 0


def parse_card_date(value: str) -> str:
    match = re.fullmatch(r"(\d{2})/(\d{2})", value)
    if match is None or not 1 <= int(match.group(1)) <= 12:
        raise argparse.ArgumentTypeError("card date must use a valid MM/YY value")
    return value


def parse_directory(value: str) -> Path:
    directory = Path(value).expanduser()
    if not directory.is_dir():
        raise argparse.ArgumentTypeError(f"directory does not exist: {directory}")
    return directory


def parse_args(argv: Sequence[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Create the next note for each recurring purchase in a billing month. "
            "Processed source notes are marked so the command is safe to rerun."
        )
    )
    parser.add_argument("directory", type=parse_directory, help="directory of purchase notes")
    parser.add_argument("card_date", type=parse_card_date, help="billing month in MM/YY format")
    return parser.parse_args(argv)


def next_card_date(card_date: str) -> str:
    month, year = map(int, card_date.split("/"))
    if month == 12:
        return f"01/{(year + 1) % 100:02d}"
    return f"{month + 1:02d}/{year:02d}"


def note_title(content: str, fallback: str) -> str:
    match = TITLE_PATTERN.search(content)
    return match.group(1) if match and match.group(1) else fallback


def add_processed_marker(content: str) -> str:
    if PROCESSED_MARKER_PATTERN.search(content):
        return content

    content = content.rstrip()
    if not ADDITIONAL_INFO_PATTERN.search(content):
        content += "\n\n# Informação adicional:"
    return f"{content}\n{PROCESSED_MARKER}\n"


def build_recurrence(content: str, remaining_months: int, new_date: str) -> str:
    new_remaining = -1 if remaining_months == -1 else remaining_months - 1
    content = REMAINING_MONTHS_PATTERN.sub(
        lambda match: f"{match.group(1)}{new_remaining}", content, count=1
    )
    return CARD_DATE_PATTERN.sub(
        lambda match: f"{match.group(1)}{new_date}", content, count=1
    )


def content_without_marker(content: str) -> str:
    return PROCESSED_MARKER_PATTERN.sub("", content).rstrip()


def find_existing_recurrence(
    note_paths: Sequence[Path], source_path: Path, expected_content: str
) -> Path | None:
    expected_content = content_without_marker(expected_content)
    for candidate_path in note_paths:
        if candidate_path == source_path:
            continue
        try:
            candidate_content = candidate_path.read_text(encoding="utf-8")
        except (OSError, UnicodeError):
            continue
        if content_without_marker(candidate_content) == expected_content:
            return candidate_path
    return None


def available_note_path(directory: Path, now: datetime | None = None) -> Path:
    timestamp = int((now or datetime.now()).strftime("%Y%m%d%H%M"))
    candidate = directory / f"{timestamp}.md"
    while candidate.exists():
        timestamp += 1
        candidate = directory / f"{timestamp}.md"
    return candidate


def process_directory(
    directory: Path, card_date: str, *, now: datetime | None = None
) -> RunSummary:
    summary = RunSummary()
    note_paths = sorted(
        path
        for path in directory.iterdir()
        if path.is_file() and path.suffix.lower() == ".md"
    )
    summary.scanned = len(note_paths)

    print(f"Processing {card_date} in {directory}")

    for source_path in note_paths:
        try:
            content = source_path.read_text(encoding="utf-8")
        except (OSError, UnicodeError) as error:
            summary.errors += 1
            print(f"[ERROR]   {source_path.name} — could not read file: {error}")
            continue

        card_date_match = CARD_DATE_PATTERN.search(content)
        if card_date_match is None or card_date_match.group(2) != card_date:
            continue

        summary.matching += 1
        title = note_title(content, source_path.stem)

        remaining_match = REMAINING_MONTHS_PATTERN.search(content)
        if remaining_match is None:
            summary.warnings += 1
            print(f'[WARNING] {source_path.name} — "{title}" has no remaining_mo field')
            continue

        remaining_months = int(remaining_match.group(2))
        if remaining_months == 0:
            summary.completed += 1
            print(f'[SKIPPED] {source_path.name} — "{title}" has no recurrence left')
            continue

        new_date = next_card_date(card_date)
        new_content = build_recurrence(
            content_without_marker(content), remaining_months, new_date
        )
        existing_path = find_existing_recurrence(
            note_paths, source_path, new_content
        )
        has_processed_marker = PROCESSED_MARKER_PATTERN.search(content) is not None

        if has_processed_marker and existing_path is not None:
            summary.already_processed += 1
            print(
                f'[SKIPPED] {source_path.name} — "{title}" was already processed '
                f"({existing_path.name} exists)"
            )
            continue

        if has_processed_marker:
            summary.recovered_stale_markers += 1
            print(
                f'[RECOVERING] {source_path.name} — "{title}" has a stale '
                f"{PROCESSED_MARKER} marker; no {new_date} recurrence exists"
            )

        if existing_path is not None:
            try:
                source_path.write_text(add_processed_marker(content), encoding="utf-8")
            except OSError as error:
                summary.errors += 1
                print(f'[ERROR]   {source_path.name} — could not mark "{title}": {error}')
                continue

            summary.updated += 1
            summary.existing_recurrences += 1
            print(
                f'[FOUND]   {existing_path.name} — existing recurrence for "{title}"'
            )
            print(f'[UPDATED] {source_path.name} — "{title}" marked {PROCESSED_MARKER}')
            continue

        new_path = available_note_path(directory, now)

        try:
            new_path.write_text(new_content, encoding="utf-8")
            if not has_processed_marker:
                source_path.write_text(add_processed_marker(content), encoding="utf-8")
        except OSError as error:
            summary.errors += 1
            print(f'[ERROR]   {source_path.name} — could not process "{title}": {error}')
            continue

        new_remaining = -1 if remaining_months == -1 else remaining_months - 1
        summary.created += 1
        print(
            f'[CREATED] {new_path.name} — "{title}", '
            f"card_date {new_date}, remaining_mo {new_remaining}"
        )
        if has_processed_marker:
            print(
                f'[RECOVERED] {source_path.name} — "{title}" now has its '
                f"missing {new_date} recurrence"
            )
        else:
            summary.updated += 1
            print(
                f'[UPDATED] {source_path.name} — "{title}" marked '
                f"{PROCESSED_MARKER}"
            )

    print(
        "\nDone: "
        f"{summary.created} created, "
        f"{summary.updated} updated, "
        f"{summary.recovered_stale_markers} stale markers recovered, "
        f"{summary.already_processed} already processed, "
        f"{summary.existing_recurrences} existing recurrences found, "
        f"{summary.completed} without recurrence, "
        f"{summary.warnings} warnings, "
        f"{summary.errors} errors "
        f"({summary.scanned} Markdown files scanned)."
    )
    return summary


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv)
    summary = process_directory(args.directory, args.card_date)
    return 1 if summary.errors else 0


if __name__ == "__main__":
    raise SystemExit(main())
