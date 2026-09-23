-- Permitir eliminar tickets del Storage SOLO a administradores
drop policy if exists tickets_admin_delete on storage.objects;
create policy tickets_admin_delete on storage.objects
  for delete to authenticated
  using (bucket_id = 'tickets' and public.is_admin());
