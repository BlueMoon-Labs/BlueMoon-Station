import { memo, useState } from 'react';

import { Box, Button, Icon } from '../../components';
import { isCopyableFile } from './filePermissions';
import { EntityContact, THEME } from './types';
import { useNetrunBackend } from './useNetrunBackend';

/** The delivered proposal carries a copy; recipients decide whether to keep it in local memory. */
export const FileExchangePanel = memo(() => {
  const { act, data } = useNetrunBackend(['file_exchange']);
  const offers = (data.file_exchange?.incoming || []).slice(0, 8);
  if (!offers.length) { return null; }
  return (<div className="netrun-file-offers" role="region" aria-label="Входящие предложения файлов">
    <Box bold mb={0.5}><Icon name="inbox" mr={0.5} />Входящие файлы ({offers.length})</Box>
    <Box color={THEME.muted} fontSize="11px">Принятая копия появится в локальной памяти.</Box>
    {offers.map((offer) => (<article key={offer.id} className="netrun-file-offers__entry" data-net-file-offer={offer.id}>
      <Box bold>{offer.name}</Box>
      <Box color={THEME.muted} fontSize="11px">Копия от {offer.sender} · память {offer.size} · предложение ещё {Math.max(0, Math.ceil(offer.ttl))} с</Box>
      <div style={{ display: 'flex', flexWrap: 'wrap', gap: '5px', marginTop: '6px' }}>
        <Button compact icon="download" content="Принять в память" disabled={!offer.can_accept}
          tooltip={offer.reason || 'Сохранить доставленную копию в своей памяти.'}
          onClick={() => act('entity_file_accept', { id: offer.id })} />
        <Button compact icon="xmark" content="Отклонить" onClick={() => act('entity_file_reject', { id: offer.id })} />
      </div>
      {!offer.can_accept && !!offer.reason && <Box color={THEME.warn} fontSize="11px" mt={0.5}>{offer.reason}</Box>}
                            </article>))}
          </div>);
});

/** Only a currently disclosed contact and a file still on our media can be proposed. */
export const FileOffer = ({ address, contact, pending }: { address: string; contact: EntityContact; pending: boolean }) => {
  const [open, setOpen] = useState(false);
  const allowed = !pending && !!contact.can_offer;
  return (<Box mt={0.5}>
    <Button compact icon="file-export" content="Предложить копию файла" selected={open} disabled={!allowed}
      tooltip={contact.offer_reason || (pending ? 'Дождитесь обновления выбранного узла.' : 'Получатель сам подтвердит сохранение копии.')}
      onClick={() => setOpen(!open)} />
    {!allowed && !!contact.offer_reason && <Box color={THEME.muted} fontSize="11px" mt={0.5}>{contact.offer_reason}</Box>}
    {open && <FileOfferForm address={address} contact={contact} allowed={allowed} />}
          </Box>);
};

/** Closed contact cards do not subscribe to inventories or enumerate their files. */
const FileOfferForm = ({ address, contact, allowed }: { address: string; contact: EntityContact; allowed: boolean }) => {
  const { act, data } = useNetrunBackend(['storage', 'shard']);
  const [uid, setUid] = useState('');
  const files = [...new Map([...(data.storage?.files || []), ...(data.shard?.files || [])].filter(isCopyableFile).map((file) => [file.uid, file])).values()];
  const file = files.find((entry) => entry.uid === uid);
  const offer = () => {
    if (allowed && file) { act('entity_file_offer', { ref: contact.ref, address, uid: file.uid }); }
  };
  return (<form className="netrun-agent-form" aria-label={`Предложение файла для ${contact.name}`}
      onSubmit={(event) => { event.preventDefault(); offer(); }}>
      <label className="netrun-field">Файл для {contact.name}<select value={file?.uid || ''} disabled={!allowed}
        onChange={(event) => setUid(event.target.value)}>
        <option value="">Выберите файл…</option>
        {files.map((entry) => <option key={entry.uid} value={entry.uid}>{entry.name} · память {entry.size} · {data.shard?.files.some((candidate) => candidate.uid === entry.uid) ? 'шард' : 'локально'}</option>)}
                                                             </select>
      </label>
      {!files.length && <Box color={THEME.muted} fontSize="11px">В памяти и на шарде нет файлов для предложения.</Box>}
      <Box color={THEME.muted} fontSize="11px" mb={0.5}>Получатель подтвердит сохранение. Исходный файл остаётся у вас.</Box>
      <Button compact icon="paper-plane" content="Отправить предложение" disabled={!allowed || !file} onClick={offer} />
          </form>);
};
