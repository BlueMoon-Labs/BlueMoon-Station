import { Fragment } from 'inferno';

import { useBackend, useLocalState } from '../backend';
import { Box, Button, Collapsible, Icon, Input, LabeledList, Section, Table, Tooltip } from '../components';
import { Window } from '../layouts';

// Muted/pastel colors for ERP tag row backgrounds
const erpTagRowColor = {
  'Unset': null,
  'Top': 'rgba(255, 80, 80, 0.15)',
  'Top-Pref': 'rgba(255, 80, 80, 0.10)',
  'Submissive Top': 'rgba(80, 200, 200, 0.15)',
  'Bottom': 'rgba(80, 130, 255, 0.15)',
  'Bottom-Pref': 'rgba(80, 130, 255, 0.10)',
  'Dominant Bottom': 'rgba(255, 165, 50, 0.15)',
  'Switch': 'rgba(255, 220, 50, 0.12)',
  'No ERP': 'rgba(100, 100, 100, 0.15)',
};

// Text colors for ERP tag labels
const erpTagTextColor = {
  'Unset': 'label',
  'Top': '#ff6666',
  'Top-Pref': '#ff8888',
  'Submissive Top': '#55cccc',
  'Bottom': '#6699ff',
  'Bottom-Pref': '#88aaff',
  'Dominant Bottom': '#ffaa44',
  'Switch': '#ddcc44',
  'No ERP': '#999999',
};

// Text colors for Yes/Ask/No preference tags
const prefTagTextColor = {
  'Yes': '#55dd55',
  'Ask': '#66aaff',
  'No': '#ff6666',
};

// Text colors for gender tags
const genderTagTextColor = {
  'Female': '#ff88cc',
  'Futa': '#cc77ff',
  'Male': '#66aaff',
  'MtF': '#ffaadd',
  'FtM': '#88bbff',
  'N/B': '#aaddaa',
  'Unset': 'label',
};

