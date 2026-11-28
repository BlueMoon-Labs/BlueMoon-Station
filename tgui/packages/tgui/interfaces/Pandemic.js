import { map } from 'common/collections';
import { useState } from 'react';

import { useBackend } from '../backend';
import { Box, Button, Collapsible, Grid, Input, LabeledList, NoticeBox, Section, Stack, Table } from '../components';
import { Window } from '../layouts';

const bloodDnaLabels = new Map([
  ['none', 'Нет данных'],
  ['SYNTHESIZED', 'Синтезирована'],
  ['REPLICATED', 'Скопирована'],
]);

const diseaseDetailsLabels = new Map([
  ['none', '—'],
  ['None', 'Нет'],
  ['Unknown', 'Неизвестно'],
  ['Blood', 'Через кровь'],
  ['Fluids', 'Через биологические жидкости'],
  ['On contact', 'При контакте'],
  ['Airborne', 'Воздушно-капельный'],
  ['advance microbes', 'Модифицированные микроорганизмы'],
  ['An engineered disease which can contain a multitude of symptoms.',
    'Искусственно созданное заболевание, которое может проявляться множеством симптомов.'],
]);

export const PandemicBeakerDisplay = (props) => {
  const { act, data } = useBackend();
  const {
    has_beaker,
    beaker_empty,
    has_blood,
    blood,
  } = data;
  const { dna, type } = blood || {};
  const cant_empty = !has_beaker || beaker_empty;
  return (
    <Section
      title="Ёмкость"
      buttons={(
        <>
          <Button
            icon="times"
            content="Опорожнить и извлечь"
            color="bad"
            disabled={cant_empty}
            onClick={() => act('empty_eject_beaker')} />
          <Button
            icon="trash"
            content="Опорожнить"
            disabled={cant_empty}
            onClick={() => act('empty_beaker')} />
          <Button
            icon="eject"
            content="Извлечь"
            disabled={!has_beaker}
            onClick={() => act('eject_beaker')} />
        </>
      )}>
      {has_beaker ? (
        !beaker_empty ? (
          has_blood ? (
            <LabeledList>
              <LabeledList.Item label="ДНК крови">
                {bloodDnaLabels.get(dna) || dna || 'Неизвестно'}
              </LabeledList.Item>
              <LabeledList.Item label="Группа крови">
                {type === 'none' ? 'Нет данных' : type || 'Неизвестно'}
              </LabeledList.Item>
            </LabeledList>
          ) : (
            <Box color="bad">
              Кровь не обнаружена.
            </Box>
          )
        ) : (
          <Box color="bad">
            Ёмкость пуста.
          </Box>
        )
      ) : (
        <NoticeBox>
          Ёмкость не установлена.
        </NoticeBox>
      )}
    </Section>
  );
};

