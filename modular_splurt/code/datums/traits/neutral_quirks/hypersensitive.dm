/datum/quirk/hypersensitive
	name = "Гиперчувствительность"
	desc = "Всё вокруг влияет на ваше настроение больше, чем должно."
	value = 0
	flavor_quirk = TRUE
	gain_text = "<span class='danger'>Вы делаете из мухи слона.</span>"
	lose_text = "<span class='notice'>Вы больше не преувеличиваете значимость событий вокруг вас.</span>"
	mood_quirk = TRUE //yogs
	medical_record_text = "Пациент демонстрирует высокий уровень эмоциональной неустойчивости."

/datum/quirk/hypersensitive/add()
	var/datum/component/mood/mood = quirk_holder.GetComponent(/datum/component/mood)
	if(mood)
		mood.mood_modifier += 0.5

/datum/quirk/hypersensitive/remove()
	if(!quirk_holder)
		return
	var/datum/component/mood/mood = quirk_holder.GetComponent(/datum/component/mood)
	if(mood)
		mood.mood_modifier -= 0.5
