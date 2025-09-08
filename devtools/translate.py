import asyncio
from typing import List
from googletrans import Translator
from googletrans.models import Translated
from polib import pofile, POFile, POEntry
from pathlib import Path
MSGIDS:List[str]
MSGIDS=[e.msgid for e in pofile(Path('data')/'localization'/'template.pot')]
async def translate(translator:Translator, filename:Path, lang:str)->None:
    print(filename)
    po=pofile(filename)
    txres:Translated
    for txres in await translator.translate(MSGIDS, dest=lang, src='en'):
        e=po.find(txres.origin)
        e.msgstr=txres.text
    po.save(filename)

async def do_localizations()->None:
    async with Translator() as translator:
        await translate(translator, Path('data') / 'localization' / 'deutsch.po', 'de')
        await translate(translator, Path('data') / 'localization' / 'fr.po', 'fr')
        await translate(translator, Path('data') / 'localization' / 'jp.po', 'ja')
        await translate(translator, Path('data') / 'localization' / 'pt-br.po', 'pt')
        await translate(translator, Path('data') / 'localization' / 'ru.po', 'ru')

if __name__ == "__main__":
    asyncio.run(do_localizations())