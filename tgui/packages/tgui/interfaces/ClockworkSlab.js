/**
 * @file
 * @copyright 2021 LetterN (https://github.com/LetterN)
 * @author Original LetterN (https://github.com/LetterN)
 * @author Changes arturlang
 * @license MIT
 */

import { map } from 'common/collections';
import { createSearch } from 'common/string';
import { Fragment } from 'inferno';

import { useBackend, useLocalState, useSharedState } from '../backend';
import { Box, Button, Divider, Input, NoticeBox, Section, Table, Tabs } from '../components';
import { Window } from '../layouts';

const MAX_SEARCH_RESULTS = 25;
let REC_RATVAR = "";
// You may ask "why is this not inside ClockworkSlab"
// It's because cslab gets called every time. Lag is bad.
for (let index = 0; index < Math.min(Math.random()*100); index++) {
  REC_RATVAR += "HONOR RATVAR ";
}

export const ClockworkSlab = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    recollection = true,
    scripture = {},
    tier_infos = {},
    category_infos = [],
    power = "0 W",
  } = data;
  const defaultTab = category_infos[0]?.name || 'Постройки';
  const [
    tab,
    setTab,
  ] = useSharedState(context, 'tab', defaultTab);

  const categoryInfo = category_infos.find(cat => cat.name === tab) || {};

  const [
    searchText,
    setSearchText,
  ] = useLocalState(context, 'searchText', '');

  const testSearch = createSearch(searchText, script => {
    return script.name + script.descname;
  });

  let bucketOfScriptures = [];
  // merge it, no need to throw a var.

  const scriptInTab = (searchText.length > 0)
    // Flatten all categories and apply search to it
    // truthy because WE DO NOT WANT TO RETURN THIS!
    && !!map((v, k) => {
      bucketOfScriptures = bucketOfScriptures.concat(v);
    })(scripture)
    && bucketOfScriptures.filter(testSearch)
      .filter((item, i) => i < MAX_SEARCH_RESULTS)
    // Return the default one
    || scripture[tab]
    || null; // this is nullable, it's recommended that you null it.

  return (
    <Window
      theme="clockcult"
      width={800}
      height={420}>
      <Window.Content overflow="auto">
        {recollection ? ( // tutorial
          <CSTutorial />
        ) : (
          <Section
            title="Энергия"
            buttons={(
              <Fragment>
                Поиск
                <Input
                  autoFocus
                  value={searchText}
                  onInput={(e, value) => setSearchText(value)}
                  mx={1} />
                <Button
                  icon="book"
                  tooltip={"Обучение"}
                  tooltipPosition={"left"}
                  onClick={() => act('toggle')}>
                  Память
                </Button>
              </Fragment>
            )}>
            <b>{power}</b> энергии доступно для писаний
            и других потребителей.
            <Section level={2}>
              <Tabs>
                {(category_infos.length ? category_infos : map((scriptures, name) => ({ name }))(scripture)).map(cat => (
                  <Tabs.Tab
                    key={cat.name}
                    selected={tab === cat.name}
                    onClick={() => setTab(cat.name)}>
                    {cat.name} ({scripture[cat.name]?.length || 0})
                  </Tabs.Tab>
                ))}
              </Tabs>
              {categoryInfo.desc && (
                <Box as={'span'} textColor={'#dab44d'} italic>
                  {categoryInfo.desc}
                </Box>
              )}
              <br />
              {map((info, tier) => (
                <Box
                  key={tier}
                  as={'span'}
                  textColor={info.ready ? '#BE8700' : '#888888'}
                  bold={!!info.ready}
                  italic={!info.ready}>
                  <b>{tier}:</b> {info.ready
                    ? "Эти писания уже открыты."
                    : info.requirement}
                  <br />
                </Box>
              ))(tier_infos)}
              <br />
              <Box as={'span'} textColor={'#DAAA18'}>
                <b>Жёлтые</b> — постройки и база.
              </Box>
              <br />
              <Box as={'span'} textColor={'#6E001A'}>
                <b>Красные</b> — атака и бой.
              </Box>
              <br />
              <Box as={'span'} textColor={'#1E8CE1'}>
                <b>Синие</b> — лечение и защита.
              </Box>
              <br />
              <Box as={'span'} textColor={'#AF0AAF'}>
                <b>Фиолетовые</b> — особые, но важные.
              </Box>
              <br />
              <Box as={'span'} textColor={'#DAAA18'} italic>
                <i>Курсив</i> — важно для победы.
              </Box>
              <Divider />
              <Table>
                <CSScripture scriptInTab={scriptInTab} />
              </Table>
            </Section>
          </Section>
        )}
      </Window.Content>
    </Window>
  );
};

