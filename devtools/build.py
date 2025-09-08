import os
import re
import shutil
from pathlib import Path
from typing import Set

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


def qc_check(path: Path) -> None:
    for rootstr, _, files in os.walk(path):
        root = path.parent / rootstr
        for filename in files:
            fpath = root / filename
            match fpath.suffix:
                case ".lua":
                    print(f"Checking {fpath}...")
                    for i, l in enumerate(fpath.read_text("utf-8").splitlines()):
                        if (m := REG_T_INVALID_SPACES.match(l)) is not None:
                            print(f"{i}\tINVALID SPACES AROUND %: {m[0]!r}")


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