export const PandemicDiseaseDisplay = (props) => {
  const { act, data } = useBackend();
  const {
    is_ready,
  } = data;
  const viruses = data.viruses || [];
  return (
    <Stack vertical fill>
      {(() => {
        const rows = [];
        for (let i = 0; i < viruses.length; i += 3) {
          const chunk = viruses.slice(i, i + 3);
          rows.push(
            <Stack.Item key={i}>
              <Grid>
                {chunk.map(virus => {
                  const symptoms = virus.symptoms || [];
                  return (
                    <Grid.Column key={virus.name} size={4}>
                      <Section
                        title={virus.can_rename ? (
                          <Input
                            value={virus.name}
                            onChange={(e, value) => act('rename_disease', {
                              index: virus.index,
                              name: value,
                            })} />
                        ) : (
                          virus.name
                        )}
                        buttons={(
                          <Button
                            icon="flask"
                            content="Создать флакон с культурой"
                            disabled={!is_ready}
                            onClick={() => act('create_culture_bottle', {
                              index: virus.index,
                            })} />
                        )}>
                        <Grid>
                          <Grid.Column>
                            {diseaseDetailsLabels.get(virus.description) || virus.description}
                          </Grid.Column>
                          <Grid.Column>
                            <LabeledList>
                              <LabeledList.Item label="Возбудитель">
                                {diseaseDetailsLabels.get(virus.agent) || virus.agent}
                              </LabeledList.Item>
                              <LabeledList.Item label="Путь передачи">
                                {diseaseDetailsLabels.get(virus.spread) || virus.spread}
                              </LabeledList.Item>
                              <LabeledList.Item label="Возможное лекарство">
                                {virus.cure === 'none' ? '—' : virus.cure}
                              </LabeledList.Item>
                            </LabeledList>
                          </Grid.Column>
                        </Grid>
                        {!!virus.is_adv && (
                          <>
                            <Section
                              title="Характеристики"
                              level={2}>
                              <Grid>
                                <Grid.Column>
                                  <LabeledList>
                                    <LabeledList.Item label="Стойкость">
                                      {virus.resistance}
                                    </LabeledList.Item>
                                    <LabeledList.Item label="Скрытность">
                                      {virus.stealth}
                                    </LabeledList.Item>
                                  </LabeledList>
                                </Grid.Column>
                                <Grid.Column>
                                  <LabeledList>
                                    <LabeledList.Item label="Скорость стадий">
                                      {virus.stage_speed}
                                    </LabeledList.Item>
                                    <LabeledList.Item label="Заразность">
                                      {virus.transmission}
                                    </LabeledList.Item>
                                  </LabeledList>
                                </Grid.Column>
                              </Grid>
                            </Section>
                            <Section
                              title="Симптомы"
                              level={2}>
                              {symptoms.map(symptom => (
                                <Collapsible
                                  key={symptom.name}
                                  title={symptom.name}>
                                  <Section>
                                    <PandemicSymptomDisplay symptom={symptom} />
                                  </Section>
                                </Collapsible>
                              ))}
                            </Section>
                          </>
                        )}
                      </Section>
                    </Grid.Column>
                  );
                })}
              </Grid>
            </Stack.Item>
          );
        }
        return rows;
      })()}
    </Stack>
  );
};

export const PandemicSymptomDisplay = (props) => {
  const { symptom } = props;
  const {
    name,
    desc,
    stealth,
    resistance,
    stage_speed,
    transmission,
    level,
    neutered,
  } = symptom;
  const thresholds = map((desc, label) => ({ desc, label }))(
    symptom.threshold_desc || {});
  return (
    <Section
      title={name}
      level={2}
      buttons={!!neutered && (
        <Box
          bold
          color="bad">
          Подавлен
        </Box>
      )}>
      <Grid>
        <Grid.Column size={2}>
          {desc}
        </Grid.Column>
        <Grid.Column>
          <LabeledList>
            <LabeledList.Item label="Уровень">
              {level}
            </LabeledList.Item>
            <LabeledList.Item label="Стойкость">
              {resistance}
            </LabeledList.Item>
            <LabeledList.Item label="Скрытность">
              {stealth}
            </LabeledList.Item>
            <LabeledList.Item label="Скорость стадий">
              {stage_speed}
            </LabeledList.Item>
            <LabeledList.Item label="Заразность">
              {transmission}
            </LabeledList.Item>
          </LabeledList>
        </Grid.Column>
      </Grid>
      {thresholds.length > 0 && (
        <Section
          title="Пороговые эффекты"
          level={3}>
          <LabeledList>
            {thresholds.map(threshold => {
              return (
                <LabeledList.Item
                  key={threshold.label}
                  label={threshold.label}>
                  {threshold.desc}
                </LabeledList.Item>
              );
            })}
          </LabeledList>
        </Section>
      )}
    </Section>
  );
};

export const PandemicAntibodyDisplay = (props) => {
  const { act, data } = useBackend();
  const resistances = data.resistances || [];
  return (
    <Section title="Антитела">
      {resistances.length > 0 ? (
        <LabeledList>
          {resistances.map(resistance => (
            <LabeledList.Item
              key={resistance.name}
              label={resistance.name}>
              <Button
                icon="eye-dropper"
                content="Создать флакон с вакциной"
                disabled={!data.is_ready}
                onClick={() => act('create_vaccine_bottle', {
                  index: resistance.id,
                })} />
            </LabeledList.Item>
          ))}
        </LabeledList>
      ) : (
        <Box
          bold
          color="bad"
          mt={1}>
          Антитела не обнаружены.
        </Box>
      )}
    </Section>
  );
};

