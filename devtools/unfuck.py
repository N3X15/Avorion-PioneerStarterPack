import re
from pathlib import Path
from typing import Generator, List, Set, Tuple

from polib import pofile, POEntry, POFile

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
                    tcomment=f"{file.as_posix()}",
                    # tcomment='',
                    msgid=msg,
                )


def preload_stock(stock_potfile: Path) -> Set[str]:
    print(f"Preloading stock messages from {stock_potfile}...")
    pot = pofile(stock_potfile)
    return set([e.msgid for e in pot])


def fixlangs(pot: POFile, frompo: POFile, topo: POFile) -> List[Tuple[str, str]]:
    repls: List[Tuple[str, str]] = []
    newpot = pofile(pot.fpath)
    newpot.clear()
    for entry in pot:
        before = frompo.find(entry.msgid)
        after = topo.find(entry.msgid)
        old = before.msgstr
        new = after.msgstr
        entry.msgid = new
        newpot.append(entry)
        # before.msgid = entry.msgid
        # after.msgid = entry.msgid
        print(f"{old} -> {new}")
        repls.append((old, new))
    newpot.save(pot.fpath)#.with_suffix(".pot.new"))
    return repls


def fixpo(repls: List[Tuple[str, str]], path: Path) -> None:
    po = pofile(path)
    newpo = pofile(path)
    newpo.clear()
    for old, new in repls:
        entry = po.find(old)
        if entry is not None:
            entry.msgid = new
            newpo.append(entry)
    newpo.save(path)#.with_suffix('.po.new'))


def main():
    import argparse

    # argp = argparse.ArgumentParser()
    # argp.add_argument("avorion_path", type=Path, help="Install path of Avorion")
    # args = argp.parse_args()
    # stock_msgids = preload_stock(
    #     args.avorion_path / "data" / "localization" / "template.pot"
    # )
    pot = pofile(Path("data") / "localization" / "template.pot")
    enpo = pofile(Path("data") / "localization" / "en.po")
    zhpo = pofile(Path("data") / "localization" / "zh.po")
    repls = fixlangs(pot, zhpo, enpo)
    for luaf in Path("data").rglob("*.lua"):
        data = luaf.read_text(encoding="utf-8")
        for before, after in repls:
            for strbefore, strafter in [
                (f"'{before}'", f"'{after}'"),
                (f'"{before}"', f'"{after}"'),
            ]:
                for ttype in "tT":
                    data = data.replace(f"{strbefore}%_{ttype}", f"{strafter}%_{ttype}")
        # luaf.with_suffix(".lua.new").write_text(data, encoding="utf-8")
        luaf.write_text(data, encoding="utf-8")
    fixpo(repls, Path("data") / "localization" / "deutsch.po")
    fixpo(repls, Path("data") / "localization" / "en.po")
    fixpo(repls, Path("data") / "localization" / "fr.po")
    fixpo(repls, Path("data") / "localization" / "jp.po")
    fixpo(repls, Path("data") / "localization" / "pt-br.po")
    fixpo(repls, Path("data") / "localization" / "ru.po")
    fixpo(repls, Path("data") / "localization" / "zh.po")


if __name__ == "__main__":
    main()