export const CharacterDirectory = (props, context) => {
  const { act, data } = useBackend(context);

  const {
    personalVisibility,
    personalTag,
    personalErpTag,
    personalNonconTag,
    personalUnholyTag,
    personalExtremeTag,
    personalExtremeHarmTag,
    personalHornyAntagsTag,
    personalGenderTag,
    prefsOnly,
  } = data;

  const [overlay, setOverlay] = useLocalState(context, 'overlay', null);

  const [overwritePrefs, setOverwritePrefs] = useLocalState(context, 'overwritePrefs', true);

  return (
    <Window width={940} height={560} resizeable>
      <Window.Content scrollable>
        {(overlay && <ViewCharacter />) || (
          <Fragment>
            <Section title="Настройки">
              <LabeledList>
                <LabeledList.Item label="Видимость">
                  <Button
                    fluid
                    icon={personalVisibility ? 'eye' : 'eye-slash'}
                    content={personalVisibility ? 'Показан' : 'Скрыт'}
                    color={personalVisibility ? 'green' : 'grey'}
                    onClick={() => act('setVisible', { overwrite_prefs: overwritePrefs })}
                  />
                </LabeledList.Item>
                <LabeledList.Item label="Объявление">
                  <Button
                    fluid
                    icon="pen"
                    content="Редактировать"
                    onClick={() => act('editAd', { overwrite_prefs: overwritePrefs })}
                  />
                </LabeledList.Item>
              </LabeledList>
            </Section>
            <Collapsible title="Теги персонажа" open={false}>
              <Section>
                <LabeledList>
                  <LabeledList.Item label="Сохранить в текущий слот">
                    <Button
                      icon={overwritePrefs ? 'toggle-on' : 'toggle-off'}
                      selected={overwritePrefs}
                      content={overwritePrefs ? 'Вкл' : 'Выкл'}
                      onClick={() => prefsOnly ? act('noMind', { overwrite_prefs: overwritePrefs }) : setOverwritePrefs(!overwritePrefs)}
                    />
                  </LabeledList.Item>
                  <LabeledList.Divider />
                  <LabeledList.Item label="Пол">
                    <Button
                      fluid
                      content={personalGenderTag}
                      onClick={() => act('setGenderTag', { overwrite_prefs: overwritePrefs })}
                    />
                  </LabeledList.Item>
                  <LabeledList.Item label="Vore тег">
                    <Button
                      fluid
                      content={personalTag}
                      onClick={() => act('setTag', { overwrite_prefs: overwritePrefs })}
                    />
                  </LabeledList.Item>
                  <LabeledList.Item label="ERP тег">
                    <Button
                      fluid
                      content={personalErpTag}
                      color={erpTagTextColor[personalErpTag] ? null : undefined}
                      onClick={() => act('setErpTag', { overwrite_prefs: overwritePrefs })}
                    />
                  </LabeledList.Item>
                  <LabeledList.Item label="Изнасилование">
                    <PrefTagButton
                      value={personalNonconTag}
                      onClick={() => act('setNonconTag')}
                    />
                  </LabeledList.Item>
                  <LabeledList.Item label="Грязный секс">
                    <PrefTagButton
                      value={personalUnholyTag}
                      onClick={() => act('setUnholyTag')}
                    />
                  </LabeledList.Item>
                  <LabeledList.Item label="Жестокий секс">
                    <PrefTagButton
                      value={personalExtremeTag}
                      onClick={() => act('setExtremeTag')}
                    />
                  </LabeledList.Item>
                  <LabeledList.Item label="Очень жестокий секс">
                    <PrefTagButton
                      value={personalExtremeHarmTag}
                      onClick={() => act('setExtremeHarmTag')}
                    />
                  </LabeledList.Item>
                  <LabeledList.Item label="Хорни антаги">
                    <PrefTagButton
                      value={personalHornyAntagsTag}
                      onClick={() => act('setHornyAntagsTag')}
                    />
                  </LabeledList.Item>
                </LabeledList>
              </Section>
            </Collapsible>
            <CharacterDirectoryList />
          </Fragment>
        )}
      </Window.Content>
    </Window>
  );
};

const PrefTagButton = (props) => {
  const { value, onClick } = props;
  const color = value === 'Yes' ? 'green' : value === 'Ask' ? 'blue' : value === 'No' ? 'red' : 'grey';
  return (
    <Button
      fluid
      content={value || 'Не задано'}
      color={color}
      onClick={onClick}
    />
  );
};

