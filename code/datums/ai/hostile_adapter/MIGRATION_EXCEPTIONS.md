# Постоянные исключения hostile AI

Каждый `/mob/living/simple_animal/hostile` получает адаптер-контроллер через
базовый профиль или явное назначение из `profile_assignments.dm`. Значение
`ai_profile_type = null` допустимо только для `AI_OFF`-оболочек без собственного
NPC-AI; полный список таких типов находится в `permanent_exceptions.dm`.

| Тип | Почему контроллер не нужен | Проверка |
|---|---|---|
| Player swarmer | Гост-роль с `AIStatus = AI_OFF`; NPC-подтипы `/swarmer/ai` используют специализированные профили | `ai_swarmer_forage_cycle`, `ai_swarmer_combat_subtypes` проверяют NPC-ветку |
| Eldritch demons | Гост-вессели с `AIStatus = AI_OFF`; сегменты armsy двигаются сигналами головы | `ai_eldritch_stays_player_vessel` |
| Guardians | Игровые духи с `AIStatus = AI_OFF`, создаваемые для владельца | `ai_guardian_stays_player_shell` |
| Herald mirror | Марионетка хозяина с `AIStatus = AI_OFF`; атаки вызываются боссовыми обёртками хозяина | `ai_herald_mirror_stays_marionette` |

Новое исключение должно одновременно получить `ai_profile_type = null`,
обоснование здесь и регрессионную проверку. Обычные и специализированные
hostile-мобы в этот список добавляться не должны.
