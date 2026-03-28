/**
 * # AI Donator Screens
 *
 * Этот файл содержит донаторские экраны для ИИ.
 *
 * Как добавить новый донаторский экран:
 *
 * 1. Добавьте спрайты в `icons/mob/AI_donator.dmi`:
 *    - `ai-<name>`      — живой стейт
 *    - `ai-<name>_dead` — мёртвый стейт
 *
 * 2. Создайте новый подтип датума:
 *
 *    /datum/ai_donator_screen/<name>
 *        name = "DisplayName"          // Название в радиальном меню
 *        icon_state = "ai-<name>"      // Стейт живого ИИ
 *        icon_state_dead = "ai-<name>_dead" // Стейт мёртвого ИИ
 *        ckey_whitelist = list("ckey") // Список ckey игроков с доступом
 *
 * 3. Добавьте new /datum/ai_donator_screen/<name> в GLOBAL_LIST_INIT_TYPED ниже.
 *
 * Примечания:
 *    - ckey всегда в нижнем регистре (как в базе данных)
 *    - icon_state_dead можно не указывать, тогда при смерти ИИ
 *      будет использоваться стандартный мёртвый стейт из AI.dmi
 *    - Один экран может быть доступен нескольким игрокам:
 *      ckey_whitelist = list("ckey1", "ckey2")
 */

/datum/ai_donator_screen
    var/name = ""
    var/icon = 'icons/mob/AI_donator.dmi'
    var/icon_state = ""
    var/icon_state_dead = ""
    var/list/ckey_whitelist = list()

/datum/ai_donator_screen/star
    name = "Star"
    icon_state = "ai-star"
    icon_state_dead = "ai-star_dead"
    ckey_whitelist = list("pe4henika")


GLOBAL_LIST_INIT_TYPED(ai_donator_screens, /datum/ai_donator_screen, list(
    new /datum/ai_donator_screen/star
))