export const PandemicCustomVirus = (props) => {
  const { act, data } = useBackend();
  const {
    tier,
    custom_cooldown,
    all_symptoms = [],
  } = data;
  const [searchText, setSearchText] = useState('');
  const [selectedSymptoms, setSelectedSymptoms] = useState([]);

  if (tier < 4) return null;

  const toggleSymptom = (id) => {
    if (selectedSymptoms.includes(id)) {
      setSelectedSymptoms(selectedSymptoms.filter(s => s !== id));
    } else {
      if (selectedSymptoms.length >= 6) return;
      setSelectedSymptoms([...selectedSymptoms, id]);
    }
  };

  const filteredSymptoms = all_symptoms.filter(s =>
    s.name.toLowerCase().includes(searchText.toLowerCase())
  );

  return (
    <Section
      title="Синтез собственного штамма (ур. 4+)"
      buttons={(
        <Button
          icon="flask"
          content="Синтезировать"
          disabled={custom_cooldown > 0 || selectedSymptoms.length === 0}
          onClick={() => {
            act('create_custom_virus', { symptom_ids: selectedSymptoms });
            setSelectedSymptoms([]);
          }}
        />
      )}>
      {custom_cooldown > 0 && (
        <NoticeBox>
          Охлаждение секвенатора: {Math.ceil(custom_cooldown / 10)} с
        </NoticeBox>
      )}
      <Input
        placeholder="Поиск симптомов…"
        value={searchText}
        onInput={(e, value) => setSearchText(value)}
        fluid
        mb={1}
      />
      <Section title="Выбранные симптомы" level={2}>
        {selectedSymptoms.length === 0 ? (
          <Box color="label">Нет выбранных симптомов</Box>
        ) : (
          selectedSymptoms.map(id => {
            const s = all_symptoms.find(sym => sym.id === id);
            return (
              <Button
                key={id}
                content={s ? s.name : id}
                icon="minus"
                color="bad"
                onClick={() => toggleSymptom(id)}
                mr={0.5}
                mb={0.5}
              />
            );
          })
        )}
      </Section>
      <Section title="Доступные симптомы" level={2}>
        <Table>
          {(() => {
            const rows = [];
            for (let i = 0; i < filteredSymptoms.length; i += 3) {
              const chunk = filteredSymptoms.slice(i, i + 3);
              rows.push(
                <Table.Row key={i}>
                  {chunk.map(s => (
                    <Table.Cell key={s.id} style={{ width: '33.33%' }}>
                      <Button
                        fluid
                        content={`${s.name} (ур. ${s.level})`}
                        icon={selectedSymptoms.includes(s.id) ? "check" : "plus"}
                        color={selectedSymptoms.includes(s.id) ? "good" : "default"}
                        onClick={() => toggleSymptom(s.id)}
                        tooltip={`Стойкость: ${s.resistance}; скрытность: ${s.stealth}; `
                          + `скорость стадий: ${s.stage_speed}; заразность: ${s.transmission}`}
                        disabled={!selectedSymptoms.includes(s.id) && selectedSymptoms.length >= 6}
                      />
                    </Table.Cell>
                  ))}
                </Table.Row>
              );
            }
            return rows;
          })()}
        </Table>
      </Section>
    </Section>
  );
};

export const Pandemic = (props) => {
  const { data } = useBackend();
  return (
    <Window
      width={520}
      height={550}>
      <Window.Content overflow="auto">
        <PandemicBeakerDisplay />
        {data.tier >= 4 && (
          <PandemicCustomVirus />
        )}
        {!!data.has_blood && (
          <>
            <PandemicAntibodyDisplay />
            <PandemicDiseaseDisplay />
          </>
        )}
      </Window.Content>
    </Window>
  );
};
