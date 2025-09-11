import os
import re
import shutil
from pathlib import Path
import sys
from typing import List, Set
from polib import pofile

DIST_DIR = Path("dist")
DEPLOY_PATHS: Set[Path] = {
    Path("data"),
    Path("modinfo.lua"),
    Path("README.md"),
    Path("thumbnail.png"),
}


def copyall(src: Path, dest: Path) -> None:
    for root, _, files in os.walk(src):
        subroot = Path(root).relative_to(src.parent)
        sroot = src.parent / subroot
        droot = dest / subroot
        # print(f"{sroot=} {droot=}")
        droot.mkdir(parents=True, exist_ok=True)
        for filename in files:
            sfn = sroot / filename
            dfn = droot / filename
            match sfn.suffix:
                case ".mo" | ".toml" | ".lock" | ".new":
                    print(f"SKIPPED {sfn}")
                    continue
            print(f"{sfn} -> {dfn}")
            shutil.copy(sfn, droot)


REG_T_INVALID_SPACES = re.compile(r'"[^"]+"(?:\w+%|%\w+)_[tT]')

def _list_printf_symbols(s:str)->List[str]:
    o:List[str]=[]
    pct:bool=False
    waiting:bool=False
    for c in s:
        match c:
            case "%":
                if waiting:
                    pct = False
                    waiting = False
                else:
                    pct = True
                    waiting = True
            case 's':
                if waiting and pct:
                    o.append("s")
                pct = False
                waiting = False
            case 'd':
                if waiting and pct:
                    o.append("d")
                pct = False
                waiting = False
            case _:
                pct = False
                waiting = False
    return o

def _list_luarepl_symbols(s:str)->Set[str]:
    o:Set[str]=set()
    for m in re.finditer(r'\$\{([^\}]+)\}', s):
        o.add(m[1])
    return o

def qc_check(path: Path) -> None:
    failed=False
    for rootstr, _, files in os.walk(path):
        root = path.parent / rootstr
        for filename in files:
            fpath = root / filename
            filefailed=False
            filechecked=False
            match fpath.suffix:
                case ".lua":
                    print(f"Checking {fpath}...")
                    for i, l in enumerate(fpath.read_text("utf-8").splitlines()):
                        if (m := REG_T_INVALID_SPACES.match(l)) is not None:
                            print(f"{i}\tINVALID SPACES AROUND %: {m[0]!r}")
                            failed = True
                            filefailed = True
                    filechecked=True
                case ".po":
                    print(f"Checking {fpath}...")
                    po=pofile(fpath)
                    for i,e in enumerate(po):
                        o=_list_luarepl_symbols(e.msgid)
                        t=_list_luarepl_symbols(e.msgstr)
                        if len(o-t)>0:
                            print(f'Missing ${{luarepl}} symbols in {fpath}[{e.msgid!r}]:')
                            for s in sorted(o-t):
                                print(f' - ${{{s}}}')
                                failed=True
                                filefailed=True
                    filechecked=True
            if filechecked:
                if filefailed:
                    print('  FAILED')
                else:
                    print('  OK')
    if failed:
        sys.exit(1)

def main() -> None:
    import argparse

    argp = argparse.ArgumentParser()
    argp.add_argument("--install", action="store_true", default=False)
    args = argp.parse_args()
    DIST_DIR=Path('dist')
    if args.install:
        DIST_DIR = (
            Path(os.environ["APPDATA"]) / "Avorion" / "mods" / "PioneerStarterPack"
        )
    qc_check(Path("data"))
    if DIST_DIR.exists():
        shutil.rmtree(DIST_DIR)
    DIST_DIR.mkdir(parents=True, exist_ok=True)
    for dpath in DEPLOY_PATHS:
        if dpath.is_dir():
            copyall(dpath, DIST_DIR)
        if dpath.is_file():
            print(f"{dpath} -> {DIST_DIR / dpath}")
            shutil.copy(dpath, DIST_DIR)


if __name__ == "__main__":
    main()
