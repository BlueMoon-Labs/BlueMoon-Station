# Атрибуция ассетов параллакса

Все файлы в этом каталоге импортированы из других SS13-кодбаз. Ни один стейт не
перерисовывался: пиксели байт в байт те же, что у источника, изменены только имена
некоторых стейтов (чтобы развести одноимённые картинки разных доноров в одном файле).

Историческое ядро `icons/effects/parallax.dmi` лежит рядом, а не здесь: это
собственный арт BlueMoon, и перенос переписал бы его бинарник целиком без всякой
пользы.

## Что НЕ импортировано, потому что оказалось нашим же файлом

Сверка шла попиксельно, а не по именам стейтов. Совпало больше, чем различалось:

| донор | стейты | результат сверки |
| --- | --- | --- |
| tgstation `icons/effects/parallax.dmi` | все 7 | побайтово идентичны нашим - донором не является |
| Paradise | `layer1`, `layer2`, `layer3` | побайтово наши |
| Paradise | `asteroids`, `space_gas` | отличия есть, но ВСЕ под `alpha = 0` - видимых различий ноль |
| BeeStation | `layer1..3` | побайтово наши |
| BeeStation | `random_layer1`, `random_layer2` | побайтово наши `space_gas` и `asteroids`, просто переименованы |
| Shiptest | `asteroids`, `icemoon` | побайтово наши |
| Shiptest | `layer3` | отличается на 329 пикселей (0.14%) - не стоит отдельного ассета |
| Polaris `space1..space6` | 6 стейтов | побайтово совпадают с CEV-Eris, взята одна копия |
| Polaris / Aurora / Foundation-19 | `dyable`, `narsie`, `cascade` | один и тот же файл у всех трёх (общий предок Baystation), взята копия Polaris |
| Polaris `planet_rings.dmi` | `sparse`, `dense` | то же изображение, что у Aurora, но вчетверо тяжелее - взята версия Aurora |

## Импортированные файлы

### `space.dmi` - 480x480, 885 КБ

| стейт | источник | путь у донора | коммит | лицензия | переименован |
| --- | --- | --- | --- | --- | --- |
| `layenia1` | Shiptest | `icons/effects/parallax.dmi` | `d87a20818730` | AGPL-3.0 / CC BY-SA 3.0 | нет |
| `layenia2` | Shiptest | там же | `d87a20818730` | AGPL-3.0 / CC BY-SA 3.0 | нет |
| `layenia3` | Shiptest | там же | `d87a20818730` | AGPL-3.0 / CC BY-SA 3.0 | нет |
| `layeniahorizon` | Shiptest | там же | `d87a20818730` | AGPL-3.0 / CC BY-SA 3.0 | нет |
| `whitesands` | Shiptest | там же | `d87a20818730` | AGPL-3.0 / CC BY-SA 3.0 | нет |
| `shiptest_layer1` | Shiptest | там же, `layer1` | `d87a20818730` | AGPL-3.0 / CC BY-SA 3.0 | да, из `layer1` |
| `shiptest_layer2` | Shiptest | там же, `layer2` | `d87a20818730` | AGPL-3.0 / CC BY-SA 3.0 | да, из `layer2` |
| `shiptest_layer3` | Shiptest | там же, `layer3` | `d87a20818730` | AGPL-3.0 / CC BY-SA 3.0 | да, из `layer3` |
| `tauceti_layer1` | TauCetiClassic | `icons/effects/parallax.dmi`, `layer1` | `b4b5a2e24005` | AGPL-3.0 / CC BY-SA 3.0 | да |
| `tauceti_layer2` | TauCetiClassic | там же, `layer2` | `b4b5a2e24005` | AGPL-3.0 / CC BY-SA 3.0 | да |
| `tauceti_layer3` | TauCetiClassic | там же, `layer3` | `b4b5a2e24005` | AGPL-3.0 / CC BY-SA 3.0 | да |
| `planet_lava` | Paradise | `icons/effects/parallax.dmi` | `3add7ad52a2d` | AGPL-3.0 / CC BY-SA 3.0 | нет |
| `planet_plasma` | Paradise | там же | `3add7ad52a2d` | AGPL-3.0 / CC BY-SA 3.0 | нет |
| `planet_chasm` | Paradise | там же | `3add7ad52a2d` | AGPL-3.0 / CC BY-SA 3.0 | нет |
| `planet_animated` | BeeStation-Hornet | `icons/effects/parallax.dmi`, `planet` | `e0863ec072d2` | AGPL-3.0 / CC BY-SA 3.0 | да |

### `skyboxes.dmi` - 736x736, 2.5 МБ