const ViewCharacter = (props, context) => {
  const { act, data } = useBackend(context);
  const { directory_notes } = data;
  const [overlay, setOverlay] = useLocalState(context, 'overlay', null);

  const prefTags = [
    { name: 'Изнасилование', value: overlay.noncon_tag },
    { name: 'Хорни антаги', value: overlay.hornyantags_tag },
    { name: 'Грязный секс', value: overlay.unholy_tag },
    { name: 'Жестокий секс', value: overlay.extreme_tag },
    { name: 'Очень жестокий секс', value: overlay.extreme_harm_tag },
  ];

  const genderDisplay = overlay.gender_tag || 'Unset';

  const headshots = (overlay.headshot_links || []).filter(link => link && link.length);
  const [selectedHeadshot, setSelectedHeadshot] = useLocalState(context, 'viewHeadshot', 0);
  const safeIdx = headshots.length > 0 ? selectedHeadshot % headshots.length : 0;

  return (
    <Section
      title={overlay.name}
      buttons={<Button icon="arrow-left" content="Назад" onClick={() => setOverlay(null)} />}>
      {headshots.length > 0 && (
        <Section level={2} title="Арт" textAlign="center">
          <Box mb={1}>
            <img
              src={headshots[safeIdx]}
              style={{
                'max-width': '256px',
                'max-height': '256px',
                'object-fit': 'contain',
              }}
            />
          </Box>
          {headshots.length > 1 && (
            <Box>
              <Button
                icon="arrow-left"
                onClick={() => setSelectedHeadshot((safeIdx + headshots.length - 1) % headshots.length)}
              />
              <Box inline mx={1} bold>{safeIdx + 1} / {headshots.length}</Box>
              <Button
                icon="arrow-right"
                onClick={() => setSelectedHeadshot((safeIdx + 1) % headshots.length)}
              />
            </Box>
          )}
        </Section>
      )}
      <Section level={2} title="Информация">
        <LabeledList>
          <LabeledList.Item label="Раса">{overlay.species}</LabeledList.Item>
          <LabeledList.Item label="Пол">
            <Box inline bold color={genderTagTextColor[genderDisplay] || 'label'}>
              {genderDisplay}
            </Box>
          </LabeledList.Item>
          <LabeledList.Item label="Vore тег">{overlay.tag}</LabeledList.Item>
          <LabeledList.Item label="ERP тег">
            <Box inline bold color={erpTagTextColor[overlay.erptag] || 'label'}>
              {overlay.erptag}
            </Box>
          </LabeledList.Item>
          {prefTags.map((tag) => (
            <LabeledList.Item key={tag.name} label={tag.name}>
              <Box
                inline
                bold
                color={prefTagTextColor[tag.value] || 'label'}>
                {tag.value || 'Не задано'}
              </Box>
            </LabeledList.Item>
          ))}
        </LabeledList>
      </Section>
      <Section level={2} title="Объявление">
        <Box style={{ 'word-break': 'break-all' }} preserveWhitespace>
          {overlay.character_ad || 'Не задано.'}
        </Box>
      </Section>
      <Section level={2} title="OOC Заметки">
        <Box style={{ 'word-break': 'break-all' }} preserveWhitespace>
          {overlay.ooc_notes || 'Не задано.'}
        </Box>
      </Section>
      <Section level={2} title="Описание">
        <Box style={{ 'word-break': 'break-all' }} preserveWhitespace>
          {overlay.flavor_text || 'Не задано.'}
        </Box>
      </Section>
      <Section
        level={2}
        title="Личная заметка"
        buttons={
          <Button
            icon="pen"
            content="Редактировать"
            onClick={() => act('editNote', { target_ckey: overlay.ckey })}
          />
        }>
        <Box style={{ 'word-break': 'break-all' }} preserveWhitespace>
          {(directory_notes && directory_notes[overlay.ckey]) || 'Нет заметки.'}
        </Box>
      </Section>
    </Section>
  );
};

