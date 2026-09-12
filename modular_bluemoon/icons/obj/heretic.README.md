# Спрайты еретиков

`heretic.dmi` и `heretic_ash.dmi` содержат состояния из [tgstation/tgstation](https://github.com/tgstation/tgstation), снимок `5f093a8cfbbe269b15bc73535f230909218e38d6`.

Лицензия: [Creative Commons Attribution-ShareAlike 3.0 Unported](https://creativecommons.org/licenses/by-sa/3.0/), согласно [README источника](https://github.com/tgstation/tgstation/blob/5f093a8cfbbe269b15bc73535f230909218e38d6/README.md#license).

| Состояния | Авторы | Коммит источника |
| --- | --- | --- |
| `ash_blade` | EnterTheJake | [bc6c798ce17](https://github.com/tgstation/tgstation/commit/bc6c798ce17) |
| `rust_blade` | EnterTheJake | [1e851842c09](https://github.com/tgstation/tgstation/commit/1e851842c09) |
| `flesh_blade` | Tramz | [f01917730d4](https://github.com/tgstation/tgstation/commit/f01917730d4) |
| `void_blade` | OrcaCora; перенос EnterTheJake | [6faa37853b7](https://github.com/tgstation/tgstation/commit/6faa37853b7) |
| `dark_blade` | EnterTheJake | [0d0270b3dc0](https://github.com/tgstation/tgstation/commit/0d0270b3dc0) |
| `moon_blade` | EnterTheJake | [12026e300b4](https://github.com/tgstation/tgstation/commit/12026e300b4) |
| `cosmic_blade` | Comxy | [73ba9046dfe](https://github.com/tgstation/tgstation/commit/73ba9046dfe) |
| `codex`, `codex_opening`, `codex_open`, `codex_closing` | EnterTheJake | [958116f9986](https://github.com/tgstation/tgstation/commit/958116f9986) |

Клинки взяты из `icons/obj/weapons/khopesh.dmi`, книга — из `icons/obj/antags/eldritch.dmi`. Состояния книги `book`, `book_opening`, `book_open`, `book_closing` переименованы в `codex`, `codex_opening`, `codex_open`, `codex_closing`. Кадры, направления и параметры анимации сохранены; состояния собраны в отдельный DMI.

204 кадра `ash_blade` вынесены в `heretic_ash.dmi`; остальные состояния остались в `heretic.dmi`. Пиксели и метаданные всех состояний сохранены.

`heretic_effects.dmi` содержит `cosmic_star` (исходное имя `cosmic_diamond`, `icons/effects/eldritch.dmi`) и `cosmic_beam` (`icons/effects/beam.dmi`). Автор — Comxy, [73ba9046dfe](https://github.com/tgstation/tgstation/commit/73ba9046dfe), та же лицензия CC BY-SA 3.0. Изменены имя звезды и упаковка состояний; кадры и параметры анимации сохранены.

## Книги и боевые эффекты

Следующие состояния взяты из того же снимка tgstation под CC BY-SA 3.0. Ссылки ведут на историю исходных файлов с авторами изменений. Таблица описывает исходный перенос; последующая адаптация эффектов приведена ниже.

| Файл | Исходные состояния и файлы | Изменения |
| --- | --- | --- |
| `heretic_feedback.dmi` | [icons/effects/eldritch.dmi](https://github.com/tgstation/tgstation/commits/5f093a8cfbbe269b15bc73535f230909218e38d6/icons/effects/eldritch.dmi): `cleave`, `smoke`, `small_rune_1`–`small_rune_7`, `cloud_swirl`, `cosmic_cloud`, `cosmic_ring`, `cosmic_carpet`, `cosmic_gem`, `moon_insanity_overlay`, `ring_leader_effect`, `eye_open`, `eye_pulse`, `eye_flash`, `eye_close`, `realitycrack`, `emark1`–`emark7` | Переупаковка; кадры и анимация сохранены. |
| `heretic_feedback.dmi`: `sigil_ash`, `sigil_rust`, `sigil_flesh`, `sigil_void`, `sigil_blade`, `sigil_moon`, `sigil_cosmic` | [icons/ui_icons/antags/heretic/knowledge.dmi](https://github.com/tgstation/tgstation/commits/5f093a8cfbbe269b15bc73535f230909218e38d6/icons/ui_icons/antags/heretic/knowledge.dmi): `node_ash`, `node_rust`, `node_flesh`, `node_void`, `node_blade`, `node_moon`, `node_cosmos`. ViktorKoL и участники tgstation, [переработка интерфейса знаний](https://github.com/tgstation/tgstation/commit/a40a92140d49c87495a1685cbe5f4a5ce55d593d). | Переименованы без изменения пикселей; статичные печати отличают пути на книге, рунах, полях и алертах. |
| `heretic_alerts.dmi` | Семь `sigil_*` из строки выше и `realitycrack` из исходного `icons/effects/eldritch.dmi`. | Статические значки: печати перенесены целиком, `rift_exposure` содержит кадр 0 `realitycrack`. Пиксели не изменены. Компактный лист HUD занимает 36 КиБ после декодирования RGBA. |
| `heretic_books.dmi` | [icons/obj/service/library.dmi](https://github.com/tgstation/tgstation/commits/5f093a8cfbbe269b15bc73535f230909218e38d6/icons/obj/service/library.dmi): `booksacredflame`, `demonomicon`, `bookblind`; [icons/obj/storage/book.dmi](https://github.com/tgstation/tgstation/commits/5f093a8cfbbe269b15bc73535f230909218e38d6/icons/obj/storage/book.dmi): `ithaqua`, `tome`; [icons/obj/antags/eldritch.dmi](https://github.com/tgstation/tgstation/commits/5f093a8cfbbe269b15bc73535f230909218e38d6/icons/obj/antags/eldritch.dmi): `ogbook`, `book_morbus`, анимации `book` и `book_morbus` | Обложки переименованы в `ash`, `flesh`, `moon`, `void`, `blade`, `rust`, `cosmic` соответственно. Каждая дополнена состояниями `_open`, `_opening`, `_closing`. Космос использует полные анимации `book_morbus`. У остальных `_opening` состоит из первого кадра собственной обложки и кадров 14–20 исходного `book_opening`; `_closing` — из кадров 0–6 исходного `book_closing` и первого кадра собственной обложки (нумерация с нуля). `_open` сохраняет полный `book_open`. Задержки исходных кадров умножены на 0.8, 1.35, 1.1, 1.5, 0.5, 0.85, 0.75 для Пепла, Ржавчины, Плоти, Пустоты, Клинка, Луны, Космоса; добавленный кадр обложки длится не более 1 децисекунды. Пиксели исходных кадров не изменены. |

В истории исходного файла эффектов указаны SmArtKar, EnterTheJake, Rex9001, jimmyl, Jacquerel, Comxy, MrMelbert, Krysonism, Nebulacrity и EdgeLordExe; в истории файлов книг — OnlineGirlfriend, Goat, Ghom, Profakos, jimmyl, Sealed101, YesterdaysPromise, Jacquerel, tattle, EnterTheJake, ViktorKoL, Rex9001, Comxy, ShizCalev, Tramz, necromanceranne, MrMelbert и EdgeLordExe. Это участники истории файлов; авторство отдельных состояний следует смотреть в связанных изменениях.

`heretic_books_lefthand.dmi` и `heretic_books_righthand.dmi` переупаковывают существующие спрайты BlueMoon из `icons/mob/inhands/misc/books_lefthand.dmi` и `books_righthand.dmi`: `kingyellow` → `ash`, `necronomicon` → `rust`, `demonomicon` → `flesh`, `ithaqua` → `void`, `bible` → `blade`, `codex` → `moon`, `scientology` → `cosmic`. Кадры и направления сохранены; цвет и дополнительные эффекты задаёт игровой код.

Источники предметов и границ полей перечислены в `heretic_oldpath_effects.txt`.

## Анимация печатей и воспоминаний

Все одиннадцать `sigil_*` в `heretic_feedback.dmi` имеют циклы из 24 кадров по 0.1 секунды. Рамка неподвижна: внутри горит пламя Пепла, разрастаются ветви Ржавчины, моргает глаз Плоти, кружатся снежинки Пустоты, движется лезвие, меняется лунная тень, вращается звезда Космоса, сходятся детали Замка, течёт вода Пучины, качается осколок Стекла и пульсирует капля Крови. Старые печати перерисованы с чётким контуром и палитрой своего пути; у Пучины, Стекла и Крови сохранены их морские, стеклянные и кровавые мотивы. HUD использует те же анимации из `heretic_alerts.dmi`.

`moon_insanity_overlay` заменён полумесяцем с тремя движущимися осколками, 16 кадров по 0.1 секунды. Знак занимает верхние 14 пикселей полотна; высота нимба учитывает эту позицию. `cloud_swirl` сохраняет исходные кадры, задержки и прозрачность, но его палитра стала нейтральной: оттенки Пепла и Пустоты задаются в DM без смешения с исходной зеленью.

`mansus_memory_idle` использует видимый кадр исходной `small_rune_1`: знак покачивается, вокруг него движутся три частицы. Цикл из 24 кадров не содержит стирания; воспоминание остаётся видимым до сбора или завершения визита. Исходные `small_rune_*` не изменены. Авторство и лицензия донорских ресурсов остаются указанными выше.
