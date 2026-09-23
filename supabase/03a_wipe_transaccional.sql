-- ============================================================
-- PASO 1 del cambio a producción (correr con RLS aún abierto)
-- Limpia SOLO las tablas transaccionales para re-migrar fresco
-- desde la hoja actual. NO toca 'usuarios'.
-- ============================================================
truncate table public.catalogo, public.proveedores, public.compras,
               public.fondos, public.bitacora, public.pedidos,
               public.rutas, public.config
  restart identity;