| стейт | источник | путь у донора | коммит | лицензия | переименован |
| --- | --- | --- | --- | --- | --- |
| `space0` | CEV-Eris | `icons/parallax.dmi` | `5f7847f26585` | см. раздел о CEV-Eris | нет |
| `space1`..`space6` | Polaris | `icons/skybox/skybox.dmi` | `6cd19fe0dec6` | AGPL-3.0 / CC BY-SA 3.0 | нет |
| `dyable` | Polaris | там же | `6cd19fe0dec6` | AGPL-3.0 / CC BY-SA 3.0 | нет |
| `stars` | Polaris | там же | `6cd19fe0dec6` | AGPL-3.0 / CC BY-SA 3.0 | нет |
| `diagnostic` | Polaris | там же | `6cd19fe0dec6` | AGPL-3.0 / CC BY-SA 3.0 | нет |
| `nebula` | CEV-Eris | `icons/parallax.dmi` | `5f7847f26585` | см. раздел о CEV-Eris | нет |
| `void` | Aurora | `icons/skybox/skybox.dmi` | `d67d2c791285` | AGPL-3.0 / CC BY-SA 3.0 | нет |
| `arusha` | Aurora | там же | `d67d2c791285` | AGPL-3.0 / CC BY-SA 3.0 | нет |
| `badlands` | Aurora | там же | `d67d2c791285` | AGPL-3.0 / CC BY-SA 3.0 | нет |
| `puddle_worlds` | Aurora | там же | `d67d2c791285` | AGPL-3.0 / CC BY-SA 3.0 | нет |
| `sparring_sea` | Aurora | там же | `d67d2c791285` | AGPL-3.0 / CC BY-SA 3.0 | нет |
| `crescent_expanse` | Aurora | там же | `d67d2c791285` | AGPL-3.0 / CC BY-SA 3.0 | нет |

### `weather.dmi` - 736x736, 1.3 МБ

Все стейты - CEV-Eris, `icons/parallax.dmi`, коммит `5f7847f26585`, без переименований:
`bluespace_storm_background`, `bluespace_storm_far`, `bluespace_storm_close`,
`micro_debris_far`, `micro_debris_close`, `photon_vortex`,
`graveyard_background`, `graveyard_far`, `graveyard_close`,
`ion_blizzard_background`, `ion_blizzard_far`, `bluespace_interphase`.

### `planets.dmi` - 256x256, 109 КБ

Обесцвеченные маски: цвет подставляется в рантайме, поэтому семнадцать стейтов
дают неограниченное число непохожих планет.

| стейт | источник | путь у донора | коммит | лицензия |
| --- | --- | --- | --- | --- |
| `base1..3`, `water1..3`, `clouds1..3`, `shadow1..3` | Aurora | `icons/skybox/planet.dmi` | `d67d2c791285` | AGPL-3.0 / CC BY-SA 3.0 |
| `atmoring`, `lightrim`, `mountains`, `weak_clouds`, `icecaps` | Polaris | `icons/skybox/planet.dmi` | `6cd19fe0dec6` | AGPL-3.0 / CC BY-SA 3.0 |

### `planet_rings.dmi` - 512x512, 21 КБ

`sparse`, `dense` - Aurora, `icons/skybox/planet_rings.dmi`, коммит `d67d2c791285`.

### `legacy_tg.dmi` - 480x480, 94 КБ

Копия `tgstation/icons/effects/old_parallax.dmi`, коммит `5f093a8cfbbe`, целиком и
без изменений. Пятнадцать стейтов по четыре кадра; delay каждого стейта равен его
имени, отчего мерцание никогда не синхронизируется.

### `goon/weather.dmi` - 672x672, 866 КБ

**Отдельный каталог и отдельная лицензия.** См. `goon/LICENSE.md`.

## О CEV-Eris

`CEV-Eris/LICENSE` объявляет код под GNU AGPL v3, но отдельного файла с лицензией
на арт в репозитории нет, и явного заявления о CC BY-SA для `icons/parallax.dmi` мы
не нашли. Поэтому здесь оно и не утверждается: стейты помечены происхождением, а не
конкретной лицензией на изображение. Источник - `CEV-Eris`, `icons/parallax.dmi`,
коммит `5f7847f26585`.

## О коде

Импортированы только изображения. Ни строки чужого кода в эту ветку не перенесено.

Идеи, воспроизведённые самостоятельно:

- **goonstation** - прозрачность из яркости цветовой матрицей, группы источников по
  z и по area, динамическое добавление и снятие источников. Реализовано с нуля
  (`luminance_alpha` у слоя, стек модификаторов в SSparallax).
- **Foundation-19** - запас скайбокса за краем вьюпорта тратится на параллаксный
  сдвиг, поэтому край не может выехать в кадр.
- **Aurora, Polaris** - сборка планеты из обесцвеченных масок с покраской в рантайме.
- **CEV-Eris** - разложение погодного явления на ярусы глубины.
