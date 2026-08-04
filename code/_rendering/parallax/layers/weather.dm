/**
 * Космическая погода.
 *
 * Два донора с разной геометрией: CEV-Eris рисует 736x736, goonstation - 672x672.
 * Общего множителя с нашим историческим тайлом 480 у них нет, поэтому период
 * заворота хранится у слоя, а не в константе.
 *
 * Тайлящийся слой обязан смыкаться сам с собой, а донорский арт этого не обещал.
 * Слои, чей шов оказался резче самых резких переходов внутри их же картинки,
 * разошлись по двум путям: у кого разрыв шёл по всей кромке (`*_background`,
 * `bluespace_storm_far`, `graveyard_far`) - переведены в скайбокс, он не
 * замощается; у кого разрыв был чинимым (`ion_blizzard_far`,
 * `bluespace_storm_close`, `graveyard_close`, `dust_dense`, `embers_dense`) -
 * пересобран сам DMI. Замеры и метод - в icons/effects/parallax/ATTRIBUTION.md.
 */

// ---------------------------------------------------------------------------
// CEV-Eris: комплекты по три яруса глубины
// ---------------------------------------------------------------------------

/**
 * У Eris параллакса как такового нет: у них один экранный объект с одним
 * icon_state, событие подменяет строку - и всё. Разложенные художником ярусы
 * `_background` / `_far` / `_close` в их коде не используются ни разу.
 *
 * Мы берём именно ярусы: расставленные по скорости, они дают ту глубину, ради
 * которой параллакс и существует. Заодно это в 1.8 МБ дешевле, чем их же
 * "сплющенные" одиночные картинки.
 */
/atom/movable/screen/parallax_layer/eris
	icon = 'icons/effects/parallax/weather.dmi'
	tile_size = 736

/**
 * Дальний ярус идёт СКАЙБОКСОМ, а не тайлом. Замер шва (по премультиплицированным
 * на альфу краям, то есть по тому, что реально рисуется) дал у `graveyard_background`
 * 19.9, у `ion_blizzard_background` 30.9 - замощённые сеткой, они показывали бы
 * прямоугольную решётку прямо посреди экрана.
 *
 * Запас увеличен до 160: скайбокс тут двигается, а не стоит, и при обычном тайле
 * 736 на view 15x15 запаса 128 хватило бы всего на 1000 тайлов хода.
 */
/atom/movable/screen/parallax_layer/eris/background
	layer_mode = PARALLAX_MODE_SKYBOX
	min_bleed = 160
	speed = 0.12
	layer = 0.5
	parallax_intensity = PARALLAX_LOW

/atom/movable/screen/parallax_layer/eris/far
	speed = 1
	layer = 2
	parallax_intensity = PARALLAX_MED

/// Ближний ярус у Eris - редкие ЯРКИЕ обломки на прозрачном (альфа 7-71 при
/// яркости 150-183), поэтому он идёт аддитивно, как и наши звёздные слои.
/atom/movable/screen/parallax_layer/eris/close
	speed = 1.8
	layer = 3
	parallax_intensity = PARALLAX_HIGH

// Блюспейс-шторм.
// Фоновый ярус (`bluespace_storm_background`) импортирован, но в профиль не входит:
// замер показал непрозрачную плиту средней яркости 0.8 из 255, то есть чистую
// черноту. У Eris она работала на BLEND_MULTIPLY поверх белого плана, у нас на
// аддитивном плане не даёт ничего.
/// Шов 26.9 - тайлить нельзя, идёт скайбоксом.
/atom/movable/screen/parallax_layer/eris/far/bluespace_storm
	icon_state = "bluespace_storm_far"
	layer_mode = PARALLAX_MODE_SKYBOX
	min_bleed = 160
	speed = 0.25
	layer = 0.6

/atom/movable/screen/parallax_layer/eris/close/bluespace_storm
	icon_state = "bluespace_storm_close"

// Кладбище кораблей
/atom/movable/screen/parallax_layer/eris/background/graveyard
	icon_state = "graveyard_background"

/// Крупные обломки станций почти непрозрачны (альфа 201), поэтому даже небольшой
/// шов 3.5 режет их пополам ровной прямой через весь экран. Скайбокс.
/atom/movable/screen/parallax_layer/eris/far/graveyard
	icon_state = "graveyard_far"
	layer_mode = PARALLAX_MODE_SKYBOX
	min_bleed = 160
	speed = 0.25
	layer = 0.6

/atom/movable/screen/parallax_layer/eris/close/graveyard
	icon_state = "graveyard_close"

// Поле мелких обломков
/atom/movable/screen/parallax_layer/eris/far/micro_debris
	icon_state = "micro_debris_far"

/atom/movable/screen/parallax_layer/eris/close/micro_debris
	icon_state = "micro_debris_close"

