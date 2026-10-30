import { useBackend } from '../../../backend';
import { Box, Button, Icon, NoticeBox, Section, Stack } from '../../../components';
import { TabDataMissing } from '../components';

interface InnateFeature {
  id: string;
  name: string;
  desc: string;
  primary: boolean;
  selected: boolean;
  available: boolean;
  requirements: { text: string; met: boolean }[];
}

interface InnateContext {
  innateTab?: { balance: number; items: InnateFeature[] };
}

export const InnateTab = () => {
  const { act, data } = useBackend<InnateContext>();
  const tab = data.innateTab;
  if (!tab) {
    return <TabDataMissing title="Врожденное" />;
  }
  return (
    <Stack vertical>
      <Stack.Item>
        <NoticeBox>
          Можно выбрать одну основную особенность и любое число дополнительных.
          Все условия проверяются повторно при создании персонажа.
          Доступно очков квирков: {tab.balance}.
        </NoticeBox>
      </Stack.Item>
      {tab.items.map(feature => (
        <Stack.Item key={feature.id}>
          <Section title={feature.name} buttons={(
            <Button
              icon={feature.selected ? 'check-square' : 'square'}
              selected={feature.selected}
              disabled={!feature.selected && !feature.available}
              onClick={() => act('innate_toggle', { id: feature.id })}>
              {feature.selected ? 'Убрать' : 'Выбрать'}
            </Button>
          )}>
            <Box bold mb={1} color={feature.primary ? 'purple' : 'label'}>
              {feature.primary ? 'Основная' : 'Дополнительная'}
            </Box>
            <Box mb={1}>{feature.desc}</Box>
            {feature.requirements.map((requirement, index) => (
              <Box key={index} color={requirement.met ? 'good' : 'bad'}>
                <Icon name={requirement.met ? 'check' : 'times'} mr={1} />
                {requirement.text}
              </Box>
            ))}
            {feature.selected && !feature.available && (
              <NoticeBox danger mt={1}>
                Условия больше не выполнены. Исправьте их или уберите
                особенность перед входом в раунд.
              </NoticeBox>
            )}
          </Section>
        </Stack.Item>
      ))}
    </Stack>
  );
};
