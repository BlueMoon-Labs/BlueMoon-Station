import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Collapsible,
  Dropdown,
  Flex,
  Icon,
  Input,
  NoticeBox,
  NumberInput,
  Section,
  Stack,
  Tabs,
  TextArea,
} from '../components';
import { Window } from '../layouts';

const BAN_TYPES = [
  { value: '1', label: 'PERMABAN' },
  { value: '2', label: 'TEMPBAN' },
  { value: '3', label: 'JOB PERMABAN' },
  { value: '4', label: 'JOB TEMPBAN' },
  { value: '7', label: 'ADMIN PERMABAN' },
  { value: '8', label: 'ADMIN TEMPBAN' },
  { value: '10', label: 'PACIFICATION BAN' },
];

const SEVERITY_OPTIONS = ['High', 'Medium', 'Minor', 'None'];

const BANTYPE_LABELS = {
  'PERMABAN': { color: 'red', icon: 'ban' },
  'TEMPBAN': { color: 'orange', icon: 'clock' },
  'JOB_PERMABAN': { color: 'yellow', icon: 'briefcase' },
  'JOB_TEMPBAN': { color: 'yellow', icon: 'briefcase' },
  'ADMIN_PERMABAN': { color: 'purple', icon: 'user-shield' },
  'ADMIN_TEMPBAN': { color: 'purple', icon: 'user-shield' },
  'PACIFICATION_BAN': { color: 'teal', icon: 'dove' },
};

