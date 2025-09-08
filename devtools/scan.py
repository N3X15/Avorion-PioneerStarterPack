import re
from pathlib import Path
from typing import Generator, Set

from polib import POEntry, pofile

REG_T_MESSAGE_STANDARD = re.compile(r'(?:"([^"]+)"|\'([^\']+)\')\w*%\w*_[tT]')


def get_msgs(file: Path) -> Generator[POEntry, None, None]:
    with file.open("r", encoding="utf-8") as f:
        for i, ol in enumerate(f):
            l = ol.strip("\r\n")
            # print(i,l)
            if (m := REG_T_MESSAGE_STANDARD.search(l)) is not None:
                msg = m.group(1)
                # print(i, repr(msg), repr(l))
                yield POEntry(
                    occurrences=[(f"{file.as_posix()}", i)],
                    tcomment="",
                    msgid=msg.replace("\\n", "\n"),
                )
                first = False


def preload_stock(stock_potfile: Path) -> Set[str]:
    print(f"Preloading stock messages from {stock_potfile}...")
    pot = pofile(stock_potfile)
    return set([e.msgid for e in pot])


def main():
    import argparse

    argp = argparse.ArgumentParser()
    argp.add_argument("avorion_path", type=Path, help="Install path of Avorion")
    args = argp.parse_args()
    stock_msgids = preload_stock(
        args.avorion_path / "data" / "localization" / "template.pot"
    )
    pot = pofile(Path("data") / "localization" / "template.pot")
    extant: Set[POEntry] = set([poe for poe in pot])
    found: Set[POEntry] = set()
    pot.clear()
    for luaf in Path("data").rglob("*.lua"):
        print(luaf)
        first: bool = True
        for e in get_msgs(luaf):
            if e.msgid in stock_msgids:
                continue
            if (fe := pot.find(e.msgid)) is None:
                print("+", repr(e.msgid))
                if first:
                    e.tcomment = f"========== {luaf.as_posix()} =========="
                    first = False
                pot.append(e)
            else:
                fe.occurrences.append(e.occurrences[0])
            found.add(e)
    # obsolete = extant - found
    # print(f'{obsolete=}')
    pot.save(Path("data") / "localization" / "template.pot")


if __name__ == "__main__":
    main()