const CharacterDirectoryList = (props, context) => {
  const { act, data } = useBackend(context);

  const { directory, canOrbit, directory_notes } = data;

  const [sortId, _setSortId] = useLocalState(context, 'sortId', 'name');
  const [sortOrder, _setSortOrder] = useLocalState(context, 'sortOrder', 'name');
  const [overlay, setOverlay] = useLocalState(context, 'overlay', null);
  const [searchText, setSearchText] = useLocalState(context, 'searchText', '');

  const filteredDirectory = (directory || []).filter(
    (character) =>
      !searchText ||
      character.name.toLowerCase().includes(searchText.toLowerCase())
  );

  return (
    <Section title="Каталог" buttons={
      <Fragment>
        <Input
          width="180px"
          placeholder="Поиск по имени..."
          value={searchText}
          onInput={(e, value) => setSearchText(value)}
        />
        <Button icon="sync" content="Обновить" ml={1} onClick={() => act('refresh')} />
      </Fragment>
    }>
      <Table>
        <Table.Row bold>
          <SortButton id="name">Name</SortButton>
          <SortButton id="species">Species</SortButton>
          <SortButton id="gender_tag">Gender</SortButton>
          <SortButton id="tag">Vore</SortButton>
          <SortButton id="erptag">ERP</SortButton>
          <SortButton id="noncon_tag">Non-Con</SortButton>
          <SortButton id="unholy_tag">Unholy</SortButton>
          <SortButton id="extreme_tag">Extreme</SortButton>
          <SortButton id="extreme_harm_tag">Ex. Harm</SortButton>
          <SortButton id="hornyantags_tag">H. Antags</SortButton>
          <Table.Cell collapsing textAlign="right">
            Ad
          </Table.Cell>
        </Table.Row>
        {filteredDirectory
          .sort((a, b) => {
            const i = sortOrder ? 1 : -1;
            return a[sortId].localeCompare(b[sortId]) * i;
          })
          .map((character, i) => (
            <Table.Row
              key={i}
              style={{
                'background-color': erpTagRowColor[character.erptag] || 'transparent',
              }}>
              <Table.Cell p={1}>
                {canOrbit ? (
                  <Button
                    color="transparent"
                    icon="ghost"
                    tooltip={directory_notes && directory_notes[character.ckey]
                      ? directory_notes[character.ckey]
                      : "Следовать"}
                    tooltipPosition="right"
                    content={character.name}
                    onClick={() => act("orbit", { ref: character.ref })}
                  />
                ) : directory_notes && directory_notes[character.ckey] ? (
                  <Tooltip content={directory_notes[character.ckey]} position="right">
                    <span>{character.name}</span>
                  </Tooltip>
                ) : character.name}
              </Table.Cell>
              <Table.Cell>{character.species}</Table.Cell>
              <Table.Cell>
                <Box inline bold color={genderTagTextColor[character.gender_tag]}>
                  {character.gender_tag}
                </Box>
              </Table.Cell>
              <Table.Cell>{character.tag}</Table.Cell>
              <Table.Cell>
                <Box inline bold color={erpTagTextColor[character.erptag]}>
                  {character.erptag}
                </Box>
              </Table.Cell>
              <Table.Cell>
                <Box inline bold color={prefTagTextColor[character.noncon_tag]}>
                  {character.noncon_tag}
                </Box>
              </Table.Cell>
              <Table.Cell>
                <Box inline bold color={prefTagTextColor[character.unholy_tag]}>
                  {character.unholy_tag}
                </Box>
              </Table.Cell>
              <Table.Cell>
                <Box inline bold color={prefTagTextColor[character.extreme_tag]}>
                  {character.extreme_tag}
                </Box>
              </Table.Cell>
              <Table.Cell>
                <Box inline bold color={prefTagTextColor[character.extreme_harm_tag]}>
                  {character.extreme_harm_tag}
                </Box>
              </Table.Cell>
              <Table.Cell>
                <Box inline bold color={prefTagTextColor[character.hornyantags_tag]}>
                  {character.hornyantags_tag}
                </Box>
              </Table.Cell>
              <Table.Cell collapsing textAlign="right">
                <Button
                  onClick={() => setOverlay(character)}
                  color="transparent"
                  icon="sticky-note"
                  mr={1}
                  content="Открыть"
                />
              </Table.Cell>
            </Table.Row>
          ))}
      </Table>
    </Section>
  );
};

const SortButton = (props, context) => {
  const { act, data } = useBackend(context);

  const { id, children } = props;

  // Hey, same keys mean same data~
  const [sortId, setSortId] = useLocalState(context, 'sortId', 'name');
  const [sortOrder, setSortOrder] = useLocalState(context, 'sortOrder', 'name');

  return (
    <Table.Cell collapsing>
      <Button
        width="100%"
        color={sortId !== id && 'transparent'}
        onClick={() => {
          if (sortId === id) {
            setSortOrder(!sortOrder);
          } else {
            setSortId(id);
            setSortOrder(true);
          }
        }}>
        {children}
        {sortId === id && <Icon name={sortOrder ? 'sort-up' : 'sort-down'} ml="0.25rem;" />}
      </Button>
    </Table.Cell>
  );
};
