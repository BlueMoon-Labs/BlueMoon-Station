/**
 * Регрессионный тест XSS-цепочки: бумага -> fax.dm/get_paper_html() ->
 * message_log["paper_html"] -> AdminTicketPanel.js -> dangerouslySetInnerHTML.
 *
 * Проверяем, что sanitize_paper_html() превращает любой пользовательский HTML
 * в безобидный текст и разрешает только точные теги из белого списка.
 */
/datum/unit_test/paper_html_sanitization

/datum/unit_test/paper_html_sanitization/Run()
	// Классический вектор из лога инцидента: <svg onload=...>
	var/attack = "<svg onload=alert(1)>text</svg>"
	var/clean = sanitize_paper_html(attack)
	TEST_ASSERT(findtext(clean, "&lt;svg onload=alert(1)&gt;"), "SVG-подобный ввод должен остаться заэкранированным текстом")
	TEST_ASSERT(!findtext(clean, "<svg"), "svg не должен превратиться в реальный тег")

	// Вектор из Q1 атаки: <img src=x onerror=import('//...')>
	var/img_attack = "<img src=x onerror=alert(1)>"
	var/clean_img = sanitize_paper_html(img_attack)
	TEST_ASSERT(!findtext(clean_img, "<img"), "img не должен превратиться в реальный тег")
	TEST_ASSERT(findtext(clean_img, "&lt;img"), "img-подобный ввод должен остаться текстом")

	// Атрибуты не должны проникать даже в разрешённый тег
	var/attr_attack = "<b onload=alert(1)>x</b>"
	var/clean_attr = sanitize_paper_html(attr_attack)
	TEST_ASSERT(!findtext(clean_attr, "<b onload"), "атрибут onload не должен выжить на разрешённом теге")

	// Повторное кодирование entity тоже не должно создавать тег
	var/entity_attack = "&lt;svg onload=alert(1)&gt;"
	var/clean_entity = sanitize_paper_html(entity_attack)
	TEST_ASSERT(!findtext(clean_entity, "<svg"), "двойное кодирование не должно создавать тег")

	// Разрешённое форматирование сохраняется
	var/formatting = sanitize_paper_html("<b>жирный</b> и <i>курсив</i>")
	TEST_ASSERT(findtext(formatting, "<b>жирный</b>"), "безопасный тег <b> должен сохраняться")
	TEST_ASSERT(findtext(formatting, "<i>курсив</i>"), "безопасный тег <i> должен сохраняться")
