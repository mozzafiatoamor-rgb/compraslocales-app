-- ============================================================
-- FASE 2b: administrar usuarios desde la app (solo admins)
-- Crea funciones RPC que corren con privilegios (security definer)
-- y validan que quien llama sea admin. No requiere Edge Function.
-- Correr una vez en el SQL Editor.
-- ============================================================
create extension if not exists pgcrypto with schema extensions;

-- correo interno a partir del nombre (igual que en la app)
create or replace function public.slug_email(p_nombre text)
returns text language sql immutable as $$
  select lower(regexp_replace(
           translate(p_nombre,'ÁÉÍÓÚÜÑáéíóúüñ','AEIOUUNaeiouun'),
           '[^a-z0-9]','','g'))||'@compras.local';
$$;

-- ALTA de persona: crea cuenta de acceso (nombre+PIN) y su perfil
create or replace function public.admin_create_user(p_nombre text, p_pin text, p_rol text)
returns text language plpgsql security definer set search_path=public,auth,extensions as $$
declare em text; uid uuid; newid text;
begin
  if not public.is_admin() then raise exception 'No autorizado'; end if;
  if p_nombre is null or length(trim(p_nombre))=0 then raise exception 'Falta el nombre'; end if;
  if p_pin is null or p_pin !~ '^[0-9]{6}$' then raise exception 'El PIN debe ser de 6 dígitos'; end if;
  em := public.slug_email(p_nombre);
  if exists(select 1 from auth.users where email=em) then raise exception 'Ya existe una cuenta para ese nombre'; end if;
  uid := gen_random_uuid();
  insert into auth.users (instance_id,id,aud,role,email,encrypted_password,email_confirmed_at,created_at,updated_at,raw_app_meta_data,raw_user_meta_data,confirmation_token,recovery_token,email_change_token_new,email_change)
   values ('00000000-0000-0000-0000-000000000000',uid,'authenticated','authenticated',em,extensions.crypt(p_pin,extensions.gen_salt('bf')),now(),now(),now(),'{"provider":"email","providers":["email"]}','{}','','','','');
  insert into auth.identities (id,user_id,provider_id,identity_data,provider,created_at,updated_at,last_sign_in_at)
   values (gen_random_uuid(),uid,uid::text,jsonb_build_object('sub',uid::text,'email',em),'email',now(),now(),now());
  newid := (coalesce((select max((id)::int) from public.usuarios where id ~ '^[0-9]+$'),0)+1)::text;
  insert into public.usuarios (id,usuario,password,nombre,rol,email,activo)
   values (newid, p_nombre, '', p_nombre, lower(p_rol), em, 'SI');
  return em;
end $$;

-- RESET de PIN
create or replace function public.admin_reset_pin(p_nombre text, p_pin text)
returns void language plpgsql security definer set search_path=public,auth,extensions as $$
declare em text;
begin
  if not public.is_admin() then raise exception 'No autorizado'; end if;
  if p_pin is null or p_pin !~ '^[0-9]{6}$' then raise exception 'El PIN debe ser de 6 dígitos'; end if;
  select email into em from public.usuarios where nombre=p_nombre limit 1;
  if em is null then raise exception 'Usuario no encontrado'; end if;
  update auth.users set encrypted_password=extensions.crypt(p_pin,extensions.gen_salt('bf')), updated_at=now() where email=em;
end $$;

-- ACTIVAR / DESACTIVAR (desactivado = no aparece en login y no puede entrar)
create or replace function public.admin_set_active(p_nombre text, p_activo boolean)
returns void language plpgsql security definer set search_path=public,auth,extensions as $$
declare em text;
begin
  if not public.is_admin() then raise exception 'No autorizado'; end if;
  select email into em from public.usuarios where nombre=p_nombre limit 1;
  if em is null then raise exception 'Usuario no encontrado'; end if;
  update public.usuarios set activo = case when p_activo then 'SI' else 'NO' end where nombre=p_nombre;
  update auth.users set banned_until = case when p_activo then null else 'infinity'::timestamptz end where email=em;
end $$;

-- ELIMINAR persona (borra cuenta y perfil)
create or replace function public.admin_delete_user(p_nombre text)
returns void language plpgsql security definer set search_path=public,auth,extensions as $$
declare em text;
begin
  if not public.is_admin() then raise exception 'No autorizado'; end if;
  select email into em from public.usuarios where nombre=p_nombre limit 1;
  if em is null then raise exception 'Usuario no encontrado'; end if;
  delete from auth.users where email=em;      -- borra identities en cascada
  delete from public.usuarios where nombre=p_nombre;
end $$;

revoke all on function public.admin_create_user(text,text,text) from anon;
revoke all on function public.admin_reset_pin(text,text) from anon;
revoke all on function public.admin_set_active(text,boolean) from anon;
revoke all on function public.admin_delete_user(text) from anon;
grant execute on function public.admin_create_user(text,text,text) to authenticated;
grant execute on function public.admin_reset_pin(text,text) to authenticated;
grant execute on function public.admin_set_active(text,boolean) to authenticated;
grant execute on function public.admin_delete_user(text) to authenticated;
