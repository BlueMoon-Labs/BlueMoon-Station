import { useBackend, useSharedState } from '../backend';
import { Box, Button, Dimmer, Icon, LabeledList, ProgressBar, Section, Tabs } from '../components';
import { Window } from '../layouts';

export const Limbgrower = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    reagents = [],
    total_reagents,
    max_reagents,
    categories = [],
    busy,
    disk = [],
  } = data;
  const [tab, setTab] = useSharedState(
    context, 'category', categories[0]?.name);
  const designList = categories
    .find(category => category.name === tab)
    ?.designs;

  return (
    <Window
      title="Limb Grower"
      width={600}
      height={760}>
      {!!busy && (
        <Dimmer fontSize="32px">
          <Icon name="cog" spin={1} />
          {' Создание...'}
        </Dimmer>
      )}
      <Window.Content overflow="auto">
        <Section title="Дата-диск" buttons={
          <Button
            content="Извлечь диск"
            icon="eject"
            onClick={() => act('eject_disk')}
            disabled={!disk['disk']}
          />
        }>
          {disk['name'] ? (
            <div>
              Containing data for {disk['name']},<br />
              Attempting to create genitalia will use the disk&apos;s data.
              Any Synthetic Frameworks created will
              overwrite the race category selected.
            </div>
          ) : disk['disk'] ? "Отсутствуют данные." : "Отсутствует диск."}
        </Section>
        <Section title="Запас реагентов">
          <Box mb={1}>
            {/* Total_reagents could be null or undefined, so let's be safe */
              `Всего реагентов / Максимум реагентов:
            ${total_reagents ? total_reagents : 0}u / ${max_reagents}u`
            }
            <ProgressBar value={(total_reagents && max_reagents)
              ? (total_reagents / max_reagents) : 0} />
          </Box>
          <LabeledList>
            {reagents.map(reagent => (
              <LabeledList.Item
                key={reagent.reagent_name}
                label={reagent.reagent_name}
                buttons={(
                  <Button.Confirm
                    key={`remove_${reagent.reagent_name}`}
                    textAlign="center"
                    content="Удалить реагент"
                    icon="fill-drip"
                    color="bad"
                    onClick={() => {
                      act('empty_reagent', { reagent_type: reagent.reagent_type });

                    }} />
                )}>
                {reagent.reagent_amount}u
              </LabeledList.Item>
            ))}
          </LabeledList>
        </Section>
        <Section title="Органы">
          <Tabs>
            {categories.map(category => (
              <Tabs.Tab
                fluid
                key={category.name}
                selected={tab === category.name}
                onClick={() => setTab(category.name)}>
                {category.name}
              </Tabs.Tab>
            ))}
          </Tabs>
          <LabeledList>
            {designList.map(design => (
              <LabeledList.Item
                key={design.name}
                label={design.name}
                buttons={(
                  <Button
                    content="Создать"
                    onClick={() => act('make_limb', {
                      design_id: design.id,
                      active_tab: design.parent_category,
                    })} />
                )}>
                {design.needed_reagents.map(reagent => (
                  <Box key={reagent.name}>
                    {reagent.name}: {reagent.amount}u
                  </Box>
                ))}
              </LabeledList.Item>
            ))}
          </LabeledList>
        </Section>
      </Window.Content>
    </Window>
  );
};
