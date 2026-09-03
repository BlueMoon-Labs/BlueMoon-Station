/// Ввод речи и эмоутов обязан экранироваться ровно один раз.
///
/// say()/whisper() зовут sanitize() внутри себя, поэтому их вербы отдают сырой
/// текст (raw_text_or_reflect). Канал эмоутов не экранирует ничего, поэтому его
/// вербы отдают уже закодированный текст (finalize_stripped_input).
///
/// Когда вербы речи начали кодировать текст сами, получалось два прохода подряд:
/// "<" -> "&lt;" -> "&amp;lt;", и игрок читал в чате голые сущности вместо своих
/// угловых скобок.
/datum/unit_test/say_input_encoding

/datum/unit_test/say_input_encoding/Run()
	var/brackets = "<обнимает>"

	// Сырая ветка: текст уходит в say() как есть, экранировать его будет sanitize() там.
	TEST_ASSERT_EQUAL(raw_text_or_reflect(null, brackets), brackets, "raw_text_or_reflect не должен экранировать текст - say() сделает это сам")

	// Кодирующая ветка: ровно одно применение html_encode для канала эмоутов.
	var/encoded = finalize_stripped_input(brackets, MAX_MESSAGE_LEN, TRUE)
	TEST_ASSERT_EQUAL(encoded, "&lt;обнимает&gt;", "finalize_stripped_input должен экранировать угловые скобки ровно один раз")

	// Второй проход по уже закодированному тексту - это и есть баг: игрок видит "&lt;" буквально.
	TEST_ASSERT_EQUAL(sanitize(encoded), "&amp;lt;обнимает&amp;gt;", "повторное экранирование должно давать &amp;lt; - именно это и ловит тест")
	TEST_ASSERT_NOTEQUAL(finalize_stripped_input(encoded, MAX_MESSAGE_LEN, TRUE), encoded, "finalize_stripped_input не идемпотентен, дважды его звать нельзя")

	// Управляющие символы вычищаются и в сырой ветке: они переживают html_encode,
	// но ломают круговой путь DM<->TGUI.
	TEST_ASSERT_EQUAL(raw_text_or_reflect(null, "a[ascii2text(14)]b"), "ab", "raw_text_or_reflect должен вычищать управляющие символы")

	// Кириллица и пробельные символы не должны страдать ни в одной из веток.
	TEST_ASSERT_EQUAL(raw_text_or_reflect(null, "тест\tстрока"), "тест\tстрока", "raw_text_or_reflect испортил юникод или табуляцию")

	// Пустой ввод отличается от отменённого только тем, что оба дают null.
	TEST_ASSERT_NULL(raw_text_or_reflect(null, ""), "пустой ввод должен возвращать null")
	TEST_ASSERT_NULL(raw_text_or_reflect(null, "[ascii2text(14)]"), "ввод из одних управляющих символов должен возвращать null")
