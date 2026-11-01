import { memo, useState } from 'react';

import { Box, Button, Icon } from '../../components';
import { THEME } from './types';
import { useNetrunBackend } from './useNetrunBackend';

/** Hacked rights collect in an ordinary file; this panel opens or copies it. */
export const AccessExport = memo(() => {
  const { act, data } = useNetrunBackend(['access_export', 'shard', 'storage']);
  const [name, setName] = useState('Копия.grants');
  const [toShard, setToShard] = useState(false);
  const access = data.access_export;
  const destination = toShard && data.shard ? data.shard : data.storage;
  const merging = destination?.files.some((file) => file.kind === 'grants');
  if (!access) { return null; }
  return (<details className="netrun-agent-details" data-net-access-export>
    <summary><Icon name="key" /> Ключ доступа</summary>
    <Box color={THEME.muted} fontSize="11px">Полученные взломом права автоматически собираются в один файл .grants в памяти. Его можно передать или скопировать. Доступ ID остаётся в текущем погружении.</Box>
    <Box mt={0.5} fontSize="11px">Узлов: {access.node_count} · сетей: {access.network_count}</Box>
    {!!access.key_uid && <Button compact mt={0.5} icon="file" content={access.key_name || 'Показать файл ключа'}
      tooltip="Открыть файл добытых прав: его можно переименовать, скопировать или переместить."
      onClick={() => act('file_select', { uid: access.key_uid })} />}
    <label className="netrun-field">Имя ключа<input value={name} maxLength={64} onChange={(event) => setName(event.target.value)} /></label>
    <label className="netrun-field">Сохранить ключ<select value={toShard && data.shard ? 'shard' : 'local'} onChange={(event) => setToShard(event.target.value === 'shard')}>
      <option value="local">Локальная память</option>
      {!!data.shard && <option value="shard">{data.shard.name}</option>}
                                                  </select>
    </label>
    <Button compact icon="copy" content={merging ? 'Обновить ключ на носителе' : 'Скопировать ключ'} disabled={!access.can_export || !name.trim()}
      tooltip={access.reason || (merging ? 'Объединить действующие права с существующим файлом; его имя сохранится.' : 'Создать независимую копию текущих добытых прав.')}
      onClick={() => act('access_export', { name: name.trim(), to_shard: !!data.shard && toShard })} />
    {!!access.reason && <Box color={THEME.muted} fontSize="11px" mt={0.5}>{access.reason}</Box>}
    {!!merging && <Box color={THEME.muted} fontSize="11px" mt={0.5}>На каждом носителе хранится один общий ключ. Новые права дополнят существующий файл.</Box>}
          </details>);
});
