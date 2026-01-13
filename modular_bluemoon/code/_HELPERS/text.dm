#define symbol_at(text, index) copytext_char(text, index, index+1)
/**
 * Calculate Jaro similarity between two strings.
 *
 * Arguments:
 * * text_a, text_b - Strings to compare.
 *
 * Returns a number between 0 and 1, where
 * * 0 - strings do not match at all
 * * 1 - exact match
 *
 * Reference: https://en.wikipedia.org/wiki/Jaro%E2%80%93Winkler_distance
 */
/proc/jaro_similarity(text_a, text_b)
	var/len_a = length_char(text_a)
	var/len_b = length_char(text_b)

	if (len_a == 1 && len_b == 1)
		return text_a == text_b // TRUE и FALSE в бьёнде - 1 и 0

	var/max_range = FLOOR(max(len_a, len_b) / 2, 1) - 1

	var/list/symbols_matched_a = list()
	var/list/symbols_matched_b = list()

	for (var/i in 1 to len_a) symbols_matched_a += FALSE
	for (var/i in 1 to len_b) symbols_matched_b += FALSE

	var/matches = 0
	for (var/i in 1 to len_a)
		for (var/j in max(1, i - max_range) to min(len_b, i + max_range))
			if (symbol_at(text_a, i) == symbol_at(text_b, j) && !symbols_matched_b[j])
				symbols_matched_a[i] = TRUE
				symbols_matched_b[j] = TRUE
				matches++
				break

	if (!matches) return 0

	// Считаем совпадения символов, но
	// когда между ними один неподходящий символ
	var/transpositions = 0
	var/cursor = 1
	for (var/i in 1 to len_a)
		if (symbols_matched_a[i])
			while (!symbols_matched_b[cursor] && cursor < len_b)
				cursor++

			cursor++
			if (symbol_at(text_a, i) != symbol_at(text_b, cursor))
				transpositions++

	transpositions /= 2

	// Модификация, чтоб был более точный поиск
	// Ошибки в словах нам не нравятся
	transpositions /= 2

	return ((matches / len_a) + (matches / len_b) + ((matches - transpositions) / matches)) / 3

/**
 * Calculate Jaro-Winkler similarity between two strings.
 *
 * Arguments:
 * * text_a, text_b - Strings to compare.
 * * scaling_factor - A factor that increases the similarity value when
 *   the beginnings of strings match. *Only the first 4 characters are
 *   taken into account.*
 *
 * Returns a number between 0 and 1, where
 * * 0 - strings do not match at all
 * * 1 - exact match
 *
 * Reference: https://en.wikipedia.org/wiki/Jaro%E2%80%93Winkler_distance
 */
/proc/jaro_winkler_similarity(text_a, text_b, scaling_factor=0.1)
	var/similarity = jaro_similarity(text_a, text_b)
	if (similarity == 0 || similarity == 1)
		return similarity

	var/len_a = length_char(text_a)
	var/len_b = length_char(text_b)

	var/common_prefix = 0
	for (var/i in 1 to min(len_a, len_b, 4))
		if (symbol_at(text_a, i) != symbol_at(text_b, i))
			break
		common_prefix++

	// Модификация, чтоб был более точный поиск
	// Люто увеличиваем similarity, если точно что-то совпало
	if (len_a > len_b)
		similarity += findtext_char(text_a, text_b) * 5
	else
		similarity += findtext_char(text_b, text_a) * 5

	return similarity + (common_prefix * scaling_factor * (1 - similarity))

/**
 * Calculate Jaro-Winkler distance between two strings.
 *
 * Arguments:
 * * text_a, text_b - Strings to compare.
 * * scaling_factor - A factor that increases the similarity value when
 *   the beginnings of strings match. *Only the first 4 characters are
 *   taken into account.*
 *
 * Returns a number between 0 and 1, where
 * * 0 - exact match
 * * 1 - strings do not match at all
 *
 * Reference: https://en.wikipedia.org/wiki/Jaro%E2%80%93Winkler_distance
 */
#define jaro_winkler_distance(text_a, text_b, scaling_factor) (1 - jaro_winkler_similarity(text_a, text_b, scaling_factor))


/proc/fuzzy_search(needle, list/haystack, key, amount=0, case_sensitive=TRUE)
	var/list/weights = list()

	if (!case_sensitive) needle = lowertext(needle)

	for (var/i in 1 to length(haystack))
		var/candidate = haystack[i]

		// На случай если нам нужно искать по подэлементу
		if (key) candidate = candidate[key]

		if (!candidate) continue

		var/val = jaro_winkler_distance(needle, !case_sensitive ? lowertext(candidate) : candidate, 0.15)

		weights[haystack[i]] = val

	sortTim(weights, GLOBAL_PROC_REF(cmp_numeric_asc), TRUE)

	var/list/winners = list()
	for (var/winner in weights)
		winners += winner

	return winners.Copy(1, amount+1)


/proc/simple_search(needle, list/haystack, key, case_sensitive=TRUE)
	var/list/winners = list()
	for (var/i in 1 to length(haystack))
		var/candidate = haystack[i]

		// На случай если нам нужно искать по подэлементу
		if (key) candidate = candidate[key]

		if (!candidate) continue

		if (case_sensitive)
			if (!findtextEx_char(candidate, needle))
				continue
		else
			if (!findtext_char(candidate, needle))
				continue

		winners += haystack[i]

	return winners

// Прок-хелпер для examine-string'а материалов. Нужен по большей части для бэкапа неучтённых словарём материалов, а также если будут новые материалы.
/proc/material_to_ru_nominative(mat_name)
	var/ru_mat_name = GLOB.mat_ru_nominative[lowertext(mat_name)]
	if(ru_mat_name)
		return ru_mat_name

	return mat_name

/proc/material_to_ru_genitive(mat_name)
	var/ru_mat_name = GLOB.mat_ru_genitive[lowertext(mat_name)]
	if(ru_mat_name)
		return ru_mat_name

	return mat_name

// падежи для бюджетов
/proc/budget_to_ru_nominative(budget_name)
	var/ru_budget_name = GLOB.budget_ru_nominative[lowertext(budget_name)]
	if(ru_budget_name)
		return ru_budget_name

	return budget_name

/proc/budget_to_ru_genitive(budget_name)
	var/ru_budget_name = GLOB.budget_ru_genitive[lowertext(budget_name)]
	if(ru_budget_name)
		return ru_budget_name

	return budget_name
