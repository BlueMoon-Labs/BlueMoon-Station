/// Context applied to LMB actions
#define SCREENTIP_CONTEXT_LMB "LMB"

/// Context applied to RMB actions
#define SCREENTIP_CONTEXT_RMB "RMB"

/// Context applied to Shift-LMB actions
#define SCREENTIP_CONTEXT_SHIFT_LMB "Shift-LMB"

/// Context applied to Ctrl-LMB actions
#define SCREENTIP_CONTEXT_CTRL_LMB "Ctrl-LMB"

/// Context applied to Ctrl-RMB actions
#define SCREENTIP_CONTEXT_CTRL_RMB "Ctrl-RMB"

/// Context applied to Alt-LMB actions
#define SCREENTIP_CONTEXT_ALT_LMB "Alt-LMB"

/// Context applied to Alt-RMB actions
#define SCREENTIP_CONTEXT_ALT_RMB "Alt-RMB"

/// Context applied to Ctrl-Shift-LMB actions
#define SCREENTIP_CONTEXT_CTRL_SHIFT_LMB "Ctrl-Shift-LMB"

/// Screentips are always disabled
#define SCREENTIP_PREFERENCE_DISABLED "Disabled"

/// Screentips are always enabled
#define SCREENTIP_PREFERENCE_ENABLED "Enabled"

/// Screentips are only enabled when they have context
#define SCREENTIP_PREFERENCE_CONTEXT_ONLY "Only with tips"

/// Screentips enabled, no context
#define SCREENTIP_PREFERENCE_NO_CONTEXT "Enabled without tips"

/**
 * Габариты коробки скринтипа. НЕ КОСМЕТИКА: это прайс-лист памяти клиента.
 *
 * Растеризованный maptext занимает у клиента поверхность maptext_width * maptext_height * 4
 * байта на КАЖДУЮ уникальную строку, и платится ОБЪЯВЛЕННЫЙ размер коробки, а не занятый
 * текстом. Строки скринтипа уникальны и личные: в них входит имя атома, вспомогательное имя,
 * до четырёх строк контекста и цвет из префов игрока, а меняются они по 2-4 раза в секунду -
 * ровно с тем темпом, с каким игрок водит мышью по объектам с разными именами.
 *
 * ШИРИНА. Раньше коробка равнялась ширине вьюпорта (update_view), то есть 480 px на обычном
 * экране и до 736 на широком, а текст центровался внутри неё через text-align. Потолок
 * возвращает широкий экран к цене обычного: коробка центруется сама, через maptext_x, и текст
 * внутри неё центруется ровно как прежде. На вьюпорте 480 и уже не меняется НИЧЕГО.
 *
 * ВЫСОТА. Фиксированные 128 брались по худшему случаю - четыре строки контекста плюс подъём
 * блока через maptext_y (16 px на строку и до -42 px смещения с картинками). У подавляющего
 * большинства атомов контекстных строк нет вовсе, и им хватает одной строки имени. Высота
 * теперь считается по числу этих строк, и обычное наведение стоит вчетверо дешевле.
 */
#define SCREENTIP_BOX_MAX_WIDTH 480
/// Высота коробки без контекстных строк: строка имени плюс maptext_y = 10.
#define SCREENTIP_BOX_HEIGHT_BASE 32
/// Прибавка на каждую контекстную строку: сама строка (16 px) плюс её подъём (12 px).
#define SCREENTIP_BOX_HEIGHT_PER_LINE 28
/// Потолок высоты - прежние 128, худший случай из четырёх контекстных строк.
#define SCREENTIP_BOX_MAX_HEIGHT 128

/// Regardless of intent
#define INTENT_ANY "any"

GLOBAL_LIST_INIT(screentip_pref_options, list(
	SCREENTIP_PREFERENCE_DISABLED,
	SCREENTIP_PREFERENCE_ENABLED,
	SCREENTIP_PREFERENCE_CONTEXT_ONLY,
	SCREENTIP_PREFERENCE_NO_CONTEXT
))