// Ионная буря. Ближнего яруса художник не нарисовал.
/atom/movable/screen/parallax_layer/eris/background/ion_blizzard
	icon_state = "ion_blizzard_background"

/atom/movable/screen/parallax_layer/eris/far/ion_blizzard
	icon_state = "ion_blizzard_far"

/**
 * Чёрная дыра. Изображение занимает весь холст 736 непрозрачно, поэтому это
 * скайбокс, а не статический объект: как объект оно закрыло бы собой квадрат
 * с видимыми краями.
 *
 * Запас намеренно оставлен дефолтным (48), в отличие от соседних ярусов Eris со
 * 160. Больше не нужно: этот слой идёт скайбоксом профиля, то есть absolute, и
 * прокрутка сцены его не двигает вовсе, а от собственной скорости 0.1 предел
 * запаса набирается только через сотни тайлов хода. Край при этом не покажется
 * ни при каком раскладе - смещение ЗАЖИМАЕТСЯ запасом, а не выезжает за него.
 * Поднимать запас значило бы зря апскейлить картинку на 9% при обычном view.
 */
/atom/movable/screen/parallax_layer/eris/photon_vortex
	icon_state = "photon_vortex"
	layer_mode = PARALLAX_MODE_SKYBOX
	speed = 0.1
	layer = 0.5
	parallax_intensity = PARALLAX_MED

/atom/movable/screen/parallax_layer/eris/background/bluespace_interphase
	icon_state = "bluespace_interphase"

// ---------------------------------------------------------------------------
// Пиковые ярусы
// ---------------------------------------------------------------------------

/**
 * Ярусы, которые каркас явления вешает на пик поверх профиля и снимает на выходе из него.
 *
 * Отдельного арта под пик нет и не нужно: это тот же ближний ярус, но быстрее и со
 * сдвигом. Наложенный на свой же слой, он вдвое уплотняет поле ровно тогда, когда
 * явление в полную силу, - и иллюминатор сам показывает, что сейчас пик.
 *
 * Сдвиг обязателен: без него копия встала бы пиксель в пиксель на оригинал, и вместо
 * удвоения плотности вышло бы простое осветление тех же самых обломков.
 */
/atom/movable/screen/parallax_layer/eris/close/graveyard/peak
	speed = 2.6
	layer = 3.2
	spawn_jitter_min = -320
	spawn_jitter_max = 320
	fade_in_time = 5 SECONDS

/atom/movable/screen/parallax_layer/eris/close/micro_debris/peak
	speed = 2.8
	layer = 3.2
	spawn_jitter_min = -320
	spawn_jitter_max = 320
	fade_in_time = 5 SECONDS

/atom/movable/screen/parallax_layer/eris/close/bluespace_storm/peak
	speed = 2.4
	layer = 3.2
	spawn_jitter_min = -320
	spawn_jitter_max = 320
	fade_in_time = 5 SECONDS

/// У ионной бури ближнего яруса художник не нарисовал, поэтому уплотняется дальний.
/// Тайлящийся, в отличие от скайбокса своего фона, - иначе он бы не двигался.
/atom/movable/screen/parallax_layer/eris/far/ion_blizzard/peak
	speed = 2.2
	layer = 3.2
	spawn_jitter_min = -320
	spawn_jitter_max = 320
	fade_in_time = 5 SECONDS

/// Вихрь на пике затягивает вещество: ближний ярус поля обломков, разогнанный вдвое
/// против штатного, читается как поток материи в аккреционный диск.
/atom/movable/screen/parallax_layer/eris/close/micro_debris/vortex_peak
	speed = 3.4
	layer = 3.2
	spawn_jitter_min = -320
	spawn_jitter_max = 320
	fade_in_time = 5 SECONDS

// ---------------------------------------------------------------------------
// goonstation: погода через маску плотности
// ---------------------------------------------------------------------------

/**
 * Часть погодных текстур goonstation полностью НЕПРОЗРАЧНА: это серый шум, у
 * которого прозрачность вычисляется из яркости цветовой матрицей. Приём (не код -
 * код у них под CC BY-NC-SA) даёт две вещи, которых иначе не получить:
 *
 * - силу явления одним числом: метель гуще или реже - это коэффициент матрицы,
 *   а не другая картинка;
 * - возможность вообще взять этот арт: положенный на BLEND_ADD как есть, он
 *   залил бы экран.
 *
 * ВЕШАТЬ МАТРИЦУ ОГУЛОМ НЕЛЬЗЯ. Замер каждого стейта показал, что половина из них
 * (`*_sparse`, `meteors`, `asteroids_*`, `clouds_*`) - обычные спрайты со своей
 * альфой 1-59%. Матрица на них не добавляет прозрачности, а домножает её на
 * яркость и почти гасит: `snow_sparse` уходит с альфы 4.3 на 2.7. Поэтому
 * коэффициент стоит только там, где исходник непрозрачен, и подобран под
 * измеренную яркость: чем темнее шум, тем больше нужен коэффициент.
 */
