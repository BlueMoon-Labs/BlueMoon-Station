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
	/// Текст татуировок на губах
	var/lips_tattoo_text = ""
	/// Текст татуировок на рогах
	var/horns_tattoo_text = ""
	/// Текст татуировок на хвосте
	var/tail_tattoo_text = ""
	/// Текст татуировок на левом бедре
	var/left_thigh_tattoo_text = ""
	/// Текст татуировок на правом бедре
	var/right_thigh_tattoo_text = ""
	/// Текст татуировок на ушах
	var/ears_tattoo_text = ""
	/// Текст татуировок на крыльях
	var/wings_tattoo_text = ""
	/// Текст татуировок на животе
	var/belly_tattoo_text = ""
	/// Текст татуировок на щеках
	var/cheeks_tattoo_text = ""
	/// Текст татуировок на лбу
	var/forehead_tattoo_text = ""
	/// Текст татуировок на подбородке
	var/chin_tattoo_text = ""
	/// Текст татуировок на левой кисти
	var/left_hand_tattoo_text = ""
	/// Текст татуировок на правой кисти
	var/right_hand_tattoo_text = ""
	/// Текст татуировок на левой ступне
	var/left_foot_tattoo_text = ""
	/// Текст татуировок на правой ступне
	var/right_foot_tattoo_text = ""
