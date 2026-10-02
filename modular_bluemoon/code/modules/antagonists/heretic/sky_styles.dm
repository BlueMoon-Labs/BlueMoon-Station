/datum/heretic_path
	/// Лист неба пути: `presence` (Знак 1:1, фигура в круге около 200) и свои фактуры из [sky_texture_states].
	var/sky_icon
	/// Сторона кадра листа неба: у Пляски лист делят пары Болеро в 256.
	var/sky_icon_size = 240
	var/sky_tint
	var/sky_tint_alpha = 65
	/// Насколько путь гасит звёзды, 0..255.
	var/sky_dim = 0
	/// Цвет зарева вокруг Знака; без него - чернила книги.
	var/sky_glow
	var/sky_glow_alpha = 100
	/// Корона за диском планеты, пока Знак её затмевает.
	var/sky_corona_alpha = 170
	/// Насколько затмение гасит саму планету, 0..255.
	var/sky_eclipse = 180
	var/sky_particles
	/// Свои фактуры неба в [sky_icon]; без них небо заполняет туманность из [GLOB.heretic_sky_veils] в цвете пути.
	var/list/sky_texture_states
	var/sky_texture_speed = 0.8
	var/sky_texture_drift = 120 SECONDS
	var/sky_texture_angle = 180
	/// Луп неба на станции, пока путь вознёсся; громкость в файле нормализована, здесь - уровень пути.
	var/sky_loop
	var/sky_loop_volume = 22
	/// Акцент неба на главном событии вознёсшегося.
	var/sky_event_sound

/datum/heretic_path/proc/sky_base_alpha(role)
	switch(role)
		if(HERETIC_SKY_ROLE_TINT)
			return sky_tint_alpha
		if(HERETIC_SKY_ROLE_DIM)
			return sky_dim
		if(HERETIC_SKY_ROLE_GLOW)
			return sky_glow_alpha
		if(HERETIC_SKY_ROLE_CORONA)
			return sky_corona_alpha
		if(HERETIC_SKY_ROLE_ECLIPSE)
			return sky_eclipse
	return 255

/// Поправка alpha роли на ярусе неба пути; ярусы есть только у Пляски.
/datum/heretic_path/proc/sky_tier_alpha(role, tier)
	return 1

/// Скорость, время и угол дрейфа яруса неба: дальний ярус медленнее, ближний обгоняет его под углом.
/datum/heretic_path/proc/sky_texture_params(index)
	if(index == 2)
		return list(sky_texture_speed * 1.75, sky_texture_drift * 0.7, sky_texture_angle + 25)
	return list(sky_texture_speed, sky_texture_drift, sky_texture_angle)

/datum/heretic_path/proc/sky_texture_count()
	return length(sky_texture_states) || length(GLOB.heretic_sky_veils)

/datum/heretic_path/ash
	sky_icon = 'modular_bluemoon/icons/effects/heretic_sky/ash.dmi'
	sky_tint = "#b34a12"
	sky_tint_alpha = 70
	sky_dim = 40
	sky_particles = /particles/heretic_sky/ash
	sky_texture_angle = 20

/datum/heretic_path/rust
	sky_icon = 'modular_bluemoon/icons/effects/heretic_sky/rust.dmi'
	sky_tint = "#8a4a1a"
	sky_dim = 60
	sky_particles = /particles/heretic_sky/rust

/datum/heretic_path/flesh
	sky_icon = 'modular_bluemoon/icons/effects/heretic_sky/flesh.dmi'
	sky_tint = "#7a1030"
	sky_tint_alpha = 75
	sky_dim = 110
	sky_particles = /particles/heretic_sky/flesh
	sky_texture_drift = 180 SECONDS

/datum/heretic_path/void
	sky_icon = 'modular_bluemoon/icons/effects/heretic_sky/void.dmi'
	sky_tint = "#2a3a7a"
	sky_tint_alpha = 70
	sky_dim = 150
	sky_particles = /particles/heretic_sky/void
	sky_texture_angle = 250

/datum/heretic_path/blade
	sky_icon = 'modular_bluemoon/icons/effects/heretic_sky/blade.dmi'
	sky_tint = "#718494"
	sky_tint_alpha = 55
	sky_dim = 50
	sky_particles = /particles/heretic_sky/blade
	sky_texture_angle = 225

/datum/heretic_path/moon
	sky_icon = 'modular_bluemoon/icons/effects/heretic_sky/moon.dmi'
	sky_tint = "#776d9e"
	sky_dim = 120
	sky_particles = /particles/heretic_sky/moon
	sky_texture_drift = 200 SECONDS
	sky_texture_angle = 90

