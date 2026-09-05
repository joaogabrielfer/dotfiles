import tempfile
import unittest
from contextlib import redirect_stdout
from datetime import datetime
from io import StringIO
from pathlib import Path

import update_recurrencies


def note(title: str, card_date: str, remaining_months: int, body: str = "") -> str:
    return f"""---
title: {title}
value: 10
created_date: 2026-03-01
card_date: {card_date}
remaining_mo: {remaining_months}
description:
---
# Informação adicional:
{body}"""


class UpdateRecurrencesTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.directory = Path(self.temporary_directory.name)
        self.now = datetime(2026, 7, 21, 12, 30)

    def tearDown(self) -> None:
        self.temporary_directory.cleanup()

    def run_processor(self, card_date: str) -> tuple[update_recurrencies.RunSummary, str]:
        output = StringIO()
        with redirect_stdout(output):
            summary = update_recurrencies.process_directory(
                self.directory, card_date, now=self.now
            )
        return summary, output.getvalue()

    def test_creates_recurrence_marks_source_and_is_safe_to_rerun(self) -> None:
        source = self.directory / "source.md"
        source.write_text(note("VEM", "03/26", 3), encoding="utf-8")

        first_summary, first_output = self.run_processor("03/26")

        self.assertEqual(first_summary.created, 1)
        self.assertEqual(first_summary.updated, 1)
        self.assertIn("[CREATED]", first_output)
        self.assertIn("[UPDATED]", first_output)
        self.assertTrue(
            source.read_text(encoding="utf-8").endswith("NOTE UPDATED\n")
        )

        generated = self.directory / "202607211230.md"
        generated_content = generated.read_text(encoding="utf-8")
        self.assertIn("card_date: 04/26", generated_content)
        self.assertIn("remaining_mo: 2", generated_content)
        self.assertNotIn("NOTE UPDATED", generated_content)

        second_summary, second_output = self.run_processor("03/26")

        self.assertEqual(second_summary.created, 0)
        self.assertEqual(second_summary.already_processed, 1)
        self.assertIn("already processed", second_output)
        self.assertEqual(len(list(self.directory.glob("*.md"))), 2)

    def test_indefinite_recurrence_and_year_rollover(self) -> None:
        source = self.directory / "subscription.md"
        source.write_text(note("Lightroom", "12/26", -1), encoding="utf-8")

        summary, _ = self.run_processor("12/26")

        self.assertEqual(summary.created, 1)
        generated = (self.directory / "202607211230.md").read_text(encoding="utf-8")
        self.assertIn("card_date: 01/27", generated)
        self.assertIn("remaining_mo: -1", generated)

    def test_adopts_recurrence_created_before_markers_were_added(self) -> None:
        source = self.directory / "source.md"
        source_content = note("VEM", "03/26", 3)
        source.write_text(source_content, encoding="utf-8")
        existing = self.directory / "old-generated-note.md"
        existing.write_text(
            update_recurrencies.build_recurrence(source_content, 3, "04/26"),
            encoding="utf-8",
        )

        summary, output = self.run_processor("03/26")

        self.assertEqual(summary.created, 0)
        self.assertEqual(summary.updated, 1)
        self.assertEqual(summary.existing_recurrences, 1)
        self.assertIn("[FOUND]", output)
        self.assertIn("NOTE UPDATED", source.read_text(encoding="utf-8"))
        self.assertEqual(len(list(self.directory.glob("*.md"))), 2)

    def test_recovers_inherited_marker_when_next_recurrence_is_missing(self) -> None:
        source = self.directory / "legacy-generated-note.md"
        source.write_text(
            note("Tênis", "07/26", 1, body="NOTE UPDATED\n"), encoding="utf-8"
        )

        first_summary, first_output = self.run_processor("07/26")

        self.assertEqual(first_summary.created, 1)
        self.assertEqual(first_summary.updated, 0)
        self.assertEqual(first_summary.recovered_stale_markers, 1)
        self.assertIn("[RECOVERING]", first_output)
        self.assertIn("[RECOVERED]", first_output)

        generated = self.directory / "202607211230.md"
        generated_content = generated.read_text(encoding="utf-8")
        self.assertIn("card_date: 08/26", generated_content)
        self.assertIn("remaining_mo: 0", generated_content)
        self.assertNotIn("NOTE UPDATED", generated_content)

        second_summary, second_output = self.run_processor("07/26")

        self.assertEqual(second_summary.created, 0)
        self.assertEqual(second_summary.already_processed, 1)
        self.assertIn("202607211230.md exists", second_output)
        self.assertEqual(len(list(self.directory.glob("*.md"))), 2)

    def test_zero_remaining_is_skipped_without_marking_source(self) -> None:
        source = self.directory / "complete.md"
        source.write_text(note("Jantar", "03/26", 0), encoding="utf-8")

        summary, output = self.run_processor("03/26")

        self.assertEqual(summary.completed, 1)
        self.assertEqual(summary.created, 0)
        self.assertIn("no recurrence left", output)
        self.assertNotIn("NOTE UPDATED", source.read_text(encoding="utf-8"))

    def test_ignores_non_markdown_files(self) -> None:
        (self.directory / "binary.dat").write_bytes(b"\xff\xfe")

        summary, _ = self.run_processor("03/26")

        self.assertEqual(summary.scanned, 0)
        self.assertEqual(summary.errors, 0)

    def test_only_frontmatter_like_first_fields_are_changed(self) -> None:
        source = self.directory / "source.md"
        source.write_text(
            note(
                "Example",
                "03/26",
                2,
                body="card_date: 03/26\nremaining_mo: 99\n",
            ),
            encoding="utf-8",
        )

        self.run_processor("03/26")

        generated = (self.directory / "202607211230.md").read_text(encoding="utf-8")
        self.assertEqual(generated.count("card_date: 04/26"), 1)
        self.assertEqual(generated.count("card_date: 03/26"), 1)
        self.assertIn("remaining_mo: 1", generated)
        self.assertIn("remaining_mo: 99", generated)

    def test_rejects_invalid_card_date(self) -> None:
        with self.assertRaisesRegex(Exception, "valid MM/YY"):
            update_recurrencies.parse_card_date("13/26")


if __name__ == "__main__":
    unittest.main()
