# Источники спрайтов еретика

Лицензия ресурсов и производных работ — [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/). Пути файлов ниже относятся к корню проекта либо к указанному репозиторию источника. Таблицы фиксируют происхождение рисунков; последующие перекраски, перерисовки и анимации сохраняют это авторство.

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




| Файл | Исходные состояния и файлы | Изменения |
| --- | --- | --- |
| `heretic_feedback.dmi`: `sigil_ash`, `sigil_rust`, `sigil_flesh`, `sigil_void`, `sigil_blade`, `sigil_moon`, `sigil_cosmic` | [icons/ui_icons/antags/heretic/knowledge.dmi](https://github.com/tgstation/tgstation/commits/5f093a8cfbbe269b15bc73535f230909218e38d6/icons/ui_icons/antags/heretic/knowledge.dmi): `node_ash`, `node_rust`, `node_flesh`, `node_void`, `node_blade`, `node_moon`, `node_cosmos`. ViktorKoL и участники tgstation, [переработка интерфейса знаний](https://github.com/tgstation/tgstation/commit/a40a92140d49c87495a1685cbe5f4a5ce55d593d). | Переименованы без изменения пикселей; статичные печати отличают пути на книге, рунах, полях и алертах. |
| `heretic_alerts.dmi` | Семь `sigil_*` из строки выше. | Статические значки: печати перенесены целиком, пиксели не изменены. Компактный лист HUD занимает 36 КиБ после декодирования RGBA. |
| `heretic_books.dmi` | [icons/obj/service/library.dmi](https://github.com/tgstation/tgstation/commits/5f093a8cfbbe269b15bc73535f230909218e38d6/icons/obj/service/library.dmi): `booksacredflame`, `demonomicon`, `bookblind`; [icons/obj/storage/book.dmi](https://github.com/tgstation/tgstation/commits/5f093a8cfbbe269b15bc73535f230909218e38d6/icons/obj/storage/book.dmi): `ithaqua`, `tome`; [icons/obj/antags/eldritch.dmi](https://github.com/tgstation/tgstation/commits/5f093a8cfbbe269b15bc73535f230909218e38d6/icons/obj/antags/eldritch.dmi): `ogbook`, `book_morbus`, анимации `book` и `book_morbus` | Обложки переименованы в `ash`, `flesh`, `moon`, `void`, `blade`, `rust`, `cosmic` соответственно. Каждая дополнена состояниями `_open`, `_opening`, `_closing`. Космос использует полные анимации `book_morbus`. У остальных `_opening` состоит из первого кадра собственной обложки и кадров 14–20 исходного `book_opening`; `_closing` — из кадров 0–6 исходного `book_closing` и первого кадра собственной обложки (нумерация с нуля). `_open` сохраняет полный `book_open`. Задержки исходных кадров умножены на 0.8, 1.35, 1.1, 1.5, 0.5, 0.85, 0.75 для Пепла, Ржавчины, Плоти, Пустоты, Клинка, Луны, Космоса; добавленный кадр обложки длится не более 1 децисекунды. Пиксели исходных кадров не изменены. |

В истории исходного файла эффектов указаны SmArtKar, EnterTheJake, Rex9001, jimmyl, Jacquerel, Comxy, MrMelbert, Krysonism, Nebulacrity и EdgeLordExe; в истории файлов книг — OnlineGirlfriend, Goat, Ghom, Profakos, jimmyl, Sealed101, YesterdaysPromise, Jacquerel, tattle, EnterTheJake, ViktorKoL, Rex9001, Comxy, ShizCalev, Tramz, necromanceranne, MrMelbert и EdgeLordExe. Это участники истории файлов; авторство отдельных состояний следует смотреть в связанных изменениях.

`heretic_books_lefthand.dmi` и `heretic_books_righthand.dmi` переупаковывают существующие спрайты BlueMoon из `icons/mob/inhands/misc/books_lefthand.dmi` и `books_righthand.dmi`: `kingyellow` → `ash`, `necronomicon` → `rust`, `demonomicon` → `flesh`, `ithaqua` → `void`, `bible` → `blade`, `codex` → `moon`, `scientology` → `cosmic`. Кадры и направления сохранены; цвет и дополнительные эффекты задаёт игровой код.

Источники предметов и границ полей перечислены в `heretic_oldpath_effects.txt`.

## Одежда, действия, Замок и Пучина

Источник: [tgstation/tgstation](https://github.com/tgstation/tgstation), ревизия `e49d800824115411dfd2740d705369f07afa8819`.

Лицензия ресурсов: [Creative Commons Attribution-ShareAlike 3.0](https://creativecommons.org/licenses/by-sa/3.0/), согласно [README источника](https://github.com/tgstation/tgstation/blob/e49d800824115411dfd2740d705369f07afa8819/README.md#license).

Состояния распределены по путям без изменения видимых пикселей, направлений, кадров и параметров анимации. У клинков удалены прозрачные поля: из полотна 64×64 оставлен прямоугольник от (7, 20) до (55, 56), с началом координат в левом верхнем углу. Игровой код компенсирует центрирование полотна 48×36, сохраняя положение в обеих руках. Масштаб и оттенок отдельных эффектов задаёт игровой код.

| Файлы | Состояния | Источник и история авторства |
| --- | --- | --- |
| `heretic_robes.dmi`, `heretic_robes_<path>_worn.dmi` | `ash_armor`, `rust_armor`, `flesh_armor`, `void_armor`, `blade_armor`, `moon_armor`, `cosmic_armor` и их варианты `_t` | [Предметы](https://github.com/tgstation/tgstation/commits/e49d800824115411dfd2740d705369f07afa8819/icons/obj/clothing/suits/armor.dmi), [на теле](https://github.com/tgstation/tgstation/commits/e49d800824115411dfd2740d705369f07afa8819/icons/mob/clothing/suits/armor.dmi). Спрайты OrcaCora и GregorDM, указанные в [переработке еретика](https://github.com/tgstation/tgstation/commit/a2c7c8e57b8f9b73eabb8f8b4c164f29df4fc334). |
| `heretic_hoods.dmi`, `heretic_hoods_<path>_worn.dmi` | Те же семь состояний без `_t` | [Предметы](https://github.com/tgstation/tgstation/commits/e49d800824115411dfd2740d705369f07afa8819/icons/obj/clothing/head/helmet.dmi), [на голове](https://github.com/tgstation/tgstation/commits/e49d800824115411dfd2740d705369f07afa8819/icons/mob/clothing/head/helmet.dmi). Та же переработка и авторы. Прозрачные состояния капюшонов Ржавчины и Космоса сохранены: поднятый капюшон нарисован в самой мантии `_t`. |
| `heretic_blades_lefthand.dmi`, `heretic_blades_righthand.dmi`, `heretic_blades_<path>_lefthand.dmi`, `heretic_blades_<path>_righthand.dmi` | `eldritch_blade`, `ash_blade`, `rust_blade`, `flesh_blade`, `void_blade`, `dark_blade`, `moon_blade`, `cosmic_blade` | [Левая рука](https://github.com/tgstation/tgstation/commits/e49d800824115411dfd2740d705369f07afa8819/icons/mob/inhands/64x64_lefthand.dmi), [правая рука](https://github.com/tgstation/tgstation/commits/e49d800824115411dfd2740d705369f07afa8819/icons/mob/inhands/64x64_righthand.dmi). Авторы исходных клинков также перечислены в [источники спрайтов](heretic_attribution.md). |

## Замок и Пучина

Перечисленные ниже донорские состояния перенесены без изменения видимых пикселей. Одежда и знак Пучины подготовлены отдельно; их обработка описана в таблице. Источники донорских ресурсов: [tgstation `5f093a8`](https://github.com/tgstation/tgstation/tree/5f093a8cfbbe269b15bc73535f230909218e38d6), [NovaSector `cb61cf4`](https://github.com/NovaSector/NovaSector/tree/cb61cf4cde8b13d037c925edeeaf314e94b0f283), [Paradise `3add7ad`](https://github.com/ParadiseSS13/Paradise/tree/3add7ad52a2da72ab7568ec977fcfeceb6a2b86e). Лицензия этих файлов — CC BY-SA 3.0; см. [tgstation README](https://github.com/tgstation/tgstation/blob/5f093a8cfbbe269b15bc73535f230909218e38d6/README.md#license), [NovaSector README](https://github.com/NovaSector/NovaSector/blob/cb61cf4cde8b13d037c925edeeaf314e94b0f283/README.md#license) и [Paradise README](https://github.com/ParadiseSS13/Paradise/blob/3add7ad52a2da72ab7568ec977fcfeceb6a2b86e/README.md).

| Назначение | Исходные состояния и авторство | Упаковка |
| --- | --- | --- |
| `heretic_lock.dmi`, `heretic_blades_lock_*hand.dmi` | tgstation: `key_blade`, `icons/obj/weapons/khopesh.dmi` и `icons/mob/inhands/64x64_*hand.dmi`; `skeleton_key`, `icons/obj/mining_zones/artefacts.dmi`. [История клинков](https://github.com/tgstation/tgstation/commits/5f093a8cfbbe269b15bc73535f230909218e38d6/icons/obj/weapons/khopesh.dmi), [история ключа](https://github.com/tgstation/tgstation/commits/5f093a8cfbbe269b15bc73535f230909218e38d6/icons/obj/mining_zones/artefacts.dmi). | Ключ переименован в `lock_key`; прозрачные поля клинков обрезаны так же, как у семи прежних путей. |
| Мантия и капюшон Замка | tgstation: `lock_armor`, `lock_armor_t`, те же четыре файла одежды, что у остальных путей выше. | Полные направления; общие предметные листы и отдельные `heretic_*_lock_worn.dmi`. |
| `heretic_tide.dmi`, `heretic_blades_tide_*hand.dmi` | Собственный рисунок 2026-09: гарпун утопленника из позеленевшей бронзы с канатной обмоткой и окном чёрной воды в жале. Донорский `crusher_harpoon` NovaSector больше не используется. | `tide_blade` 24 кадра по 1 дс, в руках четыре направления. Отдельный световой слой `tide_blade_glow` удалён. |
| Колокол Пучины | Собственный рисунок 2026-09: водолазный колокол с иллюминатором чёрной воды, балянусами и прядями водорослей. Донорский `desk_bell` Paradise больше не используется. | `tide_bell` (24 x 1.3 дс) и `tide_bell_ring` (24 x 0.7 дс, один проход) в `heretic_relics.dmi`; в `heretic_relics_*hand.dmi` колокол с кольцом, иллюминатором и язычком (idle 4 x 7.8, звон 8 x 2.1). |
| Мантия и капюшон Пучины | Собственный рисунок 2026-09: плащ из лент водорослей поверх чёрной воды, бронзовый воротник водолаза, балянусы, манжеты, биолюминесцентные огни, капли в лужу. | `tide_armor`, `tide_armor_t` в общих листах и `heretic_*_tide_worn.dmi`: 32 кадра по 1 дс, четыре направления, бегущая волна вдоль лент. Капюшон - грива водорослей с закрытым лицом, 32 кадра. |
| Эффекты и действия Пучины | Собственные рисунки 2026-09; донорские `bubbles`, `wave1`-`wave4`, `splash`, `carp_rift` tgstation больше не используются. | `heretic_tide_effects.dmi`: `tide_grasp`, `tide_wave` (16 x 0.5), `tide_burst` (24 x 0.75), `tide_warning` (20 x 1), `tide_mark`, `tide_puddle` (16 x 1). `heretic_tide_well.dmi`: `tide_whirlpool` 96x96, 16 x 1. Действия `tide_release`, `tide_undertow`, `tide_well`, `tide_deluge`, `tide_ascend` и активные варианты с суффиксом 1 - 24 кадра по 1 дс. |
| Печати и нимбы | tgstation `knowledge.dmi`: `node_lock`, `grasp_lock`, `node_locked`, `node_finished`; действия `lock_ascension`, `carp_rift`; эффект `bubbles`. | `sigil_lock` ← `node_lock` в `heretic_feedback.dmi` и `heretic_alerts.dmi`. `sigil_tide` в обоих листах и в `heretic_tide.dmi` - собственный медальон 2026-09: иллюминатор в бронзовом кольце с приливом и колоколом, 24 кадра. В `heretic_lock_effects.dmi`: `lock_warning`, `lock_grasp`, `lock_seal`, `lock_open` в порядке исходных состояний знаний. |
| Врата Замка | tgstation `icons/effects/96x96.dmi`: `door`, `door_opening`, `door_closing`; [история и авторство](https://github.com/tgstation/tgstation/commits/5f093a8cfbbe269b15bc73535f230909218e38d6/icons/effects/96x96.dmi). | `lock_barrier`, `lock_closing` в `heretic_lock_gate.dmi`, холст 32x32, 24 кадра закрытия; масштаб задаётся в DM. |
| Книги | tgstation `icons/obj/service/library.dmi`: `bookknock` → `lock`, `fishbook` → `tide`; открытая книга и переходы из `icons/obj/antags/eldritch.dmi`, как описано в `heretic_attribution.md`. | Скорости анимаций 0.7 и 1.2. Полные 28 кадров чтения и по 8 кадров открытия/закрытия. В руках сохранены BlueMoon `scrapbook` → `lock`, `album` → `tide` из `icons/mob/inhands/misc/books_*hand.dmi`. |

Эффекты Замка позднее перерисованы в бронзовой палитре, врата осветлены; у волн Пучины изменены палитра, анимация и отметки предупреждения.

## Взмахи, тени и медальон

| Файл | Состояния | Источник и авторство | Лицензия |
| --- | --- | --- | --- |
| `heretic_medallion.dmi` | `watching_eye`, `watching_eye_open`, `watching_eye_closed` | [Bubberstation, heretic_misc.dmi](https://github.com/Bubberstation/Bubberstation/blob/250db30e0c4f97590dfe25c79aca09367f3badb7/modular_zubbers/icons/obj/heretic_misc.dmi). Внесены nikothedude в [переработке еретика](https://github.com/Bubberstation/Bubberstation/commit/c3c54bf66c9f6849e6e3efd731c165e50fe15c5f), с участием Roxy; [история файла](https://github.com/Bubberstation/Bubberstation/commits/250db30e0c4f97590dfe25c79aca09367f3badb7/modular_zubbers/icons/obj/heretic_misc.dmi). | CC BY-SA 3.0, [README](https://github.com/Bubberstation/Bubberstation/blob/250db30e0c4f97590dfe25c79aca09367f3badb7/README.md#license). |

Текст CC BY-SA 3.0: https://creativecommons.org/licenses/by-sa/3.0/.

## Хватки

Спрайты хваток взяты из [tgstation/tgstation](https://github.com/tgstation/tgstation), снимок `5f093a8cfbbe269b15bc73535f230909218e38d6`.

Лицензия — [Creative Commons Attribution-ShareAlike 3.0 Unported](https://creativecommons.org/licenses/by-sa/3.0/), согласно [README источника](https://github.com/tgstation/tgstation/blob/5f093a8cfbbe269b15bc73535f230909218e38d6/README.md#license). Состояния переименованы и упакованы отдельно; кадры, направления и задержки сохранены. Масштаб, скрещивание лезвий и серебристый цвет зеркальной трещины задаются игровым кодом.

| Файл и состояние | Исходный файл и состояние |
| --- | --- |

Авторы указаны в связанной истории исходных файлов. В истории эффектов Мансуса участвуют SmArtKar, EnterTheJake, Rex9001, jimmyl, Jacquerel, Comxy, MrMelbert, Krysonism, Nebulacrity и EdgeLordExe; космический эффект добавлен Comxy в [73ba9046dfe](https://github.com/tgstation/tgstation/commit/73ba9046dfe).

## Стекло и Кровь

| Основа | Источник и авторство | Обработка |
| --- | --- | --- |
| Кристалл и кровавые сгустки хваток | [tgstation, `icons/effects/effects.dmi`](https://github.com/tgstation/tgstation/blob/5f093a8cfbbe269b15bc73535f230909218e38d6/icons/effects/effects.dmi), состояния `cain_abel_crystal` и `blood_wisp`. Ben10Omintrix и участники tgstation, [добавление Cain & Abel](https://github.com/tgstation/tgstation/commit/7c81098d3368152e3a91b226fe5099ac5890a81c), [история файла](https://github.com/tgstation/tgstation/commits/5f093a8cfbbe269b15bc73535f230909218e38d6/icons/effects/effects.dmi). | Палитры приведены к цветам путей. Кристалл сдвинут вверх и дополнен сходящимися гранями; кровавые сгустки расположены в трёх точках с разными фазами и дополнены дугой. |
| Мантия, капюшон, клинок и линза Стекла | Нарисованы заново по геометрии частей тела `icons/mob/human_parts_greyscale.dmi`; чужие спрайты не используются. | Пластины каркаса, нагрудник, шипы, осколки, куколь из сегментов с забралом и рогами, клинок и линза нарисованы по маскам торса, рук и головы для всех четырёх направлений; всё стекло полупрозрачно. |
| Посадка мантии и капюшона Крови | Нарисованы заново по геометрии частей тела `icons/mob/human_parts_greyscale.dmi`; чужие спрайты не используются. | Сюртук, наплечники, сбруя, полы и капюшон построены по маскам торса, рук и головы для всех четырёх направлений. |
| Чтение и открытие книг | EnterTheJake, tgstation `icons/obj/antags/eldritch.dmi`, [958116f9986](https://github.com/tgstation/tgstation/commit/958116f9986). Полная история переноса приведена в [источники спрайтов](heretic_attribution.md). | Сохранена геометрия перелистывания; добавлены собственные закрытые переплёты, цвета подвесок и задержки 1.05/1.15 децисекунды. |
| Книги в руках | Существующее состояние BlueMoon `album` из `icons/mob/inhands/misc/books_lefthand.dmi` и `books_righthand.dmi`, уже включённое в листы книг как `tide`. | Сохранены положение, размер и четыре проекции; заменены материалы переплёта и добавлена светлая застёжка. |

## Эхо

| Ресурс | Основа и изменения |
| --- | --- |
| Резонатор | `mania_motor_inactive` из `icons/obj/clockwork_objects.dmi`. Сохранены объёмная подставка и изогнутая рама, добавлены три звучащие трубы и движущиеся блики. |
| Книга | Переплёт Замка и проекции Клинка из [источники спрайтов](heretic_attribution.md); анимации открытия и чтения EnterTheJake из [источники спрайтов](heretic_attribution.md). Живой глаз на обложке и развороте следит за читателем и моргает; струны и нотные страницы движутся в разных фазах. Глаз на развороте расположен ниже парящей печати. Открытие и закрытие занимают по 0,8 секунды. |
| Хватка | `moon_grasp`; [источники спрайтов](heretic_attribution.md). Латунные всполохи, расходящаяся волна и полное затухание. |
| Печать | Обод `sigil_lock` из [источники спрайтов](heretic_attribution.md). Собственный центральный знак меняет форму: дуги расходятся с запаздыванием, внутренний просвет сжимается, по контуру проходит свет. Цикл — 48 кадров за 2,4 секунды. |

## Реликвии

`lantern-blue` и `lantern-blue-on` основаны на уже включённых в проект спрайтах `heretic_oldpath_effects.dmi`, исходно `icons/obj/lighting.dmi` из [tgstation, ревизия 5f093a8cfbbe269b15bc73535f230909218e38d6](https://github.com/tgstation/tgstation/tree/5f093a8cfbbe269b15bc73535f230909218e38d6). [История авторства](https://github.com/tgstation/tgstation/commits/5f093a8cfbbe269b15bc73535f230909218e38d6/icons/obj/lighting.dmi), лицензия [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/). Корпус сохранён, добавлены движение фитиля и ледяных частиц.

Прежний медальон в `heretic_medallion.dmi` использовал рисунок Bubberstation с добавленным морганием. Его надетый вариант был основан на `eye_medalion` из `icons/mob/clothing/neck.dmi`. Эти сведения сохранены для истории; в сентябре 2026 года предметный и надетый рисунки заменены самостоятельными подвесками.

`heretic_medallion.dmi`, `heretic_medallion_worn.dmi`, `heretic_medallion_lefthand.dmi` и `heretic_medallion_righthand.dmi`: самостоятельные рисунки 32×32 под CC BY-SA 3.0. У каждого пути собственная подвеска: угольная кадильница Пепла, проржавевшая шестерня, костяная оправа Плоти, ледяной осколок Пустоты, скрещённые клинки, лунный серп, орбиты Космоса, ключ Замка, иллюминатор Пучины, огранённый осколок Стекла, капля Крови, камертон Эха, песочные часы и свеча Воска. Общий медальон до выбора пути также перерисован. Сохранены три степени раскрытия глаза и длительность цикла 31,2 дс. Одинаковые соседние кадры объединены с суммированием задержек; одинаковые направления хранятся одним набором кадров.

## Демоны Мансуса

`heretic_demons.dmi` использует исходные рисунки из `icons/mob/eldritch_mobs.dmi`: `raw_prophet`, `stalker`, `ash_walker`, `armsy_start`, `armsy_mid`, `armsy_end`. Файл пришёл из tgstation вместе с переносом еретиков; в истории BlueMoon этот перенос отмечен коммитом `eb8574d6d61` автора kiwedespars. Исходный файл не изменён.

Рисунки и производная анимация распространяются по [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/), согласно лицензии звуковых и графических ресурсов проекта. Сохранены исходные силуэты, направления и палитры; у Пепельного духа добавлены тёплые оттенки жара и прозрачные частицы пепла.

Самостоятельные рисунки новых путей, включая Песок и Воск, распространяются под той же CC BY-SA 3.0. Книги новых путей используют производные анимации открытия и чтения EnterTheJake, указанные выше.

Нимбы вознесения всех путей описаны в разделе «Нимбы вознесения 2026-09-18».

## Дух

Сет пути Духа нарисован заново в сентябре 2026 года: перевозчик в истлевшем саване, обшитом серебряными оболами, с монетами на глазах под куколем. Лицензия CC BY-SA 3.0, донорские ресурсы не используются.

| Файл | Состояния | Описание |
| --- | --- | --- |
| `heretic_robes_spirit_worn.dmi`, `heretic_hoods_spirit_worn.dmi`, `heretic_robes.dmi`, `heretic_hoods.dmi` | `spirit_armor`, `spirit_armor_t` | Саван с клином оболов, цепью-перевязью, кошелём и монетами-грузилами на подоле, туман душ; куколь с пустым лицом и монетами на глазах. 24 кадра по 1 дс, четыре направления. |
| `heretic_spirit.dmi`, `heretic_blades_spirit_*hand.dmi`, `heretic_relics_spirit_*hand.dmi` | `spirit_blade`, `spirit_lantern` | Багор перевозчика с полой рукоятью и монетой (24 x 1 дс), железный фонарь с огнём душ (24 x 1.3 дс). |
| `heretic_spirit_effects.dmi` | `spirit_soul`, `spirit_tether`, `spirit_mark`, `spirit_grasp`, `spirit_burst`, `spirit_step`, `spirit_reap`, `spirit_ascend` | Неприкаянная душа, цепь связи, обол над головой, ладонь тумана, столб душ, переправа, жатва, вознесение. |
| `heretic_actions.dmi`, `heretic_alerts.dmi`, `heretic_feedback.dmi` | `spirit_sever`, `spirit_step`, `spirit_reap`, `spirit_bell`, `spirit_crown`; `sigil_spirit` | Значки способностей (24 x 1 дс) и медальон-сигил: фонарь в серебряном кольце. |
| `heretic_medallion*.dmi` | `spirit_watching_eye*` | Обол с чеканным глазом на серебряной цепочке; предмет, надетый вид и руки в одном образе. |
| `heretic_books*.dmi` | `spirit`, `spirit_opening`, `spirit_closing` | Реестр перевозчика на общей основе книг путей. |
| `ritual_inscriptions_extended.dmi`, `ritual_casts_extended.dmi` | `spirit_ferry_*` | Печать: лодка перевозчика с фонарём на шесте, заменила `spirit_gate_*`. |


## Старые пути: значки, нимбы и эффекты

Перерисованы в сентябре 2026 года на замену донорским состояниям tgstation (значки из `actions_ecult.dmi`; `cosmic_explosion`, `space_explosion`, `cosmic_grasp` из `64x64.dmi`; `slash` из `effects.dmi`; `space_protection_*` из `fields.dmi`; боевые вспышки и метки из `icons/effects/eldritch.dmi`; `cosmic_diamond` и луч из `beam.dmi`; `dio_knife` и `pierced_illusion`; `slingbeam` Monkestation; `tumor.dmi`; `living_heart`; `circle_wave`; `cosmic_domain` из `160x160.dmi`; `void_blink_*` из `96x96.dmi`; `entropic_plume`; `eldritch_projectile`; `ash_shift` из `mob.dmi`). Собственный рисунок, CC BY-SA 3.0. Неиспользуемые донорские состояния удалены: из `heretic_actions.dmi` - `rune_break` и дубли `*1`; из `heretic_feedback.dmi` - `small_rune_1`-`small_rune_7`, `eye_open`, `eye_pulse`, `eye_close`, `realitycrack`, `lock_aura`, `mansus_memory_idle`, `emark3`.

| Файл | Состояния | Описание |
| --- | --- | --- |
| `heretic_actions.dmi` | все состояния семи старых путей и базовых способностей (`mansus_grasp`, `ash_shift`, `mad_touch`, `blood_siphon`, `cleave`, `flames`, `fire_ring`, `smoke`, `ash_rekindle`, `worm_ascend`, `worm_contract`, `flesh_mend`, `corrode`, `rust_wave`, `rust_root`, `entropic_plume`, `voidblink`, `voidpull`, `void_boundary`, `void_waltz`, `furious_steel`, `cursed_steel`, `shatter`, `blade_master`, `moon_smile`, `moon_parade`, `moon_ringleader`, `mind_gate`, `cosmic_rune`, `star_touch`, `star_blast`, `cosmic_domain`, `space_crawl`, `mute`, `mansus_link`), а также Замка (`lock_seal`, `lock_bolt`, `lock_court`, `lock_release`, `lock_ascension`), Крови (`blood_release`, `blood_lance`, `blood_pact`, `blood_reckoning`, `blood_ascend`) и Стекла (`glass_release`, `glass_shards`, `glass_barrier`, `glass_storm`, `glass_ascend`) | Значки способностей, 24 x 1 дс, в одном стиле с сетами 2026-09: объём, цветной контур, материал пути (пепел и угли, плоть, ржавое железо, лёд, сталь с золотой гардой, лунное серебро, тёмный фиолет со звёздами, тёмная латунь, живая кровь, стеклянные пластины). Донорские значки tgstation (`actions_ecult.dmi`, в том числе `uncuff`, `apetra_vulnera`, `burglarsfinesse`, `caretaker`) больше не используются. |
| `heretic_feedback.dmi` | `cleave`, `smoke`, `cloud_swirl`, `cosmic_cloud`, `cosmic_ring`, `cosmic_carpet`, `cosmic_gem`, `moon_insanity_overlay`, `ring_leader_effect`, `eye_flash` | Боевые вспышки в серых тонах (цвет задаёт код): разрезы, дым, завихрение, туманность, кольцо, звёздная плита, осколок, серп со спиралью, кольцо стойки, глаз. |
| `heretic_feedback.dmi` | `emark1`, `emark2`, `emark4`, `emark5`, `emark6`, `emark7` | Метки Плоти, Пустоты, Пепла, Клинка, Луны и Космоса на жертве, 16 x 1 дс: кольцо пути с предметом (сердце, ледяная звезда, уголёк, кинжал, серп, звезда). |
| `heretic_spell_effects.dmi`, `heretic_grasp_large.dmi` | `cosmic_explosion`, `space_explosion`, `cosmic_grasp` | Звёздные вспышки 64x64, 12 x 1 дс. |
| `heretic_slashes.dmi` | `left_swing`, `right_swing` | Стальной серп взмаха 96x96, 12 x 0.5 дс; поворот по направлению задаётся в DM. |
| `heretic_oldpath_effects.dmi` | `space_protection_west`, `space_protection_east`, `space_protection_north`, `space_protection_south` | Кромка поля 8 x 1 дс в серых тонах, цвет задаёт код. |
| `heretic_effects.dmi` | `cosmic_star`, `cosmic_beam`, `rust_bolt`, `ash_shift_out`, `ash_shift_in` | Звезда Мансуса (16 x 1), нить луча для Beam (8 x 1), снаряд Длани покровителя (8 x 1), пепельный сдвиг (12 x 1). |
| `heretic_grasp.dmi`, `heretic_shadows.dmi` | `blade_grasp`, `moon_grasp`; `slingbeam` | Крест стальных росчерков (12 x 0.5), осколки зеркала (16 x 0.5); лента пустоты для Beam (8 x 1). |
| `heretic_rust_heart.dmi` | `tumor` | Вросшее сердце ржавчины с корнями 64x32 (12 x 1). |
| `heretic_spell_effects.dmi`, `heretic_domain.dmi`, `heretic_void.dmi`, `heretic_plume.dmi` | `circle_wave` 64x64; `cosmic_domain` 160x160; `void_blink_in`, `void_blink_out` 96x96; `entropic_plume` 160x160 | Кольцо Луны (1 кадр, масштаб и прозрачность задаёт код), звёздная туманность с искрами (16 x 0.5), провал пустоты (12 x 0.5), конус ржавого облака (14 x 2, одно направление, поворот задаёт код). |

## Дом памяти в Мансусе

`heretic_mansus.dmi` и `heretic_mansus_gates.dmi` — составные и переработанные ресурсы для пятнадцати путей. Лицензия [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/).

| Основа | Использование и изменения |
| --- | --- |
| BlueMoon `icons/turf/floors.dmi`; стены `cult_wall`, `sandstone_wall`, `icerock_wall`, `rusty_wall`, `iron_wall`, `clockwork_wall`, `diamond_wall`, `rock_wall`, `wood_wall` из `icons/turf/walls/` | Материалы полов, галерей и кладки. Скорректированы оттенки и освещённость; края стен собраны из исходных четвертей. Провал получил собственные края. Пепельные плиты дополнены угольками. |
| [tgstation `structures.dmi`](https://github.com/tgstation/tgstation/commits/5f093a8cfbbe269b15bc73535f230909218e38d6/icons/obj/antags/cult/structures.dmi): `forge`, `forge_off`, `talismanaltar`, `talismanaltar_off`, `tomealtar`, `tomealtar_off`, `pylon`, `cultgirder` | Основа святилищ и жаровен. Изменены материалы и свечение, добавлены свечи, пламя и клинок. |
| [tgstation `meat_wall.dmi`](https://github.com/tgstation/tgstation/commits/5f093a8cfbbe269b15bc73535f230909218e38d6/icons/turf/walls/meat_wall.dmi): `meat_wall-255` | Переработанная поверхность пола Плоти. |
| BlueMoon `icons/obj/cult.dmi`, `icons/obj/lighting.dmi`, `icons/obj/candle.dmi`, `icons/effects/eldritch.dmi` | Пламя, свечи, кристаллы, космическое святилище, разломы и свечение при срабатывании. Слои собраны в отдельные состояния, цвет и прозрачность адаптированы к путям. |
| `heretic_robes_<path>_worn.dmi`, `heretic_hoods_<path>_worn.dmi` | Преследователи и видения: пустые мантии с рваным подолом и дымным следом. Сохранены исходные направления и кадры одежды. Источники и авторы комплектов перечислены выше. |
| `heretic_lock_gate.dmi`, `heretic_feedback.dmi`, `heretic.dmi` | Резная вставка врат, знаки воспоминаний, подсказка и детали святилищ. Вставка вырезана из прозрачного полотна без изменения размера видимых пикселей. Каменная арка, её кладка и ступени собраны отдельно. Происхождение вставки, знаков и клинков указано в предыдущих разделах. |

Ревизия новых источников tgstation: `5f093a8cfbbe269b15bc73535f230909218e38d6`. В истории двух указанных файлов перечислены carlarctg, LemonInTheDark, OrionTheFox и YesterdaysPromise; ссылки ведут на историю соответствующих ресурсов. Лицензия исходников указана в [README tgstation](https://github.com/tgstation/tgstation/blob/5f093a8cfbbe269b15bc73535f230909218e38d6/README.md#license). Существующие авторы ресурсов BlueMoon сохраняются.

## Правки 2026-09-16

Собственные рисунки, CC BY-SA 3.0.

| Файл | Состояния | Описание |
| --- | --- | --- |
| `heretic_mansus_gates.dmi` | `*_gate_open` пятнадцати путей | Проём в арке закрытых врат: тьма с дизерным светом, распахнутые створки и мотив пути (капли, угли, труха, звёзды, кольца, осколки, песок, свечи, волны, огоньки, серп, орбита, блики, жилы, цепи), 8 x 2 дс. |
| `heretic_mansus.dmi` | `*_wall0`, `blade_hunter`, `lock_hunter` | Заливка стены без открытых соседей в материале пути; охотники Клинка и Замка получили цикл 8 x 2 дс. Удалены дубли `*_hud`, `*_echo`, `*_abyss` (эхо строится кодом из охотника). |
| `heretic_actions.dmi` | `moon_smile`, `moon_parade`, `ash_shift`, `worm_ascend`, `smoke`, `mansus_link`, `spirit_sever`, `void_waltz`, `mad_touch`, `lock_court`, `fire_ring`, `star_blast`, `cosmic_rune`, `space_crawl`, `cosmic_domain`, `entropic_plume`, `mute`, `glass_shards` | Значки перерисованы цельным предметом способности (зеркало, маски, стена в пепле, червь кольцом, головня в дыму, глаз в проёме, разорванная цепь, вихрь инея, ладонь со спиралью, латунный двор, кольцо огня, звезда, каменная руна, арка с кометой, планета с кольцом, облако ржавчины, зашитые губы). |
| `ritual_inscriptions*.dmi`, `ritual_casts*.dmi` | `ash_sun`, `cosmic_star`, `moon_crescent`, `echo_bell`, `blood_pact`, `rust_spread`, `blade_cross` | Знаки перерисованы предметом пути (солнце с пламенем, звезда с орбитой, серп с ликом, колокол с языком, капля с кольцами, изъеденная пластина, скрещённые клинки) с новыми кастами; у всех `_draw` слиты пустые первые кадры. |
| `heretic_sand.dmi`, `heretic_wax.dmi`, `heretic_tide.dmi` и их `heretic_blades_*hand.dmi` | `sand_blade`, `wax_blade`, `wax_grasp`, `tide_blade` | Сабля из песчаной стали с часами в гарде; нож для снятия воска с огарком на обухе; крюк гарпуна на одну сторону; ладонь хватки Воска плотнее. |
| `heretic_relics_*hand.dmi`, `heretic_books_*hand.dmi` | `lantern-blue`, `lantern-blue-on`, `tide_bell`, `tide_bell_ring`, `cosmic` | Инхенды по форме предметов: фонарь с кольцом и колпаком, колокол, книга Космоса общего размера. Удалены неиспользуемые `watching_eye*` из реликвий и серый `lock_key` из `heretic_lock.dmi`. |
| `heretic_lock_effects.dmi`, `heretic_glass_effects.dmi`, `heretic_spirit_effects.dmi`, `heretic_domain.dmi`, `heretic_tide_effects.dmi`, `heretic_feedback.dmi` | `lock_open`, `glass_prism`, `glass_prism_split`, `spirit_tether`, `cosmic_domain`, `tide_warning`, `cosmic_ring` | Распад замка со звеньями; кристалл на треноге с бегущим бликом и лучом по направлению; цепь души вокруг торса; плотная туманность купола; гребень волны с прицелом; ровный цикл кольца. Копии `sigil_*` из `heretic_feedback.dmi` удалены, источник - `heretic_alerts.dmi`. |

## Правки 2026-09-17

Собственные рисунки, CC BY-SA 3.0. Одежда, клинки и преследователи семи путей перерисованы с тонкой фигурой, короткой палитрой и отдельной приметой пути; описания этих состояний в предыдущих разделах относятся к прежним версиям.

| Файл | Состояния | Описание |
| --- | --- | --- |
| `heretic_robes_<path>_worn.dmi`, `heretic_hoods_<path>_worn.dmi` для `blood`, `echo`, `glass`, `sand`, `wax`, `tide`, `spirit` | `<path>_armor`, `<path>_armor_t` | 32 x 1 дс, четыре стороны; `<path>_armor` - вид с откинутым капюшоном (валик у шеи, куколь на спине). Кровь: мантия из тёмной живой крови, костяная маска со слезой и рога, сердце в оправе, парящие ромбы на нитях. Эхо: саван звонаря, куколь-колокол с языком, коромысло с колокольчиками, дуги звука. Стекло: пластины с белой кромкой и зелёной тенью толщины, щиток с трещиной, парящие осколки. Песок: осыпающееся одеяние, латунный циферблат, тагельмуст, парящие часы с лентой песка. Воск: оплывший медовый воск, кованые рожки со свечами холодного огня, сургучная печать. Пучина: мантия из ламинарии с воротником водолаза, приманка удильщика над куколем, всплывающие ленты и пузыри. Дух: саван перевозчика, уходящий в туман, монеты на глазах, клин оболов, души на орбите. |
| `heretic_robes.dmi`, `heretic_hoods.dmi` | те же семь пар и семь капюшонов | Сложенная вещь на полу и пустой капюшон вместо стоящей фигуры; 1-8 кадров. |
| `heretic_<path>.dmi` | `<path>_blade` | Оружие во весь тайл, 24 x 1 дс: серп-клык из застывшей крови с костяной гардой-рогами и бьющимся рубином-сердцем; клинок-вилка звонаря со струной света и гардой-колоколом; обломок витража с розеткой цветных стёкол и парящими осколками; золотой хопеш с делениями циферблата, часами в гарде и рассыпающимся кончиком; змеевидный восковой крис с гардой-канделябром и холодным пламенем; гарпун утопленника с руной, бронзовой втулкой и якорьком на цепочке; багор перевозчика с серебряным крюком-серпом, пойманной душой и оболами на шнуре. Реликвии путей не менялись. |
| `heretic_blades_<path>_lefthand.dmi`, `heretic_blades_<path>_righthand.dmi` | `<path>_blade` | То же оружие в руке в малом размере, остриё наружу. Лист Эха остаётся 48x36. |
| `heretic_mansus.dmi` | `<path>_hunter` семи путей | Собраны заново из перерисованных мантий: рваный подол и дымный след. |
| `heretic_mansus.dmi` | вторые `<path>_hunter` с `movement = 1` для всех пятнадцати путей | Движение преследователя, 10 x 1 дс, четыре стороны, собрано из кадров покоя того же листа: наклон по ходу, отстающий подол, послеобразы в цвете пути и частицы в его манере (угли, хлопья ржавчины, капли, иней, росчерки, искры, кометные хвосты, звенья, пузыри, осколки, кольца звука, песок, огоньки душ). |

## Нимбы вознесения 2026-09-18

Собственные рисунки, CC BY-SA 3.0, донорские ресурсы не используются. Прежние нимбы (32 px с увеличением, листы `heretic_ascension_auras.dmi`, `heretic_ascension.dmi`, `heretic_spirit_ascension.dmi` и мёртвые копии в `heretic_feedback.dmi`, `heretic_tide.dmi`) удалены.

| Файл | Состояния | Описание |
| --- | --- | --- |
| `heretic_ascension_<path>.dmi` для всех пятнадцати путей | `<state>_back`, `<state>_front`, `<state>_glow` | 64x64 в родном пикселе: задний слой за телом и передний перед ногами по 48 кадров, маска свечения для темноты по 24; темп 0.5-1 дс на кадр по пути. Пепел: дымный исполин с тлеющим глазом, волна огня по кольцу. Ржавчина: трон арматуры с черепом, лапа скребёт пол. Плоть: вал мяса с глазами и миногой. Пустота: затмение, из которого тянется рука. Клинок: веер мечей, один выходит из пола. Луна: серп, в тёмной части открывается глаз. Космос: веко-созвездие и кольцо звёзд. Замок: дверь в латунной арке, пальцы и ключ. Стекло: застывший взрыв витража с глазами и ртом. Кровь: позвоночник с сердцем, рука из лужи. Эхо: колокола с черепами и хор. Песок: смерч, из которого складывается лицо. Пучина: пруд с глазом, щупальца, колокол. Воск: процессия свечей с лицом. Дух: хоровод душ над рекой, рука. |

## Мягкий силуэт 2026-09-18

Собственные рисунки, CC BY-SA 3.0. Одежда и оружие Стекла, Крови, Эха, Песка, Воска и Духа перерисованы поверх правок 2026-09-17 с теми же приметами, кадрами и задержками.

| Файл | Состояния | Описание |
| --- | --- | --- |
| `heretic_robes_<path>_worn.dmi`, `heretic_hoods_<path>_worn.dmi` для `glass`, `blood`, `echo`, `sand`, `wax`, `spirit` | `<path>_armor`, `<path>_armor_t` | Скат плеч, рукава колоколом с отдельной манжетой и швом у торса, провал у кистей, раструб подола; пояс, кайма и губа подола дугами; куколь куполом; контур каждой детали в тон её материала вместо общей чёрной обводки. Эхо: мантия-колокол, коромысло дугами по плечам. Песок: тагельмуст вместо щели-визора. Дух: накидка поверх рукавов, фонарь-клетка на груди. |
| `heretic_robes.dmi`, `heretic_hoods.dmi` | пары и капюшоны тех же путей | Сложенная вещь в тех же формах. |
| `heretic_<path>.dmi`, `heretic_blades_<path>_lefthand.dmi`, `heretic_blades_<path>_righthand.dmi` | `<path>_blade` | Кромки в координатах кадра без двойных ступеней, контур деталей в тон материала. Эхо: двузубый камертон с прорезью. Песок: серп-полумесяц хопеша. Стекло: восьмигранная розетка в свинцовой оправе. Дух: фонарь-клетка с душой на крюке. |

## Фактура 2026-09-18

Собственные рисунки, CC BY-SA 3.0. Поверх мягкого силуэта возвращён материал путей; силуэт, кадры и задержки прежние.

| Файл | Состояния | Описание |
| --- | --- | --- |
| `heretic_robes_<path>_worn.dmi`, `heretic_hoods_<path>_worn.dmi`, `heretic_robes.dmi`, `heretic_hoods.dmi` для `blood`, `echo`, `sand`, `tide`, `wax` | `<path>_armor`, `<path>_armor_t` | Кровь: треснувшая маска, глазница-провал с кровью, тлеющий зрачок, пасть с зубами и висящая челюсть. Эхо: куколь-колокол из старой бронзы с патиной, вмятиной, сколом и копотью. Песок: зерно ткани, выгоревший верх, песок в складках, бахрома и заплаты, потёртый циферблат. Пучина: куколь по оси лица, ил и тина у подола, ракушки, ржавые потёки, капли. Воск: медовый воск с глянцем, ярусы потёков с каплями, янтарный отсвет у огней. |
| `heretic_robes_glass_worn.dmi`, `heretic_hoods_glass_worn.dmi`, `heretic_robes.dmi`, `heretic_hoods.dmi` | `glass_armor`, `glass_armor_t` | Разбитый витраж в цветах вознесения пути: стёкла кобальта, багрянца, янтаря и бледной аквы в свинце по форме тела, роза-окно на груди со сценой трещины и выпадающих лепестков, куколь-купол с латунной аркой проёма, стрельчатый ланцет на спине, выбитые стёкла, цветные пятна света на полу и парящие осколки. |

## Клинок Крови 2026-09-21

Собственный рисунок, CC BY-SA 3.0. Серп-клык Крови заменён новым оружием; в руке он держался тростью поперёк груди.

| Файл | Состояния | Описание |
| --- | --- | --- |
| `heretic_blood.dmi`, `heretic_blades_blood_lefthand.dmi`, `heretic_blades_blood_righthand.dmi` | `blood_blade` | Зазубренный клинок из запёкшейся крови с яркой кромкой и долом живой крови, гарда из двух рёбер вокруг светящегося сердца, рукоять из позвонков, капля на нити. 24 x 1 дс: двойной удар сердца, свет на рёбрах, волна по долу к острию, срывающаяся капля. Лист в руке 48x36: спереди и сзади остриё вверх-наружу у бедра, в профиль клинок опущен вперёд. |

## Разинутый тигель 2026-09-22

Тигель и его зелья нарисованы заново вместо tg-состояний `crucible`, `crucible_empty`, `crucible_soul`, `clarity`, `marshal` из `icons/obj/eldritch.dmi`; прежние состояния удалены. Лицензия CC BY-SA 3.0, донорские ресурсы не используются.

| Файл | Состояния | Описание |
| --- | --- | --- |
| `heretic_crucible.dmi` | `crucible_0`..`crucible_3`, `crucible_chomp` | Чугунный котёл в мясистой челюсти с клыками, костяная поварёшка сама мешает варево, пар и пульс десны; три руны на брюхе и уровень экстракта показывают накопленные доли (32 x 1.5 дс), укус при кормлении (8 x 1 дс, один проход). |
| `heretic_crucible.dmi`, `heretic_crucible_*hand.dmi` | `crucible_soul`, `clarity`, `marshal` | Колба с душой, проходящей сквозь стекло; пробирка заката и рассвета с глазом на горизонте; фляга в окровавленной повязке (24 x 1.3 дс); в руках - уменьшенные копии (12 x 2 дс, четыре направления). |

## Правки 2026-09-23

Собственные рисунки, CC BY-SA 3.0; донорские пиксели не используются, если не указано иное.

| Файл | Состояния | Описание |
| --- | --- | --- |
| `heretic_living_heart.dmi`, `heretic_living_heart_lefthand.dmi`, `heretic_living_heart_righthand.dmi`; `heretic_actions.dmi` | `living_heart` | Анатомическое живое сердце с дугой аорты, полой веной, лёгочным стволом и венечными сосудами, из среза вены растёт шарящая жила; двойной толчок, отдача и покой, 24 дс. В руке - малое сердце в четырёх направлениях. Значок: сердце поднимается из лужи Мансуса, жила тянется к далёкой фигуре. Заменяет донорский `living_heart` из `icons/obj/eldritch.dmi`. |
| `heretic_actions.dmi` | `sand_release`, `sand_step`, `sand_burial`, `sand_final`, `wax_release`, `wax_shell`, `wax_procession`, `wax_ascend`, `wax_imprint` | Значки Песка и Воска перенесены из `heretic_sand.dmi` и `heretic_wax.dmi` в общий лист и перерисованы, 24 x 1 дс: разбитые часы, перетекающий след, стела в дюне, солнечные часы; расколотая печать, кокон, процессия свечей, венец свечей, восковая кукла на нити. |
| `heretic_oldpath_items.dmi`, `heretic_oldpath_items_lefthand.dmi`, `heretic_oldpath_items_righthand.dmi` | `rune_carver`, `eldritch_flask`, `alert_rune`, `tentacle_rune`, `madness_rune`, `small_rune_1`..`small_rune_12`, `mansus_grasp`, `mad_touch` | Нож резьбы из холодной стали с ледяным остриём и тремя глифами; ампула из ржавого железа с эссенцией в оконце; руны-ловушки, вырезанные в полу (паутина, щупальца с крюками, спираль со срывом); знаки-гвозди ржавчины, вспыхивающие и остывающие в метку; каменная ладонь хватки и касания безумия, как на значках. Заменяют одноимённые состояния tgstation в `icons/obj/eldritch.dmi` и `icons/effects/eldritch.dmi`. |
| `heretic_rift.dmi` (64x64) | `influence`, `rift`, `rift_glow` | Влияние - стянутый шов в звезде сланцевых осколков, 32 x 1 дс; разлом - тот же шов, распахнутый в бездну, дрейфующие сколы и длинные пальцы за кромкой, 48 x 1 дс; маска emissive. Заменяет донорский `reality_smash` и прежний `rift` из `heretic_effects.dmi`. |
| `heretic_alerts.dmi` | `rift_exposure` | Медальон семьи печатей с разрывом и манящим пальцем, 24 x 1 дс; обод повторяет кольцо `sigil_blood`. |
| `heretic_flesh_effects.dmi` | `flesh_rupture` | Разрыв груди при сбросе формы: бугор с жилами, обломки рёбер, лоскуты, фонтан крови, куча в луже; 12 x 0.5 дс. |
| `modular_bluemoon/icons/effects/heretic_vfx.dmi` | `rust_creep`, `soul_wisp` | Ржавчина от очагов с остывающим фронтом, 14 x 0.5 дс; душа-плата сгустком тумана со смазанным лицом, 8 x 1 дс. |
| `heretic_mansus.dmi` | `flesh_wall*`, `blood_wall*`, `cosmic_wall*`, `moon_wall*`, `wax_wall*`, `spirit_wall*`, `glass_floor0..2`, `wax_floor0..2`, `wax_path`, `void_path`, `lock_path`, `spirit_path` | Стены видом сверху-спереди с лицевой гранью: мясо с рёбрами и хрящом, запёкшийся камень с кровью в швах, камень ночного неба со знаками, лунный камень с серпами и зеркалами, закопчённая кладка под наплывами воска с нишами свечей, сланец склепа с колумбарием; полы и галереи - бутылочное стекло, серый плитняк с воском, залитый воск, изморозь, слоновая кость с латунью, белёные доски. |
| `heretic_mansus.dmi` | `sand_wall*`, `glass_wall*`, `blade_wall*`, `lock_wall*` | Собраны заново из четвертей прежних тайлов, кант идёт вдоль открытой стороны; происхождение прежнее (см. «Дом памяти в Мансусе»). |
| `heretic_mansus.dmi` | `_light` и `_decor` пепла, ржавчины, плоти, клинка, луны, космоса, замка, пучины, стекла, крови, эха, песка, воска, духа (22 состояния) | Свой предмет у каждого пути: погребальный костёр и кадило, сломанная шестерня, фонарь из кожи, меч в треснувшем полу, зеркало-псише и серп с огнём, орерий, фонарь-дверца, якорь и раковина, гнездо осколков и витражный фонарь, жертвенный стол и ампула на треноге, гонг и метроном, стела и жаровня под песком, свечное дерево, урна под саваном и клетка с душой. Свет 16 кадров, декор 8. |
| `heretic_mansus_guidance.dmi` | `trail`, `sanctuary` | Двойной шеврон с бегущей волной света; четверти охранного ромба, из которых соседние клетки складывают целые ромбы. |

## Правки 2026-09-25

Собственные рисунки, CC BY-SA 3.0; донорские пиксели не используются.

| Файл | Состояния | Описание |
| --- | --- | --- |
| `heretic_actions.dmi` | `moon_sleepwalk`, `moon_return`, `moon_voice`, `moon_masquerade`, `blade_challenge`, `blade_throat`, `blade_surrender`, `blade_feint`, `cosmic_orbit`, `spirit_hold`, `spirit_incorporeal`, `spirit_shift`, `glass_casket` | Свои значки способностей, до этого делившие кнопку с соседом по пути, 24 x 1 дс: лунатик с вытянутыми руками, кольцо-серп вокруг двойника, маска на ленте с дугами голоса, маска-домино с серпом; брошенная перчатка, клинок у горла, флаг на воткнутом клинке, клинок с ложным замахом; фигура на орбите звезды; кулак с душой, призрак, пробитый пулями, душа на нити; стеклянный саркофаг. |
| `heretic_actions.dmi` | `wax_puppet`, `wax_leak`, `lock_shackles`, `blood_drain`, `echo_ether`, `echo_voice`, `echo_lullaby`, `tide_drown`, `tide_dive`, `sand_stasis`, `pocket_leave` | Замена стоковых кнопок (`voodoo`, `handcuff`, `voidblink`) и эффектов на кнопках: кукла-свеча тает в холодном огне, лужица воска под дверью, латунные наручники с лиловой скважиной, нить от должника к ампуле, звук между двумя интеркомами, губы в решётке интеркома, музыкальная шкатулка с нотами-«з» (Эхо 48 x 0.5 дс), голова под водой с пузырями, рука уходит в слив, фигура под стеклянным колпаком с застывшим песком, дверь изнанки в свет. `sand_wind` и `echo_refrain` удалены вместе с кнопками убранных способностей. |
| `heretic_alerts.dmi` | `moon_door` | Кликабельный алерт «Увести в отражение»: медальон семьи печатей с арочным зеркалом и спящим лицом в стекле, 24 x 1 дс. |
| `heretic_alerts.dmi` | `blade_oath`, `blade_brand`, `blade_hostage`, `moon_daze`, `moon_sleeper`, `echo_drowse`, `echo_hush`, `blood_slick`, `blood_drained`, `blood_letting`, `spirit_held`, `spirit_phased`, `wax_fever`, `wax_puddle` | Алерты состояний, до этого делившие знак пути или оверлей эффекта: медальон в кольце печати пути, в центре знак состояния (перевязанные клинки, порез, клинок у горла, спираль, спящая маска, нота в «з», скоба на губах, скользкий след, пустая капля, капля на нити, душа в железной хватке, призрак с пулями, тающая голова в мареве, лужица под дверью), 24 x 1 дс. |
| `heretic_alerts.dmi` | `blood_trail_close`, `blood_trail_medium`, `blood_trail_far` (8 направлений), `blood_trail_direct`, `blood_trail_null` | След крови вместо стокового пинпойнтера `pinon*` из `icons/obj/device.dmi`: медальон Крови со стрелкой из капель к владельцу, 8 x 1.5 дс. |
| `heretic_effects.dmi` | `pocket_rift`, `pocket_rift_inner`, `pocket_rift_glow` | Разрыв изнанки вместо стокового `pierced_illusion`: дыра в воздухе в рост человека с рваной кромкой и отогнутыми лоскутами; снаружи в ней пустота, изнутри - станционный пол; белая кромка, трещины и искры отдельным слоем, код красит его чернилами пути. 24 x 1 дс. |
| `heretic_wax.dmi`, `heretic_relics_wax_lefthand.dmi`, `heretic_relics_wax_righthand.dmi` | `wax_puppet` | Восковая кукла с фитилём, сургучной печатью и бумажной биркой вместо перекрашенной вуду-куклы `icons/obj/wizard.dmi`; в руках - маленькая фигурка там же, где стоковый `electronic`. |
| `heretic_tide_effects.dmi` | `tide_current` | Течение Пучины - полоса тёмной воды по направлению с бегущими шевронами пены, 4 направления, 16 x 1 дс, стык тайлов бесшовный; раньше течение было перекрашенной лужей `tide_puddle` без направления. |
| `heretic_alerts.dmi` | `echo_ring_note`, `echo_concussion`, `blade_parry`, `rust_heal`, `void_domain`, `void_chill`, `blood_clot`, `cosmic_orbiting`, `tide_drenched`, `tide_drowning`, `glass_fracture`, `moon_lunatic`, `wax_sealed`, `wax_clinging`, `wax_effigy`, `sand_recall`, `sand_stopped` | Алерты, делившие печать пути с меткой, HUD запаса или соседним алертом, получили свои медальоны в той же манере (фигура в дугах звона, звуковой удар, клинок с отбитой пулей, ржавая плита с крестом, фигура в белой рамке, сапог во льду, свернувшаяся капля, фигура на орбите звезды, сапог в чёрной воде, голова под водой, треснувшее стекло, сбитый прицел, сургучная печать, сапог в липком воске, кукла и её двойник, клетка с возвратной стрелкой, фигура под колпаком). Копия `sigil_wax` удалена из `heretic_wax.dmi`: её использовал только алерт печати. |
