import { useBackend } from '../backend';
import { Box, Button, Grid, LabeledList, ProgressBar, Section } from '../components';
import { Window } from '../layouts';

export const DnaVault = (props) => {
  const { act, data } = useBackend();
  const {
    completed,
    used,
    choiceA,
    choiceB,
    dna,
    dna_max,
    plants,
    plants_max,
    animals,
    animals_max,
  } = data;
  return (
    <Window
      width={350}
      height={400}>
      <Window.Content>
        <Section title="База данных ДНК хранилища">
          <LabeledList>
            <LabeledList.Item label="ДНК: гуманоиды">
              <ProgressBar
                value={dna / dna_max}>
                {dna + ' / ' + dna_max + ' образцов'}
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="ДНК: растения">
              <ProgressBar
                value={plants / plants_max}>
                {plants + ' / ' + plants_max + ' образцов'}
              </ProgressBar>
            </LabeledList.Item>
            <LabeledList.Item label="ДНК: животные">
              <ProgressBar
                value={animals / animals_max}>
                {animals + ' / ' + animals_max + ' образцов'}
              </ProgressBar>
            </LabeledList.Item>
          </LabeledList>
        </Section>
        {!!(completed && !used) && (
          <Section title="Персональная генная терапия">
            <Box
              bold
              textAlign="center"
              mb={1}>
              Доступные курсы генной терапии
            </Box>
            <Grid>
              <Grid.Column>
                <Button
                  fluid
                  bold
                  content={choiceA}
                  textAlign="center"
                  onClick={() => act('gene', {
                    choice: choiceA,
                  })} />
              </Grid.Column>
              <Grid.Column>
                <Button
                  fluid
                  bold
                  content={choiceB}
                  textAlign="center"
                  onClick={() => act('gene', {
                    choice: choiceB,
                  })} />
              </Grid.Column>
            </Grid>
          </Section>
        )}
      </Window.Content>
    </Window>
  );
};
