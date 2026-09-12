# Стекло и Кровь

Ниже описано исходное сведение: Ogg Vorbis, 44.1 кГц, stereo, качество 5. Короткие эффекты имеют мягкое затухание; обе композиции вознесения длятся 16 секунд и затихают в последние три секунды. Пиковый лимитер ограничен уровнем 0.85. После сведения `glass_grasp` усилен вдвое, `ascend_glass` — в 1.7 раза, чтобы стеклянные голоса не терялись за окружением. Последующее сведение позиционных эффектов в моно, сокращение окончаний и выравнивание уровня описаны в [SOUND_STYLE.md](SOUND_STYLE.md). Исходные ресурсы не изменялись.

| Файл | Исходники и обработка |
| --- | --- |
| `glass_grasp.ogg` | tgstation `sound/effects/glass/glass_reverse.ogg`, громкость 0.8, затухание. |
| `glass_page.ogg` | BlueMoon `sound/effects/Glassknock.ogg`, низкочастотный фильтр 5.5 кГц, громкость 0.55. |
| `glass_release.ogg` | BlueMoon `Glassbr1.ogg` и `Glasshit.ogg`, громкости 0.8/0.35, второй слой задержан на 0.07 с и имеет короткое эхо. |
| `glass_storm.ogg` | `glass_reverse.ogg`, BlueMoon `Glassbr3.ogg` и `Glassbr2.ogg`, громкости 0.45/0.75/0.38, задержки 0/0.65/1.15 с; последний слой понижен на 10% и дополнен эхом. |
| `blood_grasp.ogg` | BlueMoon `sound/magic/enter_blood.ogg`, громкость 0.9. |
| `blood_page.ogg` | BlueMoon `sound/effects/wounds/blood2.ogg`, фильтр 4.5 кГц, громкость 0.7. |
| `blood_release.ogg` | BlueMoon `sound/magic/exit_blood.ogg` и `sound/effects/wounds/blood3.ogg`, громкости 0.75/0.45, второй слой задержан на 0.12 с. |
| `blood_reckoning.ogg` | `exit_blood.ogg` понижен на 20%; первые три секунды `sound/hallucinations/psychosis/heartbeat_corrupted.ogg`, фильтр 3.2 кГц; `blood3.ogg`. Громкости 0.7/0.45/0.7, задержки 0.25/0/1.1 с. |
| `ascend_glass.ogg` | Новая партия поющего стекла: десять синусоидальных голосов с негармоническим обертоном 2.76, медленным вступлением и затуханием. Ноты D3/A3/E♭4/A4/D5/E♭5/A5/D6/A♭5/D5, разнесённые по стереополю. Дополнены `glass_reverse.ogg`, `Glassbr3.ogg` и BlueMoon `sound/hallucinations/psychosis/cathedral_voice.ogg`, громкости 0.65/0.65/0.33, задержки 0.35/1.1/3.2 с. |
| `ascend_blood.ogg` | BlueMoon `sound/hallucinations/psychosis/buildup_coven.ogg`, `heartbeat_corrupted.ogg`, `cathedral_voice.ogg` и `sound/magic/exit_blood.ogg`. Громкости 0.72/0.52/0.42/0.7, задержки 0/0.3/3.3/7.5 с; пульс повторён один раз, голос понижен на 10%, завершающий слой имеет эхо. |

`glass_reverse.ogg` взят из [tgstation, ревизия 5f093a8](https://github.com/tgstation/tgstation/blob/5f093a8cfbbe269b15bc73535f230909218e38d6/sound/effects/glass/glass_reverse.ogg). Согласно [атрибуции источника](https://github.com/tgstation/tgstation/blob/5f093a8cfbbe269b15bc73535f230909218e38d6/sound/attributions.txt), он объединяет [glass-shattering-hit_01.ogg — C_Rogers](https://freesound.org/people/C_Rogers/sounds/203368/) (CC0) и развёрнутый с затуханием [Shattering Glass (Small) — Czarcazas](https://freesound.org/people/Czarcazas/sounds/330800/) ([CC BY 3.0](https://creativecommons.org/licenses/by/3.0/)). Авторство исходников сохранено для трёх производных композиций.

Остальные слои уже входят в ресурсы BlueMoon. Новая партия стекла и обработка распространяются на условиях [CC BY-SA 3.0](https://creativecommons.org/licenses/by-sa/3.0/), как ресурсы проекта. Иллюстрации книг и игровые спрайты описаны отдельно в каталоге иконок.
