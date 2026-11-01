//------------------------------SETUP------------------------------//

//Простые постоянные, которые подсказывают механу, кто сейчас находится
// в теле хоста. От их значения обычно зависит то, что будет делать абилка takeControl

#define islatexmob(A) (istype(A, /mob/living/simple_animal/latexmob)) //Простая проверка на latexmob
#define isbackseatmob(A) (istype(A, /mob/living/simple_animal/latexmob/venom)) //аналогично для venom
#define checkplayerssd(M) (!M.client && M.mind) //Майнд есть, а клиента нет. Типичный признак ливнувшего игрока.

/**
 * Макрос для проверки дистанции
 * Если до цели один шаг или меньше, то TRUE
 * Если больше, то FALSE
 */
#define check_one_meter_distance_to_mob(M, U) \
    if (get_dist(M, U) > 1) {\
        TOO_FAR_ERROR(U); \
        return FALSE; \
    }

/**
 * Проверка human на факт наличия космического костюма
 * Если и сам костюм И шлем надены на хумана, то выдает FALSE
 * Если хотя бы одно из этих FALSE то итог TRUE
 * ВАЖНО: НЕ использовать внутри if
 */
#define check_space_suit(M, U) \
    if(istype(M.wear_suit, /obj/item/clothing/suit/space) && istype(M.head, /obj/item/clothing/head/helmet/space)) { \
        SPACE_SUIT_ERROR(U); \
        return FALSE; \
    }

#define DEFAULT_LL_OVERLAY_ICON 'modular_bluemoon/horny_venom/icons/full_sprite_overlay.dmi'
#define DEFAULT_LL_OVERLAY_ICON_STATE "overlay"


#define BODY_OWNER "OWNER" //Если тело находится под контролем изначального владельца
#define VENOM_USER "VENOM" //Если телом сейчас управляет игрок на латексном паразите
#define IN 			"in"   //Применяется при трансфере BACKSEAT <--> BODY
#define OUT 		"out"  //Применяется при трансфере BODY <--> BACKSEAT

//-----Скорости слияния с хостом-----
#define DEFAULT_MERGING_DELAY 10 SECONDS	//Начальная стадия
#define MEDIUM_MERGING_DELAY   8 SECONDS	//Последующие стадии
#define BEST_MERGING_DELAY     5 SECONDS	//Самая последняя стадия, наименьшая задержка
#define DEBUG_MERGING_DELAY    1 SECONDS    //Только для разработки

//TGUI ALERTS сообщения, выводимые в виде окна игроку. Носят важный характер.
// Сюда выносятся только важные сообщения.
#define LOGIN_WARNING_MESSAGE(user) (tgui_alert(user, "Не совершайте самоубиство и не ставьте чужое тело в неловкое положение. Так же вам крайне не следует делать сомнительные, или откровенные(ЕРП) действия, без явного одобрения со стороны хозяина тела(Noncon = Yes считается за явное одобрение, в противном случае ОБЯЗАТЕЛЬНО спрашивайте в LOOC).", "Предупреждение", list("Я осознаю это")))
#define MERGING_SSD_ERROR(user) (tgui_alert(user, "Вы не можете пытаться поглотить/взять контроль SSD игроков", "ОШИБКА", list("Хорошо")))
#define ABILITY_IS_UPDATED(user, ability) (tgui_alert(user, "Способность [ability] была успешно улучшена!", "Уведомление", list("Ок")))
#define MOB_IS_ALIVE_ERROR(user) (tgui_alert(user, "Вы не можете поглощать живых симплмобов до второй стадии! Улучшите вашу способность на втрой тир, прежде чем поглощать живых", "ОШИБКА", list("Хорошо")))

//-----Разнообразные сообщения, используемые в to_chat-----
#define DEFAULT_ABILITY_ERROR_MESSAGE(user)  to_chat(user, span_warning("Вы не можете использовать эту способность из текущего состояния!"))
#define LEAK_OUT_ERROR_MESSAGE(user)         to_chat(user, span_warning("Ваше тело недостаточно гибкое для использования этой способности. Попробуйте сменить форму тела на слайма"))
#define SLOW_DOWN_ANTISPAM_MESSAGE(user)     to_chat(user, span_danger("В данный момент вы уже пытаетесь поглотить кого-то"))
#define NO_AIRLOCK_NEABY(user)               to_chat(user, span_warning("Шлюзы по-близости не найдены"))
#define TOO_FAR_ERROR(user)                  to_chat(user, span_warning("Вы слишком далеко"))
#define SPACE_SUIT_ERROR(user)               to_chat(user, span_warning("Цель одета в скафандр, некуда пролезть!"))
#define HANDLE_MERGING_TO_HOST_MESSAGE(user) to_chat(user, span_boldwarning("Что-то склизкое и темное обхватывает вас с ног, начиная ползти вверх по вашему телу, пробирай до дрожи!"))
//-----Постоянные для "заднего сидения". Это промежуточное место, куда попадает игрок на паразите/владельце тела при смене "рулящего" телом-----
#define LOGIN_NOTICE_MESSAGE(user)  to_chat(user, span_notice("Вы находитесь на так называемом заднем сидении данного тела. Вы можете говорить как и привыкли, но ваши слова услышит лишь владелец тела. В данном состоянии вы можете только наблюдать."))

//-----Скорости регенерации очков эволюции-----
#define POINTS_REGEN_DEBUG    0.5
#define POINTS_REGEN_NORMAL   0.001
#define POINTS_REGEN_HOSTLESS 0.0005

#define LATEX_MAX_STAGE 3
#define LATEX_MAX_POINTS 1
#define LATEX_CONTACT_DURATION (1 MINUTES)
#define LATEX_STAIN_HANDS 1
#define LATEX_STAIN_ARMS 2
#define LATEX_STAIN_CHEST 3
#define LATEX_STAIN_MAX_STAGE LATEX_STAIN_CHEST
#define LATEX_STAIN_REMOVE_CHANCE 20
#define LATEX_STAIN_REMOVE_COOLDOWN (3 SECONDS)
#define LATEX_STAIN_SCALE 0.35
#define LATEX_STAIN_CHEST_SCALE 0.5
#define LATEX_STAIN_HAND_OFFSET 8
#define LATEX_STAIN_HAND_HEIGHT 3
#define LATEX_STAIN_CHEST_HEIGHT 10
#define LATEX_CAPTURE_ROUND (6 SECONDS)
#define LATEX_QTE_PERIOD (2 SECONDS)
#define LATEX_QTE_WIDTH 0.24
#define LATEX_QTE_MARGIN 0.1
#define LATEX_ABSORB_DELAY (5 SECONDS)
#define LATEX_ABSORB_HEALTH_FACTOR 0.001
#define LATEX_ABSORB_DECAY 0.1
#define LATEX_INJECT_AMOUNT 5
#define LATEX_INJECT_COST 0.1
#define LATEX_INJECT_COOLDOWN (5 SECONDS)
#define LATEX_COLOR "#17171c"
#define LATEX_EFFECT_INDEX 3
#define LATEX_FORM_DAMAGE 5
#define LATEX_FORM_DAMAGE_STEP 1.25
#define LATEX_FORM_DAMAGE_SPREAD 2
#define LATEX_LEAK_DELAY (1.5 SECONDS)
#define LATEX_MIMIC_MAX_SIZE (world.icon_size * 2)

#define LATEX_QTE_STEPS 100
