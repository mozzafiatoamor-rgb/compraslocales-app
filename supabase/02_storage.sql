-- Bucket público para tickets (fotos de compras)
insert into storage.buckets (id, name, public)
values ('tickets', 'tickets', true)
on conflict (id) do nothing;

-- Permitir subir/leer tickets con la anon key
drop policy if exists tickets_anon_insert on storage.objects;
create policy tickets_anon_insert on storage.objects
  for insert to anon with check (bucket_id = 'tickets');

drop policy if exists tickets_public_read on storage.objects;
create policy tickets_public_read on storage.objects
  for select to anon using (bucket_id = 'tickets');
