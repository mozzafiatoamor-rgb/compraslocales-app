-- Tickets (fotos de recibos): visibles por URL, pero subir requiere login.
update storage.buckets set public = true where id = 'tickets';

drop policy if exists tickets_auth_read on storage.objects;
drop policy if exists tickets_public_read on storage.objects;
create policy tickets_public_read on storage.objects
  for select to anon, authenticated using (bucket_id = 'tickets');

-- (subir se mantiene solo para autenticados: política tickets_auth_insert del 04)
