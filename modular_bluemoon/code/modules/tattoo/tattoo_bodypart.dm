// Расширение частей тела для хранения татуировок
// tattoo_text - перманентные татуировки, не смываются водой/мылом
// В отличие от writtentext (надписи ручкой), удаляются только хирургией
// Дефайны TATTOO_ZONE_* находятся в code/__BLUEMOONCODE/_DEFINES/tattoo.dm

/obj/item/bodypart
	/// Текст татуировок на этой части тела
	var/tattoo_text = ""
	/// Текст татуировок на паху (хранится на груди, но имеет отдельную видимость)
	var/groin_tattoo_text = ""
	/// Текст татуировок на ягодицах
	var/butt_tattoo_text = ""
	/// Текст татуировок на вагине
	var/pussy_tattoo_text = ""
	/// Текст татуировок на яичках
	var/testicles_tattoo_text = ""
	/// Текст татуировок на груди (женской)
	var/breasts_tattoo_text = ""
	/// Текст татуировок на половом члене
	var/penis_tattoo_text = ""
