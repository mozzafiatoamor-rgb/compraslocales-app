-- ============================================================
-- PASO FINAL: cerrar permisos. Correr al final, ya con datos,
-- usuarios y cuentas de Auth listas y probadas.
-- Después de esto: sin iniciar sesión (nombre+PIN) NO se puede
-- leer ni escribir nada. La key pública deja de ser un riesgo.
-- ============================================================
do $$
declare t text;
begin
  foreach t in array array['catalogo','proveedores','compras','fondos','bitacora','pedidos','rutas','usuarios','config']
  loop
    execute format('alter table public.%I enable row level security;', t);
    -- quitar el acceso abierto de la fase 1
    execute format('drop policy if exists anon_all on public.%I;', t);
    -- acceso solo para usuarios autenticados (login por nombre+PIN)
    execute format('drop policy if exists auth_all on public.%I;', t);
    execute format($p$create policy auth_all on public.%I for all to authenticated using (true) with check (true);$p$, t);
  end loop;
end $$;

-- 'usuarios': todos los autenticados pueden leer (para mostrar nombres);
-- solo un admin puede modificar roles.
drop policy if exists auth_all on public.usuarios;
drop policy if exists usuarios_select on public.usuarios;
drop policy if exists usuarios_admin_write on public.usuarios;
create policy usuarios_select on public.usuarios for select to authenticated using (true);
create policy usuarios_admin_write on public.usuarios for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- Storage de tickets: subir/leer solo autenticados
drop policy if exists tickets_anon_insert on storage.objects;
drop policy if exists tickets_public_read on storage.objects;
drop policy if exists tickets_auth_insert on storage.objects;
drop policy if exists tickets_auth_read on storage.objects;
create policy tickets_auth_insert on storage.objects for insert to authenticated with check (bucket_id='tickets');
create policy tickets_auth_read   on storage.objects for select to authenticated using (bucket_id='tickets');
update storage.buckets set public=false where id='tickets';