export const BanPanel = (props, context) => {
  const { act, data } = useBackend(context);
  const {
    db_connected,
    playerckey,
    adminckey,
    ip,
    cid,
    page,
    job_categories = [],
    banned_roles = [],
    job_list = [],
    search_results = [],
    total_count = 0,
  } = data;

  const [tab, setTab] = useLocalState(context, 'tab', 0);

  if (!db_connected) {
    return (
      <Window title="Banning & Unbanning" width={700} height={400} theme="admin">
        <Window.Content>
          <Flex height="100%" align="center" justify="center" direction="column">
            <Icon name="database" size={4} color="red" mb={2} />
            <Box fontSize="18px" bold mb={1}>Database not connected</Box>
            <Box color="gray" textAlign="center" maxWidth="500px">
              SQL bans and search are unavailable until the server can connect
              to MySQL (check <b>dbconfig.txt</b> and that the DB service is running).
            </Box>
            <Box color="gray" textAlign="center" mt={1} maxWidth="500px" fontSize="11px">
              If your config uses the legacy banlist file instead, enable
              <b> ban_legacy_system</b> in game options for the old savefile-based
              panel (limited features).
            </Box>
          </Flex>
        </Window.Content>
      </Window>
    );
  }

  const bansPerPage = 15;
  const totalPages = Math.max(1, Math.ceil(total_count / bansPerPage));

  return (
    <Window title="Banning & Unbanning" width={900} height={640} theme="admin" resizable>
      <Window.Content>
        <Stack vertical fill>
          <Stack.Item>
            <SearchBar
              playerckey={playerckey}
              adminckey={adminckey}
              ip={ip}
              cid={cid}
              tguiContext={context}
              onSearch={(fields) => act('search', fields)}
            />
          </Stack.Item>
          <Stack.Item>
            <Tabs>
              <Tabs.Tab
                selected={tab === 0}
                icon="gavel"
                onClick={() => setTab(0)}>
                Custom Ban
              </Tabs.Tab>
              <Tabs.Tab
                selected={tab === 1}
                icon="search"
                onClick={() => setTab(1)}>
                Search Results
                {total_count > 0 && (
                  <Box as="span" ml={1} opacity={0.6}>({total_count})</Box>
                )}
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          <Stack.Item grow>
            {tab === 0 && (
              <CustomBanForm
                playerckey={playerckey}
                job_categories={job_categories}
                banned_roles={banned_roles}
                job_list={job_list}
                tguiContext={context}
                onAddBan={(fields) => act('add_ban', fields)}
                onUnbanJobs={(fields) => act('unban_jobs', fields)}
              />
            )}
            {tab === 1 && (
              <SearchResults
                search_results={search_results}
                total_count={total_count}
                page={page}
                totalPages={totalPages}
                onSetPage={(p) => act('set_page', { page: p })}
                onEditBan={(banid, edit) => act('edit_ban', { banid, banedit: edit })}
                onUnban={(banid) => act('unban', { banid })}
              />
            )}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};

const SearchBar = (props) => {
  const { playerckey, adminckey, ip, cid, tguiContext, onSearch } = props;
  const [localPlayer, setLocalPlayer] = useLocalState(
    tguiContext, 'search_player', playerckey || ''
  );
  const [localAdmin, setLocalAdmin] = useLocalState(
    tguiContext, 'search_admin', adminckey || ''
  );
  const [localIp, setLocalIp] = useLocalState(
    tguiContext, 'search_ip', ip || ''
  );
  const [localCid, setLocalCid] = useLocalState(
    tguiContext, 'search_cid', cid || ''
  );

  return (
    <Section py={0.5}>
      <Flex align="center" wrap="wrap">
        <Flex.Item mr={0.5} mb={0.5}>
          <Icon name="search" color="label" mr={1} />
        </Flex.Item>
        <Flex.Item mr={1} mb={0.5}>
          <Input
            width="130px"
            value={localPlayer}
            placeholder="Ckey..."
            onChange={(e, v) => setLocalPlayer(v)}
          />
        </Flex.Item>
        <Flex.Item mr={1} mb={0.5}>
          <Input
            width="110px"
            value={localAdmin}
            placeholder="Admin..."
            onChange={(e, v) => setLocalAdmin(v)}
          />
        </Flex.Item>
        <Flex.Item mr={1} mb={0.5}>
          <Input
            width="120px"
            value={localIp}
            placeholder="IP..."
            onChange={(e, v) => setLocalIp(v)}
          />
        </Flex.Item>
        <Flex.Item mr={1} mb={0.5}>
          <Input
            width="100px"
            value={localCid}
            placeholder="CID..."
            onChange={(e, v) => setLocalCid(v)}
          />
        </Flex.Item>
        <Flex.Item mb={0.5}>
          <Button
            icon="search"
            color="blue"
            onClick={() => onSearch({
              playerckey: localPlayer,
              adminckey: localAdmin,
              ip: localIp,
              cid: localCid,
            })}
          >
            Search
          </Button>
        </Flex.Item>
      </Flex>
    </Section>
  );
};

const CustomBanForm = (props) => {
  const {
    playerckey,
    job_categories,
    banned_roles,
    job_list,
    tguiContext,
    onAddBan,
    onUnbanJobs,
  } = props;

  const [banType, setBanType] = useLocalState(tguiContext, 'banType', '');
  const [banKey, setBanKey] = useLocalState(tguiContext, 'banKey', playerckey || '');
  const [banIp, setBanIp] = useLocalState(tguiContext, 'banIp', '');
  const [banCid, setBanCid] = useLocalState(tguiContext, 'banCid', '');
  const [banDuration, setBanDuration] = useLocalState(tguiContext, 'banDuration', 0);
  const [banSeverity, setBanSeverity] = useLocalState(tguiContext, 'banSeverity', '');
  const [banJob, setBanJob] = useLocalState(tguiContext, 'banJob', '');
  const [banReason, setBanReason] = useLocalState(tguiContext, 'banReason', '');
  const [checkedRoles, setCheckedRoles] = useLocalState(tguiContext, 'checkedRoles', {});
  const [expandedCats, setExpandedCats] = useLocalState(tguiContext, 'expandedCats', {});

  const flatRoles = [];
  job_categories.forEach((cat) => {
    cat.roles.forEach((role) => flatRoles.push(role.name));
  });

  const toggleRole = (roleName, idx) => {
    setCheckedRoles((prev) => ({
      ...prev,
      [idx]: !prev[idx],
    }));
  };

  const toggleCategory = (catName) => {
    setExpandedCats((prev) => ({
      ...prev,
      [catName]: !prev[catName],
    }));
  };

  const selectAllExceptOther = () => {
    const newChecked = {};
    let i = 0;
    job_categories.forEach((cat) => {
      cat.roles.forEach(() => {
        i++;
        newChecked[i] = cat.name !== 'Other';
      });
    });
    setCheckedRoles(newChecked);
  };

  const unselectAllExceptOther = () => {
    const newChecked = { ...checkedRoles };
    let i = 0;
    job_categories.forEach((cat) => {
      cat.roles.forEach(() => {
        i++;
        if (cat.name !== 'Other') {
          newChecked[i] = false;
        }
      });
    });
    setCheckedRoles(newChecked);
  };

  const handleAddBan = () => {
    const jrMax = flatRoles.length;
    const fields = {
      bantype: banType,
      bankey: banKey,
      banip: banIp,
      bancid: banCid,
      banduration: banDuration,
      banjob: banJob,
      banreason: banReason,
      banseverity: banSeverity,
      jr_max: jrMax,
    };
    for (let i = 1; i <= jrMax; i++) {
      if (checkedRoles[i]) {
        fields['jr_' + i] = String(i);
      }
    }
    onAddBan(fields);
  };

  const handleUnbanJobs = () => {
    const jrMax = flatRoles.length;
    const fields = {
      bankey: banKey,
      jr_max: jrMax,
    };
    for (let i = 1; i <= jrMax; i++) {
      if (checkedRoles[i]) {
        fields['jr_' + i] = String(i);
      }
      if (banned_roles.includes(flatRoles[i - 1])) {
        fields['was_jr_' + i] = '1';
      }
    }
    onUnbanJobs(fields);
  };

  let roleIdx = 0;

  return (
    <Section
      title="Custom Ban"
      fill
      scrollable
    >
      <NoticeBox info fontSize="11px" mb={0.5}>
        JOB PERMA/TEMP: отметьте роли ниже или выберите Job. Снятие: Key, снимите галочки, «Снять джоббаны».
      </NoticeBox>

      <Flex wrap="wrap" mb={0.5}>
        <Flex.Item width="50%" pr={0.5}>
          <Box bold mb={0.3} color="label" fontSize="11px">Ban Type</Box>
          <Dropdown
            width="100%"
            selected={banType ? BAN_TYPES.find((t) => t.value === banType)?.label : 'Select...'}
            options={BAN_TYPES.map((t) => t.label)}
            onSelected={(v) => {
              const found = BAN_TYPES.find((t) => t.label === v);
              setBanType(found ? found.value : '');
            }}
          />
        </Flex.Item>
        <Flex.Item width="50%" pl={0.5}>
          <Box bold mb={0.3} color="label" fontSize="11px">Key</Box>
          <Input
            width="100%"
            value={banKey}
            placeholder="player key"
            onChange={(e, v) => setBanKey(v)}
          />
        </Flex.Item>
      </Flex>

      <Flex wrap="wrap" mb={0.5}>
        <Flex.Item width="50%" pr={0.5}>
          <Box bold mb={0.3} color="label" fontSize="11px">IP</Box>
          <Input
            width="100%"
            value={banIp}
            placeholder="ip address"
            onChange={(e, v) => setBanIp(v)}
          />
        </Flex.Item>
        <Flex.Item width="50%" pl={0.5}>
          <Box bold mb={0.3} color="label" fontSize="11px">Computer ID</Box>
          <Input
            width="100%"
            value={banCid}
            placeholder="computer id"
            onChange={(e, v) => setBanCid(v)}
          />
        </Flex.Item>
      </Flex>

      <Flex wrap="wrap" mb={0.5}>
        <Flex.Item width="50%" pr={0.5}>
          <Box bold mb={0.3} color="label" fontSize="11px">Duration (min)</Box>
          <NumberInput
            width="100%"
            value={banDuration}
            minValue={0}
            onChange={(e, v) => setBanDuration(v)}
          />
        </Flex.Item>
        <Flex.Item width="50%" pl={0.5}>
          <Box bold mb={0.3} color="label" fontSize="11px">Severity</Box>
          <Dropdown
            width="100%"
            selected={banSeverity || 'Select...'}
            options={SEVERITY_OPTIONS}
            onSelected={(v) => setBanSeverity(v)}
          />
        </Flex.Item>
      </Flex>

      <Box bold mb={0.3} color="label" fontSize="11px">
        Job <Box as="span" color="gray">(если не отмечены роли)</Box>
      </Box>
      <Dropdown
        width="100%"
        mb={0.5}
        selected={banJob || '--'}
        options={job_list}
        onSelected={(v) => setBanJob(v)}
      />

      <Box mb={0.5}>
          <Flex align="center" mb={0.5}>
            <Flex.Item mr={1}>
              <Button icon="check-double" color="good" onClick={selectAllExceptOther}>
                Забанить всё, кроме Other
              </Button>
            </Flex.Item>
            <Flex.Item>
              <Button icon="times" color="bad" onClick={unselectAllExceptOther}>
                Разбанить всё, кроме Other
              </Button>
            </Flex.Item>
            <Flex.Item ml={0.5}>
              <Box color="gray" fontSize="10px">бан: JOB + Add; разбан: снять + Снять джоббаны</Box>
            </Flex.Item>
          </Flex>
          {banned_roles.length > 0 && (
            <NoticeBox warning fontSize="11px" mb={0.5}>
              Активные джоббаны по Key уже отмечены. Снимите галочки и нажмите
              <b> Снять джоббаны</b>.
            </NoticeBox>
          )}
          <Flex wrap="wrap">
            {job_categories.map((cat) => {
              const isOther = cat.name === 'Other';
              return (
                <Flex.Item
                  key={cat.name}
                  width="155px"
                  mr={1}
                  mb={0.5}
                  opacity={isOther ? 0.85 : 1}
                >
                  <Collapsible
                    title={
                      <Box bold color={cat.color} fontSize="11px">
                        {cat.name}
                      </Box>
                    }
                    open={expandedCats[cat.name] === true}
                    onToggle={() => toggleCategory(cat.name)}
                  >
                    <Box
                      style={{
                        maxHeight: '120px',
                        overflowY: 'auto',
                        background: 'rgba(255,255,255,0.03)',
                        borderRadius: '4px',
                        padding: '2px',
                      }}
                    >
                      {cat.roles.map((role) => {
                        roleIdx++;
                        const idx = roleIdx;
                        const isBanned = banned_roles.includes(role.name);
                        return (
                          <Box
                            key={role.name}
                            mb={0.1}
                            style={{
                              background: isBanned
                                ? 'rgba(200,60,60,0.3)'
                                : 'transparent',
                              borderRadius: '3px',
                              padding: '1px 3px',
                              border: isBanned
                                ? '1px solid rgba(220,90,90,0.4)'
                                : '1px solid transparent',
                            }}
                          >
                            <Button.Checkbox
                              checked={!!checkedRoles[idx]}
                              content={role.name}
                              onClick={() => toggleRole(role.name, idx)}
                            />
                          </Box>
                        );
                      })}
                    </Box>
                  </Collapsible>
                </Flex.Item>
              );
            })}
          </Flex>
        </Box>

      <Box bold mb={0.3} color="label" fontSize="11px">Reason</Box>
      <TextArea
        width="100%"
        height="50px"
        mb={0.5}
        value={banReason}
        onChange={(e, v) => setBanReason(v)}
      />

      <Flex>
        <Flex.Item mr={1}>
          <Button icon="gavel" color="red" onClick={handleAddBan}>
            Add Ban
          </Button>
        </Flex.Item>
        <Flex.Item>
          <Button icon="unlock" color="green" onClick={handleUnbanJobs}>
            Снять джоббаны (снятые галочки)
          </Button>
        </Flex.Item>
      </Flex>

      <Box color="gray" fontSize="11px" mt={0.5}>
        Учтите: джоббаны и снятие джоббанов действуют со следующего раунда.
      </Box>
    </Section>
  );
};

const SearchResults = (props) => {
  const {
    search_results,
    total_count,
    page,
    totalPages,
    onSetPage,
    onEditBan,
    onUnban,
  } = props;

  if (search_results.length === 0) {
    return (
      <Section title="Search Results" fill>
        <Flex height="100%" align="center" justify="center">
          <Box color="gray">
            <Icon name="search" mr={1} />
            No results found. Use the search bar above to look up bans.
          </Box>
        </Flex>
      </Section>
    );
  }

  return (
    <Section
      title={'Search Results (' + total_count + ' total)'}
      fill
      scrollable
      buttons={
        totalPages > 1 && (
          <Flex align="center">
            <Button
              icon="chevron-left"
              disabled={page === 0}
              onClick={() => onSetPage(page - 1)}
            />
            <Box mx={1} color="label" fontSize="12px">
              Page {page + 1} / {totalPages}
            </Box>
            <Button
              icon="chevron-right"
              disabled={page >= totalPages - 1}
              onClick={() => onSetPage(page + 1)}
            />
          </Flex>
        )
      }
    >
      {totalPages > 1 && (
        <Flex wrap="wrap" mb={1}>
          {Array.from({ length: totalPages }, (_, i) => (
            <Flex.Item key={i} mr={0.5} mb={0.5}>
              <Button
                selected={i === page}
                onClick={() => onSetPage(i)}
              >
                {i + 1}
              </Button>
            </Flex.Item>
          ))}
        </Flex>
      )}
      <Stack vertical>
        {search_results.map((ban) => (
          <Stack.Item key={ban.id}>
            <BanEntry ban={ban} onEditBan={onEditBan} onUnban={onUnban} />
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
};

const BanEntry = (props) => {
  const { ban, onEditBan, onUnban } = props;
  const info = BANTYPE_LABELS[ban.bantype] || { color: 'gray', icon: 'question' };
  const isUnbanned = !!ban.unbanned;

  return (
    <Box
      mb={0.5}
      style={{
        border: '1px solid rgba(255,255,255,0.1)',
        borderRadius: '4px',
        overflow: 'hidden',
        opacity: isUnbanned ? 0.6 : 1,
      }}
    >
      <Box
        px={1}
        py={0.5}
        style={{
          background: isUnbanned
            ? 'rgba(100,100,100,0.2)'
            : 'rgba(200,60,60,0.2)',
          borderBottom: '1px solid rgba(255,255,255,0.06)',
        }}
      >
        <Flex align="center" wrap="wrap">
          <Flex.Item mr={1}>
            <Icon name={info.icon} color={info.color} mr={0.5} />
            <Box inline bold color={info.color} fontSize="12px">
              {ban.bantype}
            </Box>
          </Flex.Item>
          {ban.job && (
            <Flex.Item mr={1}>
              <Box as="span" px={0.8} py={0.1} fontSize="11px"
                style={{ background: 'rgba(255,255,255,0.08)', borderRadius: '3px' }}>
                {ban.job}
              </Box>
            </Flex.Item>
          )}
          {ban.duration > 0 && (
            <Flex.Item mr={1}>
              <Box as="span" color="gray" fontSize="11px">{ban.duration} min</Box>
            </Flex.Item>
          )}
          {ban.expiration && (
            <Flex.Item mr={1}>
              <Box as="span" color="gray" fontSize="11px">Expires: {ban.expiration}</Box>
            </Flex.Item>
          )}
          <Flex.Item grow />
          <Flex.Item>
            <Box inline bold color="white" mr={1}>{ban.ban_key}</Box>
            <Box inline color="gray" fontSize="11px" mr={1}>{ban.bantime}</Box>
            <Box inline color="gray" fontSize="11px" mr={1}>Round #{ban.round_id}</Box>
            <Box inline color="label">by <b>{ban.a_key}</b></Box>
          </Flex.Item>
        </Flex>
      </Box>

      <Box px={1} py={0.5}>
        <Flex align="center" wrap="wrap">
          <Flex.Item grow mr={1}>
            <Box color="label" fontSize="11px" mb={0.2}>
              <b>Reason</b>
              {!isUnbanned && (
                <Button icon="pen" color="transparent" ml={1}
                  onClick={() => onEditBan(ban.id, 'reason')}>
                  Edit
                </Button>
              )}
            </Box>
            <Box fontSize="11px" color="#e2e8f0"
              style={{ fontStyle: 'italic', wordBreak: 'break-word' }}>
              {"\u201C"}{ban.reason}{"\u201D"}
            </Box>
          </Flex.Item>
          <Flex.Item shrink={0}>
            {!isUnbanned && (
              <Flex>
                {ban.duration > 0 && (
                  <Flex.Item mr={0.5}>
                    <Button icon="clock" color="orange"
                      onClick={() => onEditBan(ban.id, 'duration')}>
                      Edit Duration
                    </Button>
                  </Flex.Item>
                )}
                <Flex.Item>
                  <Button icon="unlock" color="green"
                    onClick={() => onUnban(ban.id)}>
                    Unban
                  </Button>
                </Flex.Item>
              </Flex>
            )}
          </Flex.Item>
        </Flex>
      </Box>

      {ban.edits && (
        <Box px={1} py={0.5} fontSize="11px" color="gray"
          style={{
            borderTop: '1px solid rgba(255,255,255,0.05)',
            background: 'rgba(255,255,255,0.02)',
          }}>
          <b>Edits:</b> {ban.edits}
        </Box>
      )}

      {isUnbanned && (
        <Box px={1} py={0.5} fontSize="11px" color="green"
          style={{
            borderTop: '1px solid rgba(255,255,255,0.05)',
            background: 'rgba(80,200,120,0.08)',
          }}>
          <Icon name="check-circle" mr={0.5} />
          <b>Unbanned</b> by {ban.unban_key} on {ban.unbantime}
        </Box>
      )}
    </Box>
  );
};
