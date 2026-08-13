/**
 * Каталог собранных спрайтшитов (png/css) и их кросс-раундового кэша.
 *
 * Мир с UNIT_TESTS собирает не тот же набор спрайтов, что боевой (см.
 * assets/vending.dm - под тестами предметы с отсутствующим icon_state
 * пропускаются), поэтому листы у них разные побайтово. Пиши оба в один каталог -
 * и прогон dm-test поверх живого сервера перезапишет png/css прямо под ним:
 * раунд начнёт отдавать новое содержимое под старыми, уже посчитанными именами,
 * а css уедет ссылаться на png, которого под этим именем никто не отправлял.
 */
#ifdef UNIT_TESTS
#define SPRITESHEET_CACHE_DIR "data/spritesheets_unit_tests/"
#else
#define SPRITESHEET_CACHE_DIR "data/spritesheets/"
#endif

/**
 * Собирает [/datum/universal_icon] - описание иконки, а не саму иконку.
 * Аргументы те же, что у BYOND-овского icon(): icon_file, icon_state, dir, frame,
 * transform, color.
 *
 * "color" игнорируется, если передан свой transform - домешивай цвет сам или
 * заведи трансформер через color_transform().
 * Трансформеры НЕ копируются при передаче, внутри это список - не переиспользуй
 * один и тот же transform на нескольких иконках.
 *
 * Дефайн, а не прок, ради скорости: этих вызовов десятки тысяч за старт.
 */
#define uni_icon(I, icon_state, rest...) new /datum/universal_icon(I, icon_state, ##rest)
