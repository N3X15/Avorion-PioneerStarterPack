import re
from pathlib import Path
import sys
from typing import Generator, Set

from polib import POEntry, pofile

REG_LUA_COMMENT = re.compile(r"--.*$", flags=re.MULTILINE)
REG_LUA_MLCOMMENT = re.compile(r"--\[(=*)\[(.|\n)*?\]\1\]", flags=re.MULTILINE)
REG_T_MESSAGE_STANDARD = re.compile(r"\-\-.+$")
REG_T_MESSAGE_STANDARD = re.compile(r'"((?:[^"\\]|\\.)*)"\w*%\w*_[tT]')
REG_T_MESSAGE_CONTEXT = re.compile(r"\/\*(\*(?!\/)|[^*])*\*\/")


def get_msgs(file: Path) -> Generator[POEntry, None, None]:
    code = file.read_text(encoding="utf-8")
    # Remove comments from the code we're about to parse.
    code = REG_LUA_MLCOMMENT.sub("", code)
    code = REG_LUA_COMMENT.sub("", code)
    # Parse each line separately
    for i, ol in enumerate(code.splitlines()):
        l = ol.strip("\r\n")

        for m in REG_T_MESSAGE_STANDARD.finditer(l):
            # print(repr(m))
            msg = m.group(1)
            msgctxt = None
            if (cm := REG_T_MESSAGE_CONTEXT.search(msg)) is not None:
                msgctxt = cm.group(1).replace("\\n", "\n")
                msg = REG_T_MESSAGE_CONTEXT.sub("", msg)
            # print(i, repr(msg), repr(l))
            yield POEntry(
                occurrences=[(f"{file.as_posix()}", i)],
                tcomment="",
                msgid=msg.replace("\\n", "\n"),
                msgctxt=msgctxt,
            )


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
    potpath = Path("data") / "localization" / "template.pot"
    pot = pofile(potpath, wrapwidth=sys.maxsize)
    extant: Set[str] = set([poe.msgid for poe in pot])
    found: Set[str] = set()
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
            found.add(e.msgid)
    obsolete = extant - found
    new = found - extant
    if len(obsolete) > 0:
        print(f"Could not find:")
        [print(f" - {e!r}") for e in obsolete]
    if len(new) > 0:
        print(f"New entries:")
        [print(f" + {e!r}") for e in new]
    pot.save(potpath)


if __name__ == "__main__":
    main()
