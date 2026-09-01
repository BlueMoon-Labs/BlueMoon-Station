#define PARALLAX_DELAY_DEFAULT world.tick_lag
#define PARALLAX_DELAY_MED     1
#define PARALLAX_DELAY_LOW     2

// WARNING - client.prefs uses this, if you change these make sure to update the code in preferences!
#define PARALLAX_DISABLE 0
#define PARALLAX_LOW     1
#define PARALLAX_MED     2
#define PARALLAX_HIGH    3
#define PARALLAX_INSANE  4  // default

// keep this false until we can fix it being a seizure hazard/ugly as sin
#define PARALLAX_ROTATION_ANIMATIONS FALSE

/**
 * Режимы слоя параллакса.
 *
 * TILED - историческая механика: картинка размножается сеткой [tile_size] и
 *   бесконечно проматывается, смещение заворачивается в +-[tile_size]/2.
 *   Единственный режим, который идёт по относительному (накопительному) пути в
 *   RelativePosition, и единственный, который участвует в анимации прокрутки.
 * SKYBOX - крупный нетайлящийся фон. Позиция считается от абсолютных координат,
 *   но зажимается в "bleed" - запас картинки поверх вьюпорта, - поэтому край
 *   изображения не выезжает в кадр ни при каком client.view.
 * STATIC - крупный неподвижный объект (планета, кольца, обломок). Абсолютная
 *   позиция без тайлинга и без зажима: объект имеет право уехать за край.
 * OVERLAY - экранная тонировка. Растянута по вьюпорту своим screen_loc и НИКОГДА
 *   не перепозиционируется: событию нужен ровный цветной фильтр поверх плана
 *   параллакса, а не изображение, которое куда-то едет.
 */
#define PARALLAX_MODE_TILED  1
#define PARALLAX_MODE_SKYBOX 2
#define PARALLAX_MODE_STATIC 3
#define PARALLAX_MODE_OVERLAY 4

/// Исторический размер тайла слоя параллакса. 15x15 тайлов по 32 пикселя.
#define PARALLAX_DEFAULT_TILE_SIZE 480

/// Скорость прокрутки сцены под летящим шаттлом: децисекунды на один проход тайла
/// у слоя со speed = 1. Историческое значение - столько же стояло на шаттле.
#define PARALLAX_SHUTTLE_SCROLL_SPEED 25

/**
 * Флаги окружения профиля - где профиль вообще уместен.
 * Автоподбор профиля по z сверяет их с трейтами z-уровня.
 */
#define PARALLAX_ENV_STATION (1<<0)
#define PARALLAX_ENV_SPACE_RUINS (1<<1)
#define PARALLAX_ENV_PLANET (1<<2)
#define PARALLAX_ENV_SHUTTLE (1<<3)
#define PARALLAX_ENV_CENTCOM (1<<4)

/// Потолок числа ДВИЖУЩИХСЯ (tiled) слоёв в разрешённом профиле.
/// RelativePosition выполняется на каждый шаг игрока по одному разу на слой и
/// является самым горячим проком рендера - профиль сверх этого числа отвергает
/// юнит-тест parallax_profile_catalog.
#define PARALLAX_MAX_MOVING_LAYERS 5

/// Токен модификатора, под которым админский инструмент подменяет профиль.
#define PARALLAX_TOKEN_ADMIN "admin"

/**
 * Приоритеты в стеке модификаторов. Больший применяется позже и перебивает меньший.
 * Админ обязан видеть то, что поставил, поверх любого события.
 */
#define PARALLAX_PRIORITY_WEATHER 10
#define PARALLAX_PRIORITY_EVENT 20
/// Сцены антагонистов. Выше пиковых слоёв космической погоды (EVENT + 1): культ,
/// сожравший треть экипажа, важнее ионной бури и обязан быть виден сквозь неё.
#define PARALLAX_PRIORITY_ANTAG 40
#define PARALLAX_PRIORITY_ADMIN 100
