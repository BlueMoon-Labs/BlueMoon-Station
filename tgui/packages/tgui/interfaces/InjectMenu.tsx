import { useBackend } from '../backend';
import {
  BlockQuote,
  Button,
  Divider,
  Flex,
  ProgressBar,
  Section,
} from '../components';
import { Window } from '../layouts';

type InjectMenuList = {
  subject: string;
  reagents: Reagent[];
  cooldown_remaining: number;
  evolve_poins: number;
  cost: number;
  amount: number;
};

type Reagent = {
  name: string;
};

export const InjectMenu = () => {
  const { act, data } = useBackend<InjectMenuList>();

  return (
    <Window width={500} height={300}>
      <Window.Content scrollable>
        <Section
          fill={false}
          style={{ maxWidth: '100%' }}
          title={`Ввод реагентов в ${data.subject}`}>
          <BlockQuote>Шкала очков эволюции</BlockQuote>

          <ProgressBar
            ranges={{
              good: [0.6, 1],
              average: [0.2, 0.6],
              bad: [-Infinity, 0.2],
            }}
            value={data.evolve_poins}
          />

          <Divider />
          {data.cooldown_remaining > 0 && (
            <BlockQuote>Следующая инъекция через {Math.ceil(data.cooldown_remaining)} с.</BlockQuote>
          )}

          <BlockQuote>Доступные реагенты:</BlockQuote>

          <Flex direction="row" wrap="wrap">
            {data.reagents.map((reagent) => (
              <Button
                key={reagent.name}
                disabled={data.cooldown_remaining > 0 || data.evolve_poins < data.cost}
                onClick={() =>
                  act('inject', { reagent_name: reagent.name })
                }
                style={{
                  width: 'calc(30% - 4px)',
                  margin: '2px',
                  flexGrow: 0,
                }}>
                {reagent.name} {data.amount}u
              </Button>
            ))}
          </Flex>
        </Section>
      </Window.Content>
    </Window>
  );
};
