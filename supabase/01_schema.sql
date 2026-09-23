-- ============================================================
-- Mozzafiato Compras — Esquema Supabase
-- Migración desde Google Sheets. Proyecto SEPARADO (solo compras).
-- Correr en: Supabase → SQL Editor → New query → Run.
--
-- Diseño: cada tabla tiene una columna interna "seq" (autoincremental)
-- que actúa como llave. La app sigue borrando "por número de fila";
-- la capa de datos traduce fila -> seq internamente, así NO se toca
-- ninguna de las ~40 llamadas existentes a deleteRow.
-- El orden de columnas replica EXACTO el que la app lee de cada hoja.
-- ============================================================

-- 🛒 Catálogo  (hoja A:F -> id, categoria, producto, unidad, precioRef, activo)
create table if not exists public.catalogo (
  seq        bigint generated always as identity primary key,
  id         text,
  categoria  text,
  producto   text,
  unidad     text,
  precio_ref numeric default 0,
  activo     text default 'SI'
);

-- 🏪 Proveedores (A:D -> id, nombre, tipo, activo)
create table if not exists public.proveedores (
  seq    bigint generated always as identity primary key,
  id     text,
  nombre text,
  tipo   text,
  activo text default 'SI'
);

-- 🧾 Compras (A:L -> id, fecha, hora, categoria, producto, cantidad, unidad, precio, proveedor, ticket, comprador, notas)
create table if not exists public.compras (
  seq       bigint generated always as identity primary key,
  id        text,
  fecha     text,
  hora      text,
  categoria text,
  producto  text,
  cantidad  numeric default 0,
  unidad    text,
  precio    numeric default 0,
  proveedor text,
  ticket    text,
  comprador text,
  notas     text
);

-- 💵 Fondos (A:H -> id, fecha, hora, tipo, monto, responsable, notas, para)
create table if not exists public.fondos (
  seq         bigint generated always as identity primary key,
  id          text,
  fecha       text,
  hora        text,
  tipo        text,
  monto       numeric default 0,
  responsable text,
  notas       text,
  para        text
);

-- 📜 Bitácora (A:F -> fecha, hora, usuario, accion, detalle, tipo)  [append-only]
create table if not exists public.bitacora (
  seq     bigint generated always as identity primary key,
  fecha   text,
  hora    text,
  usuario text,
  accion  text,
  detalle text,
  tipo    text
);

-- 📋 Pedidos (A:K -> id, fecha, hora, titulo, producto, cantidad, unidad, precioRef, subtotal, creador, estado)
create table if not exists public.pedidos (
  seq        bigint generated always as identity primary key,
  id         text,
  fecha      text,
  hora       text,
  titulo     text,
  producto   text,
  cantidad   numeric default 0,
  unidad     text,
  precio_ref numeric default 0,
  subtotal   numeric default 0,
  creador    text,
  estado     text default 'Pendiente'
);

-- Rutas (A:H -> sesion, fecha, hora, comprador, lat, lng, tipo, notas)  [append-only, opcional GPS]
create table if not exists public.rutas (
  seq       bigint generated always as identity primary key,
  sesion    text,
  fecha     text,
  hora      text,
  comprador text,
  lat       text,
  lng       text,
  tipo      text,
  notas     text
);

-- 👤 Usuarios (A:E -> id, usuario, password, nombre, rol)
create table if not exists public.usuarios (
  seq      bigint generated always as identity primary key,
  id       text,
  usuario  text,
  password text,
  nombre   text,
  rol      text default 'comprador'
);

-- ⚙️ Config (A:B -> key, value)  [historial de permisos, append-only]
create table if not exists public.config (
  seq   bigint generated always as identity primary key,
  key   text,
  value text
);

-- ============================================================
-- RLS  (Fase 1: equivalente al modelo actual de Google Sheets,
--       donde la apiKey ya da lectura a toda la hoja. Ver nota
--       de seguridad al final: recomiendo endurecer login luego.)
-- ============================================================
do $$
declare t text;
begin
  foreach t in array array['catalogo','proveedores','compras','fondos','bitacora','pedidos','rutas','usuarios','config']
  loop
    execute format('alter table public.%I enable row level security;', t);
    execute format('drop policy if exists anon_all on public.%I;', t);
    execute format($p$create policy anon_all on public.%I for all to anon using (true) with check (true);$p$, t);
  end loop;
end $$;

-- ============================================================
-- NOTA DE SEGURIDAD (leer):
-- Con la anon key pública (GitHub Pages) y estas políticas, cualquiera
-- con la anon key podría leer la tabla usuarios (incluye contraseñas),
-- igual que hoy con la apiKey de Google. Recomendado como paso 2 de
-- endurecimiento (sin romper nada): guardar contraseñas con hash y usar
-- una función RPC login() que valide del lado del servidor y no exponga
-- el hash. Lo puedo implementar cuando apruebes la Fase 1.
-- ============================================================
