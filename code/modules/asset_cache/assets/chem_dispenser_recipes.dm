/**
 * Книга рецептов диспенсера как JSON-ассет.
 *
 * Тело книги весит от полумегабайта до 1.17 МБ на набор реагентов, и раньше оно
 * ездило внутри сообщения tgui: url_encode(json_encode(...)) просит у 32-битного
 * DreamDaemon непрерывный кусок памяти в разы больше самой книги - на таких
 * аллокациях процесс и умирал (раунды 9941/9948; раунд 9954 поймал 1.17 МБ уже
 * предупреждением). Ассет кодируется один раз на набор реагентов, уезжает клиенту
 * файлом через транспорт ассетов и кэшируется на его стороне, а в нагрузке
 * интерфейса остаётся только имя файла.
 *
 * Экземпляр на каждый набор реагентов создаёт ensure_recipes_asset() диспенсера;
 * абстрактным типом ассет объявлен ровно поэтому - SSassets не должен поднимать
 * его сам, без набора он пуст.
 */
/datum/asset/json/chem_dispenser_recipes
	_abstract = /datum/asset/json/chem_dispenser_recipes
	/// Книга рецептов, которую отдаст generate(). Отпускается сразу после
	/// регистрации: файл уже записан, а сам список и так живёт в
	/// shared_dispenser_recipe_caches у диспенсеров.
	var/list/payload

/datum/asset/json/chem_dispenser_recipes/New(reagents_hash, list/recipes)
	name = "chem_recipes_[reagents_hash]"
	payload = recipes
	..()
	payload = null

/datum/asset/json/chem_dispenser_recipes/generate()
	return payload
