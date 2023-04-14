#define TRAIT_IMAGINARYPERSON		"ImaginaryPerson"

/datum/quirk/imaginary_person
	name = "������ ��������"
	desc = "� ��� �������� ������ � ������. ��� �����, ������� �� ���, ��� ���... ������ �� ������������ �� ��� ����������� ������� ����!"
	value = 0
	mob_trait = TRAIT_IMAGINARYPERSON
	human_only = TRUE
	gain_text = null // Handled by trauma.
	lose_text = null
	medical_record_text = "� �������� ����������� ��������� ������� � ������ ��������� ���� ��� ��������� ��������."
	on_spawn_immediate = FALSE

/datum/quirk/imaginary_person/add()
	var/datum/brain_trauma/severe/split_personality/T = new()
	var/mob/living/carbon/human/H = quirk_holder
	H.gain_trauma(T, TRAUMA_RESILIENCE_ABSOLUTE)