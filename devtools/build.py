import os
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
        print(f"{sroot=} {droot=}")
        droot.mkdir(parents=True, exist_ok=True)
        for filename in files:
            sfn = sroot / filename
            dfn = droot / filename
            if sfn.suffix in (".mo",):
                print(f"SKIPPED {sfn}")
                continue
            print(f"{sfn} -> {dfn}")
            shutil.copy(sfn, droot)


def main() -> None:
    import argparse

    argp = argparse.ArgumentParser()
    argp.add_argument("--install", action="store_true", default=False)
    args = argp.parse_args()
    if args.install:
        DIST_DIR = (
            Path(os.environ["APPDATA"]) / "Avorion" / "mods" / "PioneerStarterPack"
        )
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