/atom/movable/screen/parallax_layer/goon
	icon = 'icons/effects/parallax/goon/weather.dmi'
	tile_size = 672

/// Яркость 136 из 255 при полной непрозрачности: без маски этот слой добавил бы
/// к каждому кадру ровно свою яркость, то есть залил бы экран. Коэффициент
/// подобран так, чтобы вклад слоя в среднюю яркость сцены был около 22 из 255.
/atom/movable/screen/parallax_layer/goon/snow_dense
	icon_state = "snow_dense"
	luminance_alpha = 0.14
	speed = 2
	layer = 4
	parallax_intensity = PARALLAX_HIGH

/// Спрайт со своей альфой - матрица не нужна.
/atom/movable/screen/parallax_layer/goon/snow_sparse
	icon_state = "snow_sparse"
	speed = 1.2
	layer = 3
	parallax_intensity = PARALLAX_MED

/// Яркость 82 из 255, вклад в сцену около 20.
/atom/movable/screen/parallax_layer/goon/dust_dense
	icon_state = "dust_dense"
	luminance_alpha = 0.25
	speed = 1.8
	layer = 4
	parallax_intensity = PARALLAX_HIGH

/atom/movable/screen/parallax_layer/goon/dust_sparse
	icon_state = "dust_sparse"
	speed = 1
	layer = 3
	parallax_intensity = PARALLAX_MED

/// Яркость всего 34 из 255 - тлеющие угли на почти чёрном. Коэффициент вшестеро
/// больше снежного, иначе слой не проявится вовсе; вклад в сцену около 10.
/atom/movable/screen/parallax_layer/goon/embers_dense
	icon_state = "embers_dense"
	luminance_alpha = 0.6
	speed = 2.2
	layer = 4
	parallax_intensity = PARALLAX_HIGH

/atom/movable/screen/parallax_layer/goon/embers_sparse
	icon_state = "embers_sparse"
	speed = 1.4
	layer = 3
	parallax_intensity = PARALLAX_MED

/**
 * Облака goonstation. В профили НЕ входят, хотя импортированы, и вот почему.
 *
 * `clouds_1` и `clouds_2` - чёрные маски (яркость 0 и 20 при собственной альфе):
 * goon красит их своей системой цвета, а выбирать за художника цвет мы не станем.
 * У `clouds_3` цвет свой, но это крупные кучевые облака, и на нашем вьюпорте одно
 * такое облако занимает треть экрана: в композите сцена читалась как серые валуны,
 * а не как погода.
 *
 * Тип оставлен, чтобы облака можно было включить, когда появится, откуда брать
 * цвет и как их масштабировать.
 */
/atom/movable/screen/parallax_layer/goon/clouds
	icon_state = "clouds_3"
	alpha = 90
	speed = 0.9
	layer = 2
	parallax_intensity = PARALLAX_MED

/// Яркость 32 из 255.
/atom/movable/screen/parallax_layer/goon/blowout_clouds
	icon_state = "blowout_clouds"
	luminance_alpha = 0.4
	speed = 1.6
	layer = 4
	parallax_intensity = PARALLAX_HIGH

/atom/movable/screen/parallax_layer/goon/meteors
	icon_state = "meteors"
	speed = 2.4
	layer = 4
	parallax_intensity = PARALLAX_HIGH

/// Пустота: почти чёрное поле, по которому ползут два яруса разреженных облаков.
/atom/movable/screen/parallax_layer/goon/void
	icon_state = "void"
	speed = 0.3
	layer = 1
	parallax_intensity = PARALLAX_LOW

/// Тёмный непрозрачный шум. Маска ему не нужна: аддитивный слой яркостью 14
/// сам по себе даёт мягкую дымку, а матрица только съела бы её.
/atom/movable/screen/parallax_layer/goon/void_clouds_1
	icon_state = "void_clouds_1"
	alpha = 150
	speed = 0.8
	layer = 2
	parallax_intensity = PARALLAX_MED

/// Яркость 7 из 255 - самый тёмный шум набора.
/atom/movable/screen/parallax_layer/goon/void_clouds_2
	icon_state = "void_clouds_2"
	alpha = 120
	speed = 1.4
	layer = 3
	parallax_intensity = PARALLAX_HIGH

/atom/movable/screen/parallax_layer/goon/asteroids_far
	icon_state = "asteroids_far"
	speed = 0.8
	layer = 2
	parallax_intensity = PARALLAX_MED

/atom/movable/screen/parallax_layer/goon/asteroids_near
	icon_state = "asteroids_near"
	speed = 1.9
	layer = 3
	parallax_intensity = PARALLAX_HIGH

/atom/movable/screen/parallax_layer/goon/asteroids_sparse
	icon_state = "asteroids_sparse"
	speed = 1.3
	layer = 3
	parallax_intensity = PARALLAX_MED
