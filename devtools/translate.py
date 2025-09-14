import asyncio
import os
import re
import sys
from pathlib import Path
from typing import List, Set

import humanize
from googletrans import Translator
from googletrans.models import Translated
from polib import POFile, pofile
from rich.console import Console

MSGIDS: List[str]

LANG_DIR = Path("data") / "localization"
REG_STRING_REPLACEMENTS = re.compile(r"[%％] *[sS]")
REG_DECIMAL_REPLACEMENTS = re.compile(r"[%％] *[dD]")
REG_LUA_REPLACEMENTS = re.compile(r"[\$$] *\{ *([^\}]+) *\}")


def _fix_luarepl(m: re.Match) -> str:
    return f"${{{m[1].lower()}}}"


async def translate(
    console: Console,
    translator: Translator,
    pot: POFile,
    filename: Path,
    lang: str,
    overwrite: bool = False,
) -> None:
    with console.status(f"Translating {filename} (en -> {lang})..."):
        po = pofile(filename, wrapwidth=sys.maxsize)
        po.merge(pot)
        txres: Translated
        EXCLUDED_MSGIDS: Set[str] = set(
            [e.msgid for e in po if e.msgstr != ""] if not overwrite else []
        )
        msgids = list(set(MSGIDS) - EXCLUDED_MSGIDS)
        if len(msgids)==0:
            return
        for txres in await translator.translate(
            msgids, dest=lang, src="en"
        ):
            e = po.find(txres.origin)
            if e is None:
                console.log(f"W: Could not find msgid={txres.origin!r}.")
                continue
            msgstr: str = txres.text
            msgstr = REG_STRING_REPLACEMENTS.sub("%s", msgstr)
            msgstr = REG_DECIMAL_REPLACEMENTS.sub("%d", msgstr)
            e.msgstr = REG_LUA_REPLACEMENTS.sub(_fix_luarepl, msgstr)
        po.save(filename)
        sz = humanize.naturalsize(os.path.getsize(filename))
        console.log(f"Successfully translated {sz} from English to {lang=}.")


async def do_localizations(console: Console) -> None:
    global MSGIDS
    pot = pofile(LANG_DIR / "template.pot")
    MSGIDS = [e.msgid for e in pot]
    async with Translator() as translator:
        await translate(
            console,
            translator,
            pot,
            filename=LANG_DIR / "deutsch.po",
            lang="de",
            overwrite=True,
        )
        await translate(
            console,
            translator,
            pot,
            filename=LANG_DIR / "fr.po",
            lang="fr",
            overwrite=True,
        )
        await translate(
            console,
            translator,
            pot,
            filename=LANG_DIR / "jp.po",
            lang="ja",
            overwrite=True,
        )
        await translate(
            console,
            translator,
            pot,
            filename=LANG_DIR / "pt-br.po",
            lang="pt",
            overwrite=True,
        )
        await translate(
            console,
            translator,
            pot,
            filename=LANG_DIR / "ru.po",
            lang="ru",
            overwrite=True,
        )
        await translate(
            console,
            translator,
            pot,
            filename=LANG_DIR / "zh.po",
            lang="zh",
            overwrite=False,
        )


if __name__ == "__main__":
    console = Console()
    asyncio.run(do_localizations(console))
