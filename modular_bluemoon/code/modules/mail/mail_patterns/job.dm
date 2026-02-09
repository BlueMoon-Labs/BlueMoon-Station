/**
 *
 * ПО РАБОТЕ
 *
 */

/datum/mail_pattern/job/fake_nuke_disk
	name = "Фальшивый ядерный диск"
	description = "Содержит пластиковый ядерный диск и письмо от мошенников."

	weight = MAIL_WEIGHT_RARE

	sender = "ЦНТР КОМАНДОВАНИЕ"
	letter_sign = ""
	letter_icon_state = "docs_blue"
	letter_title = "Срочный приказ с ЦК"
	letter_html = {"<center><font color=\"RoyalBlue\"><h1>Центральное Командование — Отдел управления стратегическими активами</h1></font></center>
					<hr /><br>
					<font size=\"2\">Канал: SECURE / Приоритет: DELTA / Автоматическая рассылка</font><br><br>
					В рамках внеплановой инвентаризации и обновления протоколов хранения стратегических носителей, Центральное Командование производит <b>срочный отзыв партии ядерных дисков</b> (серии <b>NUC-D/NT-7</b>).<br><br>
					Для обеспечения непрерывности работы станции, вам отправлен <b>обновлённый сертифицированный носитель</b> нового образца. Получение возможно только после выполнения процедуры возврата.<br><br>
					<b>Требуется выполнить немедленно:</b><br>
					1) Извлечь текущий <b>ядерный диск</b> из хранения/персонального сейфа.<br>
					2) Отправить его <b>курьерской капсулой</b> на адрес, указанный ниже.<br>
					3) После отправки — <b>принять новый диск</b> и разместить его как основной носитель станции.<br><br>
					<font color=\"#FF0000\"><b>Срок выполнения: 10 минут с момента получения письма.</b></font><br>
					Невыполнение требований будет расценено как нарушение регламента <b>NT-SEC-NUC-17</b> и приведёт к дисциплинарным мерам в отношении ответственного персонала.<br><br>
					<b>Адрес для отправки (временный):</b><br>
					<font color=\"#8B0000\"><b>ZETA 12.1/6 AlphaZ64</b></font><br><br>
					<hr />
					<font color=\"grey\">
					<div align=\"justify\">
					Примечание: данное сообщение предназначено исключительно для уполномоченного персонала. Передача содержания третьим лицам запрещена.
					</div>
					</font>"}

	whitelisted_jobs = list(
		"Captain",
		"Chief Engineer",
		"Research Director",
		"Head of Personnel",
		"Chief Medical Officer",
		"Head Of Security",
	)

	initial_contents = list(
		/obj/item/disk/nuclear/fake/obvious/mail
	)

/datum/mail_pattern/job/mime_nothing
	name = "Набор для мима"
	description = "Содержит латексную перчатку-шарик, маску мима и бутылку «Ничего»."

	weight = MAIL_WEIGHT_UNCOMMON

	sender = ""
	letter_sign = ""
	letter_title = "Silence"
	letter_html = {""}

	whitelisted_jobs = list(
		"Mime"
	)

	initial_contents = list(
		/obj/item/reagent_containers/food/drinks/bottle/bottleofnothing,
		/obj/item/latexballon,
		/obj/item/clothing/mask/gas/mime,
	)
