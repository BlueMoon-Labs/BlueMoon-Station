import { map } from 'common/collections';

import { useBackend, useLocalState } from '../backend';
import { Box, Button, Collapsible, Grid, Input, LabeledList, NoticeBox, Section, Stack, Table } from '../components';
import { Window } from '../layouts';

export const PandemicBeakerDisplay = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    has_beaker,
    beaker_empty,
    has_blood,
    blood,
  } = data;
  const cant_empty = !has_beaker || beaker_empty;
  return (
    <Section
      title="Beaker"
      buttons={(
        <>
          <Button
            icon="times"
            content="Empty and Eject"
            color="bad"
            disabled={cant_empty}
            onClick={() => act('empty_eject_beaker')} />
          <Button
            icon="trash"
            content="Empty"
            disabled={cant_empty}
            onClick={() => act('empty_beaker')} />
          <Button
            icon="eject"
            content="Eject"
            disabled={!has_beaker}
            onClick={() => act('eject_beaker')} />
        </>
      )}>
      {has_beaker ? (
        !beaker_empty ? (
          has_blood ? (
            <LabeledList>
              <LabeledList.Item label="Blood DNA">
                {(blood && blood.dna) || 'Unknown'}
              </LabeledList.Item>
              <LabeledList.Item label="Blood Type">
                {(blood && blood.type) || 'Unknown'}
              </LabeledList.Item>
            </LabeledList>
          ) : (
            <Box color="bad">
              No blood detected
            </Box>
          )
        ) : (
          <Box color="bad">
            Beaker is empty
          </Box>
        )
      ) : (
        <NoticeBox>
          No beaker loaded
        </NoticeBox>
      )}
    </Section>
  );
};

export const PandemicDiseaseDisplay = (props, context) => {
  const { act, data } = useBackend(context);
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
                            content="Create culture bottle"
                            disabled={!is_ready}
                            onClick={() => act('create_culture_bottle', {
                              index: virus.index,
                            })} />
                        )}>
                        <Grid>
                          <Grid.Column>
                            {virus.description}
                          </Grid.Column>
                          <Grid.Column>
                            <LabeledList>
                              <LabeledList.Item label="Agent">
                                {virus.agent}
                              </LabeledList.Item>
                              <LabeledList.Item label="Spread">
                                {virus.spread}
                              </LabeledList.Item>
                              <LabeledList.Item label="Possible Cure">
                                {virus.cure}
                              </LabeledList.Item>
                            </LabeledList>
                          </Grid.Column>
                        </Grid>
                        {!!virus.is_adv && (
                          <>
                            <Section
                              title="Statistics"
                              level={2}>
                              <Grid>
                                <Grid.Column>
                                  <LabeledList>
                                    <LabeledList.Item label="Resistance">
                                      {virus.resistance}
                                    </LabeledList.Item>
                                    <LabeledList.Item label="Stealth">
                                      {virus.stealth}
                                    </LabeledList.Item>
                                  </LabeledList>
                                </Grid.Column>
                                <Grid.Column>
                                  <LabeledList>
                                    <LabeledList.Item label="Stage speed">
                                      {virus.stage_speed}
                                    </LabeledList.Item>
                                    <LabeledList.Item label="Transmissibility">
                                      {virus.transmission}
                                    </LabeledList.Item>
                                  </LabeledList>
                                </Grid.Column>
                              </Grid>
                            </Section>
                            <Section
                              title="Symptoms"
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

export const PandemicSymptomDisplay = (props, context) => {
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
          Neutered
        </Box>
      )}>
      <Grid>
        <Grid.Column size={2}>
          {desc}
        </Grid.Column>
        <Grid.Column>
          <LabeledList>
            <LabeledList.Item label="Level">
              {level}
            </LabeledList.Item>
            <LabeledList.Item label="Resistance">
              {resistance}
            </LabeledList.Item>
            <LabeledList.Item label="Stealth">
              {stealth}
            </LabeledList.Item>
            <LabeledList.Item label="Stage Speed">
              {stage_speed}
            </LabeledList.Item>
            <LabeledList.Item label="Transmission">
              {transmission}
            </LabeledList.Item>
          </LabeledList>
        </Grid.Column>
      </Grid>
      {thresholds.length > 0 && (
        <Section
          title="Thresholds"
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

export const PandemicAntibodyDisplay = (props, context) => {
  const { act, data } = useBackend(context);
  const resistances = data.resistances || [];
  return (
    <Section title="Antibodies">
      {resistances.length > 0 ? (
        <LabeledList>
          {resistances.map(resistance => (
            <LabeledList.Item
              key={resistance.name}
              label={resistance.name}>
              <Button
                icon="eye-dropper"
                content="Create vaccine bottle"
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
          No antibodies detected.
        </Box>
      )}
    </Section>
  );
};

export const PandemicCustomVirus = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    tier,
    custom_cooldown,
    all_symptoms = [],
  } = data;
  const [searchText, setSearchText] = useLocalState(context, 'searchText', '');
  const [selectedSymptoms, setSelectedSymptoms] = useLocalState(context, 'selectedSymptoms', []);

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
      title="Custom Strain Synthesis (Tier 4+)"
      buttons={(
        <Button
          icon="flask"
          content="Synthesize"
          disabled={custom_cooldown > 0 || selectedSymptoms.length === 0}
          onClick={() => {
            act('create_custom_virus', { symptom_ids: selectedSymptoms });
            setSelectedSymptoms([]);
          }}
        />
      )}>
      {custom_cooldown > 0 && (
        <NoticeBox>
          Sequencer Cooling Down: {Math.ceil(custom_cooldown / 10)}s
        </NoticeBox>
      )}
      <Input
        placeholder="Search Symptoms..."
        value={searchText}
        onInput={(e, value) => setSearchText(value)}
        fluid
        mb={1}
      />
      <Section title="Selected Symptoms" level={2}>
        {selectedSymptoms.length === 0 ? (
          <Box color="label">None selected</Box>
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
      <Section title="Available Symptoms" level={2}>
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
                        content={`${s.name} (L${s.level})`}
                        icon={selectedSymptoms.includes(s.id) ? "check" : "plus"}
                        color={selectedSymptoms.includes(s.id) ? "good" : "default"}
                        onClick={() => toggleSymptom(s.id)}
                        tooltip={`R:${s.resistance} S:${s.stealth} Sp:${s.stage_speed} T:${s.transmission}`}
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

export const Pandemic = (props, context) => {
  const { data } = useBackend(context);
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
            <PandemicDiseaseDisplay />
            <PandemicAntibodyDisplay />
          </>
        )}
      </Window.Content>
    </Window>
  );
};
