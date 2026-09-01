/**
 * # Процедурная планета
 *
 * Порт замысла генератора Aurora, дополненный слоями Polaris.
 *
 * Ключ ко всему - ассеты хранятся ОБЕСЦВЕЧЕННЫМИ масками. Ни один стейт не несёт
 * собственного цвета, цвет подставляется в рантайме, поэтому семнадцать стейтов
 * на 109 КБ дают неограниченное число непохожих планет. Отдельный DM-тип на
 * каждую планету при таком подходе не нужен и был бы прямой ошибкой.
 *
 * Оригинал Aurora выводил цвет облаков из состава атмосферы своей оверкарты. У
 * нас оверкарты нет, поэтому палитра выбирается по типу мира, а сам мир - один
 * раз на z-уровень вместе с профилем.
 */
/atom/movable/screen/parallax_layer/planet_generated
	icon = 'icons/effects/parallax/planets.dmi'
	icon_state = "base1"
	blend_mode = BLEND_OVERLAY
	layer_mode = PARALLAX_MODE_STATIC
	center_x = -100
	center_y = -100
	speed = 1
	layer = 30
	base_scale = 1.6
	parallax_intensity = PARALLAX_MED
	spawn_jitter_min = 90
	spawn_jitter_max = 150
	// То же окружение, что у остальных планет - см. space/planet.
	environment_flags = PARALLAX_ENV_STATION | PARALLAX_ENV_SPACE_RUINS | PARALLAX_ENV_CENTCOM
	/// Вероятность колец в процентах. У Aurora было 20.
	var/ring_chance = 20
	/// Планета уже собрана. Клон её не пересобирает: он копирует appearance
	/// исходника, иначе у каждого клиента был бы СВОЙ мир на общем z.
	var/generated = FALSE
	/// Палитры поверхности, воды и облаков. Одна тройка на планету.
	var/static/list/world_palettes = list(
		// Земной: зелёная суша, синяя вода, белые облака
		list("#7a8f5a", "#2f5c8f", "#e8eef5", "#5fa8d3"),
		// Пустынный: охра, солёные озёра, рыжая пыль
		list("#b08a4f", "#6f5a3a", "#e0c9a0", "#d8a860"),
		// Ледяной: голубоватая порода, тёмная вода, белая метель
		list("#9fb3c8", "#20364f", "#ffffff", "#8fd0ff"),
		// Вулканический: базальт, лава, пепел
		list("#4a3f3a", "#c9482a", "#7a6a63", "#ff7040"),
		// Токсичный: болотный, кислотный, зелёная дымка
		list("#5f6b3a", "#8fbf3a", "#c8e08a", "#a0ff60"),
		// Мёртвый: серая порода, без воды, тонкая дымка
		list("#7a7a7a", "#3a3a3a", "#bdbdbd", "#9aa5b1"),
	)

/**
 * Сборка висит на ApplyLayerMode, а не только на Initialize.
 *
 * Профиль зовёт ApplyLayerMode вручную ровно потому, что SSatoms во время
 * инициализации мира откладывает Initialize на потом. Оставь сборку в одном
 * Initialize - и в такой момент клиент получил бы вместо планеты голую
 * неокрашенную маску `base1` без воды, облаков, тени и колец.
 */
/atom/movable/screen/parallax_layer/planet_generated/ApplyLayerMode()
	. = ..()
	Generate()

/**
 * Собирает планету.
 *
 * Порядок наложения - не украшение, а именно то, что даёт объём:
 * гало атмосферы уходит в underlays (светится ИЗ-ПОД диска), тень ложится
 * поверх поверхности, а световая кромка - поверх тени, иначе терминатор
 * съедает подсветку. Кольцо шире диска и потому смещено на четверть своего
 * холста, чтобы передняя дуга легла на диск.
 */
/atom/movable/screen/parallax_layer/planet_generated/proc/Generate()
	if(generated)
		return
	generated = TRUE
	var/list/palette = pick(world_palettes)
	var/surface_color = palette[1]
	var/water_color = palette[2]
	var/cloud_color = palette[3]
	var/atmosphere_color = palette[4]

	icon_state = "base[rand(1, 3)]"
	color = surface_color

	var/list/new_overlays = list()

	var/mutable_appearance/water = mutable_appearance(icon, "water[rand(1, 3)]")
	water.color = water_color
	// Случайный поворот океанов - самый дешёвый способ сделать две планеты на
	// одной паре масок непохожими.
	var/matrix/water_turn = matrix()
	water_turn.Turn(rand(0, 359))
	water.transform = water_turn
	new_overlays += water

	if(prob(45))
		var/mutable_appearance/mountains = mutable_appearance(icon, "mountains")
		mountains.color = surface_color
		mountains.alpha = 140
		new_overlays += mountains

	if(prob(35))
		var/mutable_appearance/caps = mutable_appearance(icon, "icecaps")
		caps.color = "#ffffff"
		caps.alpha = 190
		new_overlays += caps

	var/mutable_appearance/clouds = mutable_appearance(icon, prob(70) ? "clouds[rand(1, 3)]" : "weak_clouds")
	clouds.color = cloud_color
	clouds.alpha = rand(120, 210)
	new_overlays += clouds

	// Тень терминатора - множением, иначе она не затемняет, а замазывает.
	var/mutable_appearance/shadow = mutable_appearance(icon, "shadow[rand(1, 3)]")
	shadow.blend_mode = BLEND_MULTIPLY
	new_overlays += shadow

	// Световая кромка поверх тени: у Aurora её нет, это добавка от Polaris,
	// и именно она превращает плоский круг в шар.
	var/mutable_appearance/rim = mutable_appearance(icon, "lightrim")
	rim.color = atmosphere_color
	rim.alpha = 200
	new_overlays += rim

	if(prob(ring_chance))
		var/mutable_appearance/ring = mutable_appearance('icons/effects/parallax/planet_rings.dmi', prob(50) ? "sparse" : "dense")
		ring.color = surface_color
		ring.alpha = 170
		ring.pixel_x = -128
		ring.pixel_y = -128
		new_overlays += ring

	overlays = new_overlays

	var/mutable_appearance/halo = mutable_appearance(icon, "atmoring")
	halo.color = atmosphere_color
	halo.alpha = 150
	underlays = list(halo)
