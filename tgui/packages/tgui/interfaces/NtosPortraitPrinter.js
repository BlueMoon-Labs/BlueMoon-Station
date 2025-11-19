import { resolveAsset } from '../assets';
import { useBackend, useLocalState } from '../backend';
import { Button, NoticeBox, Section, Stack, Tabs, Input } from '../components';
import { NtosWindow } from '../layouts';

export const NtosPortraitPrinter = (props, context) => {
  const { act, data } = useBackend(context);
  const [tabIndex, setTabIndex] = useLocalState(context, 'tabIndex', 0);
  const [listIndex, setListIndex] = useLocalState(context, 'listIndex', 0);
  const [query, setQuery] = useLocalState(context, 'query', '');
  const {
    library,
    library_secure,
    library_private,
    library_large,
    library_large_private,
  } = data;
  const TABS = [
    {
      name: 'Common Portraits',
      asset_prefix: "library",
      list: library,
    },
    {
      name: 'Secure Portraits',
      asset_prefix: "library_secure",
      list: library_secure,
    },
    {
      name: 'Private Portraits',
      asset_prefix: "library_private",
      list: library_private,
    },
    {
      name: 'Large Portraits',
      asset_prefix: "library_large",
      list: library_large,
    },
    {
      name: 'Large Private Portraits',
      asset_prefix: "library_large_private",
      list: library_large_private,
    },
  ];
  //const tab2list = TABS[tabIndex].list;
  //const current_portrait_title = tab2list[listIndex]["title"];
  //const current_portrait_asset_name = TABS[tabIndex].asset_prefix + "_" + tab2list[listIndex]["md5"];
  const baseList = TABS[tabIndex].list || [];

  const filteredList = !query
    ? baseList
    : baseList.filter(p =>
      String(p.title)
        .toLowerCase()
        .includes(query.toLowerCase()),
    );

  const hasPortraits = filteredList.length > 0;
  const safeIndex = hasPortraits
    ? Math.min(listIndex, filteredList.length - 1)
    : 0;

  const current_portrait_title = hasPortraits
    ? filteredList[safeIndex].title
    : 'No portraits found';

  const current_portrait_asset_name = hasPortraits
    ? TABS[tabIndex].asset_prefix + '_' + filteredList[safeIndex].md5
    : '';

  return (
    <NtosWindow
      title="Art Galaxy"
      width={400}
      height={406}>
      <NtosWindow.Content>
        <Stack vertical fill>
          <Stack.Item>
            <Section fitted>
              <Tabs fluid textAlign="center">
                {TABS.map((tabObj, i) => !!tabObj.list && (
                  <Tabs.Tab
                    key={i}
                    selected={i === tabIndex}
                    onClick={() => {
                      setListIndex(0);
                      setTabIndex(i);
                    }}>
                    {tabObj.name}
                  </Tabs.Tab>
                ))}
              </Tabs>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Section>
              <Input
                fluid
                placeholder="Search portraits..."
                value={query}
                onInput={(_e, value) => {
                  setListIndex(0);
                  setQuery(value);
                }}
              />
            </Section>
          </Stack.Item>
          <Stack.Item grow={2}>
            <Section fill>
              <Stack
                height="100%"
                align="center"
                justify="center"
                direction="column">
                <Stack.Item>
                  <img
                    src={resolveAsset(current_portrait_asset_name)}
                    height="128px"
                    style={{
                      'vertical-align': 'middle',
                      '-ms-interpolation-mode': 'nearest-neighbor',
                    }} />
                </Stack.Item>
                <Stack.Item className="Section__titleText">
                  {current_portrait_title}
                </Stack.Item>
              </Stack>
            </Section>
          </Stack.Item>
          <Stack.Item>
            <Stack>
              <Stack.Item grow={3}>
                <Section height="100%">
                  <Stack justify="space-between">
                    <Stack.Item grow={1}>
                      <Button
                        icon="angle-double-left"
                        disabled={!hasPortraits || safeIndex === 0}
                        onClick={() => setListIndex(0)}
                      />
                    </Stack.Item>
                    <Stack.Item grow={3}>
                      <Button
                        disabled={!hasPortraits || safeIndex === 0}
                        icon="chevron-left"
                        onClick={() => setListIndex(listIndex - 1)}
                      />
                    </Stack.Item>
                    <Stack.Item grow={3}>
                      <Button
                        icon="check"
                        disabled={!hasPortraits}
                        content="Print Portrait"
                        onClick={() => act("select", {
                          tab: tabIndex + 1,
                          selected: listIndex + 1,
                        })}
                      />
                    </Stack.Item>
                    <Stack.Item grow={1}>
                      <Button
                        icon="chevron-right"
                        disabled={!hasPortraits || safeIndex === filteredList.length - 1}
                        onClick={() => setListIndex(listIndex + 1)}
                      />
                    </Stack.Item>
                    <Stack.Item>
                      <Button
                        icon="angle-double-right"
                        disabled={!hasPortraits || safeIndex === filteredList.length - 1}
                        onClick={() => setListIndex(filteredList.length - 1)}
                      />
                    </Stack.Item>
                  </Stack>
                </Section>
              </Stack.Item>
            </Stack>
            <Stack.Item mt={1} mb={-1}>
              <NoticeBox info>
                Printing a canvas costs 5 paper from
                the printer installed in your machine.
              </NoticeBox>
            </Stack.Item>
          </Stack.Item>
        </Stack>
      </NtosWindow.Content>
    </NtosWindow>
  );
};
