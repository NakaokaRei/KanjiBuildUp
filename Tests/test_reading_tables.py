"""Run with a Python environment containing pdfplumber."""
from pathlib import Path
import sys
from types import SimpleNamespace
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'Scripts'))
from build_reading_tables import table_entries


def chars(text, orange=False):
    return [dict(text=c, non_stroking_color=(1, .5, 0) if orange else (0, 0, 0)) for c in text]


class ReadingTableTests(unittest.TestCase):
    def test_star_is_a_separate_question_without_renumbering_squares(self):
        page = SimpleNamespace(chars=(
            chars('□内法') + chars('うちのり', True) +
            chars('☆乾草') + chars('ほしくさ', True) +
            chars('□小札') + chars('こざね', True) +
            chars('☆冠付') + chars('かむりづけ', True)))
        for source in (9, 10):
            self.assertEqual(table_entries(page, source, 2), [
                ('内法', 'うちのり'), ('小札', 'こざね'),
                ('乾草', 'ほしくさ'), ('冠付', 'かむりづけ')])

    def test_trailing_stars_and_answer_alternatives(self):
        page = SimpleNamespace(chars=(
            chars('□飯櫃') + chars('めしびつ／いびつ', True) +
            chars('☆梳毛') + chars('すきげ', True) +
            chars('☆浮鮴') + chars('うきごり', True)))
        self.assertEqual(table_entries(page, 10, 2), [
            ('飯櫃', 'めしびつ／いびつ'), ('梳毛', 'すきげ'), ('浮鮴', 'うきごり')])


if __name__ == '__main__':
    unittest.main()
