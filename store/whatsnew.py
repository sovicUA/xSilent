"""Витягує примітки до випуску версії з store/release-notes.md у файли
whatsnew-<мова> (формат `whatsNewDirectory` дії r0adkll/upload-google-play).

    python store/whatsnew.py 1.2.0 build/whatsnew

Береться розділ `## <версія> (...)`, у ньому — блоки коду під `### <мова>`.
Без приміток для версії або понад 500 символів (ліміт Play) — помилка, щоб
реліз не пішов без них.
"""

import pathlib
import re
import sys

LIMIT = 500


def extract(text: str, version: str) -> dict[str, str]:
    section = re.search(
        rf"^## {re.escape(version)} \(.*?$(.*?)(?=^## |\Z)",
        text,
        re.M | re.S,
    )
    if not section:
        return {}
    return {
        lang: body.strip()
        for lang, body in re.findall(
            r"^### (\S+)\s*\n```\n(.*?)```", section.group(1), re.M | re.S
        )
    }


def main() -> int:
    version, out = sys.argv[1], pathlib.Path(sys.argv[2])
    src = pathlib.Path(__file__).with_name("release-notes.md")
    notes = extract(src.read_text(encoding="utf-8"), version)
    if not notes:
        print(f"Немає приміток для {version} у {src}", file=sys.stderr)
        return 1
    out.mkdir(parents=True, exist_ok=True)
    for lang, body in notes.items():
        if len(body) > LIMIT:
            print(f"{lang}: {len(body)} > {LIMIT} символів", file=sys.stderr)
            return 1
        (out / f"whatsnew-{lang}").write_text(body, encoding="utf-8")
        print(f"{lang}: {len(body)} символів")
    return 0


if __name__ == "__main__":
    sys.exit(main())
