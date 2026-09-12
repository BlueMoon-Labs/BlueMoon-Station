# Звуки еретиков

Источник — [tgstation/tgstation](https://github.com/tgstation/tgstation), снимок `5f093a8cfbbe269b15bc73535f230909218e38d6`. Лицензия ассетов — [Creative Commons Attribution-ShareAlike 3.0 Unported](https://creativecommons.org/licenses/by-sa/3.0/), согласно [README источника](https://github.com/tgstation/tgstation/blob/5f093a8cfbbe269b15bc73535f230909218e38d6/README.md#license). Авторы и история правок указаны в ссылках на исходные файлы. Последующая обработка и новые производные звуки описаны в [SOUND_STYLE.md](SOUND_STYLE.md); `void_deflect1/2/3.ogg` сохранены без изменений.

| Файлы | Источник и история |
| --- | --- |
| `cosmic_energy.ogg` | [sound/effects/magic/cosmic_energy.ogg](https://github.com/tgstation/tgstation/commits/5f093a8cfbbe269b15bc73535f230909218e38d6/sound/effects/magic/cosmic_energy.ogg) |
| `cosmic_expansion.ogg` | [sound/effects/magic/cosmic_expansion.ogg](https://github.com/tgstation/tgstation/commits/5f093a8cfbbe269b15bc73535f230909218e38d6/sound/effects/magic/cosmic_expansion.ogg) |
| `void_deflect1.ogg`, `void_deflect2.ogg`, `void_deflect3.ogg` | [sound/effects/magic/void_deflect1.ogg](https://github.com/tgstation/tgstation/commits/5f093a8cfbbe269b15bc73535f230909218e38d6/sound/effects/magic/void_deflect1.ogg), [void_deflect2.ogg](https://github.com/tgstation/tgstation/commits/5f093a8cfbbe269b15bc73535f230909218e38d6/sound/effects/magic/void_deflect2.ogg), [void_deflect3.ogg](https://github.com/tgstation/tgstation/commits/5f093a8cfbbe269b15bc73535f230909218e38d6/sound/effects/magic/void_deflect3.ogg) |
| `parry.ogg` | [sound/items/weapons/parry.ogg](https://github.com/tgstation/tgstation/commits/5f093a8cfbbe269b15bc73535f230909218e38d6/sound/items/weapons/parry.ogg) |

## Замок и Пучина

`lock_knock.ogg` основан на tgstation `sound/effects/magic/hereticknock.ogg`, `ascend_lock.ogg` — на `sound/music/antag/heretic/ascend_knock.ogg`, снимок `5f093a8cfbbe269b15bc73535f230909218e38d6`. Лицензия CC BY-SA 3.0; [история стука](https://github.com/tgstation/tgstation/commits/5f093a8cfbbe269b15bc73535f230909218e38d6/sound/effects/magic/hereticknock.ogg), [история вознесения](https://github.com/tgstation/tgstation/commits/5f093a8cfbbe269b15bc73535f230909218e38d6/sound/music/antag/heretic/ascend_knock.ogg), [лицензия источника](https://github.com/tgstation/tgstation/blob/5f093a8cfbbe269b15bc73535f230909218e38d6/README.md#license).

Звуки Пучины используют существующие ресурсы BlueMoon:

| Файл | Источник |
| --- | --- |
| `tide_grasp.ogg` | `sound/effects/bubbles.ogg`; сведение в моно и коррекция уровня. |
| `tide_release.ogg` | `sound/effects/watersplash.ogg`, без изменений. |
| `tide_bell.ogg` | `sound/hallucinations/psychosis/bell_creepy.ogg`; первые 3.2 с, затухание последних 0.65 с, коррекция уровня. |
| `tide_deluge.ogg` | `sound/effects/splash.ogg`; первые 1.25 с, затухание последних 0.15 с, коррекция уровня. |
| `ascend_tide.ogg` | 18-секундная композиция из `sound/hallucinations/psychosis/undercurrent_dark.ogg`, `whalesong_monotron.ogg`, `foghorn_distant.ogg`, `bell_creepy.ogg` и `sound/effects/watersplash.ogg`. |

В исходном сведении композиции громкости слоёв равны 0.7, 0.42, 0.38, 0.62 и 0.36; задержки — 0, 1.5, 5, 0.35 и 0.35 секунды. Начальный fade-in 0.2 секунды, fade-out с 15-й по 18-ю секунду; пиковый лимитер 0.89. Затем общий уровень понижен на 2.74 dB. Ogg Vorbis, stereo 44.1 кГц, качество 5. Оригинальные файлы не изменялись.