export const CSScripture = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    power_unformatted = 0,
    tier_infos = {},
  } = data;
  const {
    scriptInTab = [],
  } = props;

  return (
    scriptInTab?.length > 0 ? scriptInTab.map(script => (
      <Table.Row
        key={script.name}
        className="candystripe">
        <Table.Cell
          italic={!!script?.important}
          color={script.fontcolor}>
          <b>
            {script.name}
          </b>
          {`
              ${script.descname}
              ${script.invokers || ''}
            `}
        </Table.Cell>
        <Table.Cell
          collapsing
          textAlign="right">
          <Button
            disabled={
              script.required_unformatted > power_unformatted
              || !(tier_infos[script.tier]?.ready)
            }
            tooltip={[
              script.tip,
              !(tier_infos[script.tier]?.ready) && tier_infos[script.tier]?.requirement,
            ].filter(Boolean).join('\n\n')}
            tooltipPosition={'left'}
            onClick={() => act('recite', {
              'script': script.type,
            })} >
            {`Прочесть ${script.required}`}
          </Button>
        </Table.Cell>
        <Table.Cell
          collapsing
          textAlign="center">
          <Button
            fluid
            disabled={!script.quickbind}
            onClick={() => act('bind', {
              'script': script.type,
            })}>
            {script.bound ? (
              `Отвязать ${script.bound}`
            ) : (
              'Быстрая'
            )}
          </Button>
        </Table.Cell>
      </Table.Row>
    )) : (
      <Box
        as="span"
        textColor={'#BE8700'}
        fontSize={2.3}>
        Пусто!
      </Box>
    )
  );
};

export const CSTutorial = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    recollection_categories = [],
    rec_section = null,
    rec_binds = [],
    HONOR_RATVAR = false, // is ratvar free yet?
  } = data;
  return (
    <Section
      title="Память"
      buttons={(
        <Button
          icon="cog"
          tooltipPosition={"left"}
          onClick={() => act('toggle')}>
          Писания
        </Button>
      )}>
      <Box>
        {HONOR_RATVAR ? (
          <Box
            as="span"
            textColor="#BE8700"
            fontSize={2}
            bold>
            {REC_RATVAR}
          </Box>
        ) : (
          <>
            <Box
              as="span"
              textColor="#BE8700"
              fontSize={2} // 2rem
              bold>
              Chetr nyy hagehguf naq ubabe Ratvar.
            </Box>
            <NoticeBox warning>
              ВНИМАНИЕ: Информация устарела.
              Читайте гайд в рюкзаке или вики.
            </NoticeBox>
            Архивы Ратвара, Часового Судии. Здесь — советы
            для слуг, что делать дальше и как служить
            мастеру. Загляните сюда, если застряли.
            <br /> <br />
            <NoticeBox info>
              Servant, Cache, Slab и прочие термины
              пишутся с большой буквы — это особенность
              языка Ратвара, не путайтесь.
            </NoticeBox>
          </>
        )}
      </Box>
      {recollection_categories?.map(cat => (
        <Fragment key={cat.name}>
          <br />
          <Button
            tooltip={cat.desc}
            tooltipPosition={'right'}
            onClick={() => act('rec_category', {
              "category": cat.name,
            })} >
            {cat.name}
          </Button>
        </Fragment>
      ))}
      <Divider />
      <Box>
        <Box
          as={'span'}
          textColor={'#BE8700'}
          fontSize={2.3}>
          {rec_section?.title ? (
            rec_section.title
          ) : (
            'Архив плиты не найден.'
          )}
        </Box>
        <br /><br />
        {rec_section?.info ? (
          rec_section.info
        ) : (
          "Когскараб, видимо, потерял этот раздел."
        )}
      </Box>
      <br />
      <Divider />
      <Box>
        <Box
          as={'span'}
          textColor={'#BE8700'}
          fontSize={2.3}>
          Быстрые писания
        </Box>
        <br />
        <Box as={'span'} italic>
          До пяти писаний можно привязать
          к кнопкам действий.
        </Box>
        <br /><br />
        {rec_binds?.map(bind => (
          <Fragment key={bind.name ? bind.name : "none"}>
            Слот <b>быстрой привязки</b> ({rec_binds.indexOf(bind)+1}),
            сейчас:&nbsp;
            <span style={`color:${bind ? bind.color : "#BE8700"}`}>
              {bind?.name ? bind.name : "Нет"}
            </span>
            .
            <br />
          </Fragment>
        ))}
      </Box>
    </Section>
  );
};
