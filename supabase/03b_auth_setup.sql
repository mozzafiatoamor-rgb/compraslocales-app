-- ============================================================
-- PASO 3: dejar 'usuarios' limpio y listo para login por nombre+PIN
-- (correr DESPUÉS de re-migrar los datos transaccionales)
-- Cada persona = una cuenta de Supabase Auth (correo interno = su nombre).
-- El PIN se define al crear la cuenta en el panel de Supabase (no aquí).
-- ============================================================

-- columna de enlace con la cuenta de Auth
alter table public.usuarios add column if not exists email text;
alter table public.usuarios add column if not exists activo text default 'SI';

-- limpiar: quitar filas basura y duplicadas, dejar 6 personas
delete from public.usuarios;  -- se re-crean limpias abajo

insert into public.usuarios (id, usuario, password, nombre, rol, email, activo) values
 ('1','GUSTAVO','','GUSTAVO','admin',    'gustavo@compras.local','SI'),
 ('2','FERNELI','','FERNELI','comprador','ferneli@compras.local','SI'),
 ('3','EUCEBIO','','EUCEBIO','cocinero', 'eucebio@compras.local','SI'),
 ('4','ABIGAIL','','ABIGAIL','cajero',   'abigail@compras.local','SI'),
 ('5','JULIO','',  'JULIO',  'cajero',   'julio@compras.local','SI'),
 ('6','ULISES','', 'ULISES', 'comprador','ulises@compras.local','SI');
-- (los roles los podrá cambiar el admin desde la app)

-- función para el selector de nombres en la pantalla de login (sin exponer datos)
create or replace function public.list_staff()
returns table(id text, nombre text, rol text, email text)
language sql security definer set search_path = public as $$
  select id, nombre, rol, email from public.usuarios
  where coalesce(activo,'SI') <> 'NO' order by nombre;
$$;

-- saber si el usuario logueado es admin (para permitir cambiar roles)
create or replace function public.is_admin()
returns boolean language sql security definer set search_path = public as $$
  select exists(select 1 from public.usuarios
                where email = auth.email() and lower(rol) = 'admin');
$$;

grant execute on function public.list_staff() to anon, authenticated;
grant execute on function public.is_admin() to authenticated;