/datum/heretic_path/cosmic
	sky_icon = 'modular_bluemoon/icons/effects/heretic_sky/cosmic.dmi'
	sky_tint = "#237d91"
	sky_tint_alpha = 70
	sky_dim = 90
	sky_particles = /particles/heretic_sky/cosmic
	sky_texture_drift = 240 SECONDS
	sky_texture_angle = 135

/datum/heretic_path/lock
	sky_icon = 'modular_bluemoon/icons/effects/heretic_sky/lock.dmi'
	sky_tint = "#b99335"
	sky_dim = 60
	sky_particles = /particles/heretic_sky/lock
	sky_texture_angle = 0

/datum/heretic_path/tide
	sky_icon = 'modular_bluemoon/icons/effects/heretic_sky/tide.dmi'
	sky_tint = "#166c80"
	sky_tint_alpha = 75
	sky_dim = 90
	sky_particles = /particles/heretic_sky/tide
	sky_texture_drift = 90 SECONDS
	sky_texture_angle = 270

/datum/heretic_path/glass
	sky_icon = 'modular_bluemoon/icons/effects/heretic_sky/glass.dmi'
	sky_tint = "#70a6a2"
	sky_tint_alpha = 60
	sky_dim = 50
	sky_particles = /particles/heretic_sky/glass
	sky_texture_angle = 160

/datum/heretic_path/blood
	sky_icon = 'modular_bluemoon/icons/effects/heretic_sky/blood.dmi'
	sky_tint = "#990e27"
	sky_tint_alpha = 80
	sky_dim = 120
	sky_particles = /particles/heretic_sky/blood
	sky_texture_angle = 180

/datum/heretic_path/echo
	sky_icon = 'modular_bluemoon/icons/effects/heretic_sky/echo.dmi'
	sky_tint = "#9e7943"
	sky_tint_alpha = 60
	sky_dim = 50
	sky_particles = /particles/heretic_sky/echo
	sky_texture_drift = 160 SECONDS

/datum/heretic_path/sand
	sky_icon = 'modular_bluemoon/icons/effects/heretic_sky/sand.dmi'
	sky_tint = "#b49a68"
	sky_dim = 40
	sky_particles = /particles/heretic_sky/sand
	sky_texture_drift = 70 SECONDS
	sky_texture_angle = 100

/datum/heretic_path/wax
	sky_icon = 'modular_bluemoon/icons/effects/heretic_sky/wax.dmi'
	sky_tint = "#807b62"
	sky_tint_alpha = 70
	sky_dim = 90
	sky_particles = /particles/heretic_sky/wax
	sky_texture_drift = 150 SECONDS
	sky_texture_angle = 90

/datum/heretic_path/spirit
	sky_icon = 'modular_bluemoon/icons/effects/heretic_sky/spirit.dmi'
	sky_tint = "#4b9384"
	sky_dim = 130
	sky_particles = /particles/heretic_sky/spirit
	sky_texture_drift = 110 SECONDS
	sky_texture_angle = 90

/datum/heretic_path/dance
	sky_icon = 'modular_bluemoon/icons/effects/heretic_sky/dance.dmi'
	sky_tint = "#8f3a2a"
	sky_tint_alpha = 70
	sky_dim = 60
	sky_particles = /particles/heretic_sky/dance
	sky_texture_states = list("bolero_couples_far", "bolero_couples_near")
	sky_icon_size = 256

/datum/heretic_path/dance/sky_texture_params(index)
	if(index == 2)
		return list(1.4, 50 SECONDS, 270)
	return list(0.6, 90 SECONDS, 90)

/// Ярусы Болеро: бал проступает с первой ступени, оркестр - с третьей, Финал заливает небо.
/datum/heretic_path/dance/sky_tier_alpha(role, tier)
	switch(role)
		if(HERETIC_SKY_ROLE_TEXTURE)
			return tier >= 1
		if(HERETIC_SKY_ROLE_TEXTURE_NEAR)
			return tier >= 2
		if(HERETIC_SKY_ROLE_TINT)
			var/static/list/tint_by_tier = list(0.9, 1, 1.2, 1.5)
			return tint_by_tier[clamp(tier, 0, 3) + 1]
		if(HERETIC_SKY_ROLE_PARTICLES, HERETIC_SKY_ROLE_FIELD)
			return tier >= 3 ? 1 : 0.5
	return 1
