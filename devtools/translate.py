import asyncio
import os
import re
from typing import List
from googletrans import Translator
from googletrans.models import Translated
from polib import pofile, POFile, POEntry
from pathlib import Path
from rich.console import Console
import humanize

MSGIDS: List[str]


REG_STRING_REPLACEMENTS = re.compile(r"[%％] *[sS]")
REG_DECIMAL_REPLACEMENTS = re.compile(r"[%％] *[dD]")
REG_LUA_REPLACEMENTS = re.compile(r"[\$$] *\{ *([^\}]+) *\}")


def _fix_luarepl(m: re.Match) -> str:
    return f"${{{m[1].lower()}}}"


async def translate(
    console: Console, translator: Translator, pot:POFile, filename: Path, lang: str
) -> None:
    with console.status(f"Translating {filename} (en -> {lang})..."):
        po = pofile(filename)
        po.merge(pot)
        txres: Translated
        for txres in await translator.translate(MSGIDS, dest=lang, src="en"):
            e = po.find(txres.origin)
            if e is None:
                console.log(f'W: Could not find msgid={txres.origin!r}.')
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
    pot=pofile(Path('data')/'localization'/'template.pot')
    MSGIDS = [e.msgid for e in pot]
    async with Translator() as translator:
        await translate(
            console, translator, pot,Path("data") / "localization" / "deutsch.po", "de"
        )
        await translate(
            console, translator, pot, Path("data") / "localization" / "fr.po", "fr"
        )
        await translate(
            console, translator, pot, Path("data") / "localization" / "jp.po", "ja"
        )
        await translate(
            console, translator, pot, Path("data") / "localization" / "pt-br.po", "pt"
        )
        await translate(
            console, translator, pot, Path("data") / "localization" / "ru.po", "ru"
        )


if __name__ == "__main__":
    console = Console()
    asyncio.run(do_localizations(console))
