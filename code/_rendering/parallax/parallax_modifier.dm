/**
 * # Модификатор параллакса
 *
 * Временное изменение сцены на одном z-уровне: подмена профиля целиком,
 * добавление слоя поверх или перекраска.
 *
 * Модификаторы живут стеком на z и снимаются по токену, а не "восстановлением
 * предыдущего состояния". Поэтому два события, наложившиеся друг на друга,
 * не откатывают чужие изменения: снятие любого из них просто пересобирает
 * сцену из того, что осталось в стеке.
 */
/datum/parallax_modifier
	/// Уникальный в пределах z ключ источника. Повторный add с тем же токеном
	/// заменяет запись, а не добавляет вторую.
	var/token
	/// z-уровень, к которому привязан модификатор.
	var/z
	/// Больший приоритет применяется позже и перебивает меньший.
	var/priority = 0
	/// Полная подмена профиля. Тип /datum/parallax_profile или null.
	var/datum/parallax_profile/profile
	/// Типпасы слоёв, добавляемых поверх выбранного профиля.
	var/list/extra_layers
	/// Цвет, которым перекрашиваются слои с palette_tinted вместо палитры профиля.
	var/tint
	/// Цвета, выставленные animate_layer_type() адресно по типу слоя: типпас -> цвет.
	/// Хранятся здесь, а не на шаблоне, потому что шаблон выбрасывается на каждой
	/// инвалидации z, и без этого фазовая подсветка сбрасывалась бы на исходный цвет
	/// слоя посреди явления - до следующего вызова, которого на плато пика не будет.
	var/list/layer_colors

/datum/parallax_modifier/New(token, z, priority = 0, datum/parallax_profile/profile, list/extra_layers, tint)
	src.token = token
	src.z = z
	src.priority = priority
	src.profile = profile
	src.extra_layers = extra_layers?.Copy()
	src.tint = tint

/datum/parallax_modifier/Destroy(force)
	profile = null
	extra_layers = null
	layer_colors = null
	return ..()
