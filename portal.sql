-- ============================================================
-- Portal de clientes Contador'ate — tablas, seguridad y datos iniciales
-- Ejecutar UNA vez en Supabase > SQL Editor (proyecto rddqovxastacbvhhwggv)
-- ============================================================

-- 1. Tablas
create table if not exists public.portal_noticias (
  id          uuid primary key default gen_random_uuid(),
  fecha       date not null default current_date,
  categoria   text not null,
  titulo      text not null,
  resumen     text not null,
  detalle     text,
  publicada   boolean not null default true,
  creado      timestamptz not null default now()
);

create table if not exists public.portal_apps (
  id          uuid primary key default gen_random_uuid(),
  nombre      text not null,
  categoria   text not null,
  descripcion text not null,
  url         text,
  icono       text not null default 'app',
  orden       int  not null default 0,
  activa      boolean not null default true
);

create table if not exists public.portal_redes (
  id     uuid primary key default gen_random_uuid(),
  red    text not null,
  url    text not null,
  orden  int  not null default 0
);

-- Quién puede administrar el portal (por correo de Supabase Auth)
create table if not exists public.portal_admins (
  email text primary key
);

-- 2. Seguridad: cualquiera lee lo publicado; solo administradores escriben
alter table public.portal_noticias enable row level security;
alter table public.portal_apps     enable row level security;
alter table public.portal_redes    enable row level security;
alter table public.portal_admins   enable row level security;  -- sin políticas: nadie la lee desde la web

create or replace function public.portal_es_admin()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select exists (
    select 1 from public.portal_admins
    where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;

revoke all on function public.portal_es_admin() from public;
grant execute on function public.portal_es_admin() to anon, authenticated;

drop policy if exists "noticias publicas"   on public.portal_noticias;
drop policy if exists "noticias admin"      on public.portal_noticias;
drop policy if exists "apps publicas"       on public.portal_apps;
drop policy if exists "apps admin"          on public.portal_apps;
drop policy if exists "redes publicas"      on public.portal_redes;
drop policy if exists "redes admin"         on public.portal_redes;

create policy "noticias publicas" on public.portal_noticias for select using (publicada);
create policy "noticias admin"    on public.portal_noticias for all to authenticated
  using (public.portal_es_admin()) with check (public.portal_es_admin());

create policy "apps publicas" on public.portal_apps for select using (activa);
create policy "apps admin"    on public.portal_apps for all to authenticated
  using (public.portal_es_admin()) with check (public.portal_es_admin());

create policy "redes publicas" on public.portal_redes for select using (true);
create policy "redes admin"    on public.portal_redes for all to authenticated
  using (public.portal_es_admin()) with check (public.portal_es_admin());

-- 3. Administrador del portal (debe existir también en Authentication > Users)
insert into public.portal_admins (email) values ('contadorate@gmail.com')
on conflict do nothing;

-- 4. Datos iniciales (solo si las tablas están vacías)
insert into public.portal_apps (nombre, categoria, descripcion, url, icono, orden)
select * from (values
  ('FacturaPro', 'Facturación', 'Facturas, cartera, recibos de caja, tesorería e informes por centro de costo.', 'https://contadorate-org.github.io/facturapro/', 'invoice', 1),
  ('RentaControl', 'Arrendamientos', 'Control de inmuebles en arriendo y Airbnb: reservas, ocupación, ingresos y gastos.', 'https://contadorate-org.github.io/rentacontrol2026/', 'home', 2),
  ('EF Manager', 'Financiero', 'Consulte sus estados financieros con comparativos por periodo.', 'https://efmanager.vercel.app/', 'chart', 3),
  ('Costeo de Importaciones', 'Comercio exterior', 'Costeo por importación: gastos, anticipos y diferencia en cambio.', 'https://contadorate-org.github.io/costeo-importaciones/', 'ship', 4),
  ('Agenda Contador''ate', 'Gestión', 'Tareas, reuniones y recordatorios con notificaciones en el celular.', null, 'calendar', 5)
) as v(nombre, categoria, descripcion, url, icono, orden)
where not exists (select 1 from public.portal_apps);

insert into public.portal_noticias (fecha, categoria, titulo, resumen, detalle)
select * from (values
  (date '2026-10-28', 'Tributario', 'Cierre del calendario de renta de personas naturales 2025',
   'Terminaron los vencimientos de la declaración de renta de personas naturales. Si quedó pendiente, contáctenos para evaluar la presentación extemporánea y la sanción aplicable.',
   'La declaración presentada fuera de plazo genera sanción por extemporaneidad (art. 641 E.T.) e intereses moratorios si hay saldo a pagar. Mientras más pronto se presente, menor es la sanción.'),
  (date '2026-10-20', 'Exógena', 'Prepare desde ahora la información exógena del año gravable 2026',
   'Revise que sus terceros tengan NIT, dirección y municipio completos en su software contable. Esto evita reprocesos en el reporte del próximo año.', null),
  (date '2026-10-10', 'Laboral', 'Reducción de la jornada laboral: lo que cambia en su nómina',
   'La Ley 2101 de 2021 continúa la reducción gradual de la jornada máxima semanal. Le ayudamos a revisar turnos, horas extra y recargos.',
   'Revise los contratos y el reglamento interno de trabajo para ajustar la jornada a la fecha de cada etapa de la reducción.'),
  (date '2026-10-01', 'La firma', 'Nuevo portal de clientes Contador''ate',
   'Desde esta página puede entrar a todas las aplicaciones que usamos con su empresa. Guarde el enlace en sus favoritos o en la pantalla de inicio de su celular.', null)
) as v(fecha, categoria, titulo, resumen, detalle)
where not exists (select 1 from public.portal_noticias);

insert into public.portal_redes (red, url, orden)
select 'WhatsApp', 'https://wa.me/573225687714', 1
where not exists (select 1 from public.portal_redes);
