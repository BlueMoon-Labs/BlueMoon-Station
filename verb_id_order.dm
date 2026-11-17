// Первый файл сборки. DreamMaker нумерует процы по корням дерева типов в порядке первого объявления корня, а клиент молча не вызывает верб, чей проц получил id больше 65535.
// Корни с вербами объявлены здесь первыми, чтобы рост остального кода (почти весь он в /datum) их не сдвигал. Новый корень с вербами вписывать сюда же, до /datum; сторожа - unit test verb_proc_ids и scan_verb_proc_ids() при старте мира.

/client
/mob
/obj

// Глобальные процы тоже бывают вербами (possess), объявление этого проца ставит их корень сюда.
/// Номер проца в таблице мира, null для не-проца
/proc/verb_proc_id(procpath)
	var/ref_text = "\ref[procpath]"
	if(copytext(ref_text, 1, 6) != "\[0x26")
		return null
	return hex2num(copytext(ref_text, 6, length(ref_text)))

/datum/admins
/datum/verbs
