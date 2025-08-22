-- Таблицы меню и заказов в зал

-- Категории блюд (опционально)
create table if not exists food_categories (
  id bigserial primary key,
  name text not null,
  position int default 0,
  is_active boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Блюда
create table if not exists foods (
  id bigserial primary key,
  category_id bigint references food_categories(id) on delete set null,
  name text not null,
  description text,
  image_url text,
  price numeric(8,2) not null,
  size_prices jsonb, -- {"S": {"price": 6.90, "volume": "200ml"}, "M": {"price": 8.90, "volume": "350ml"}, "L": {"price": 10.90, "volume": "450ml"}}
  is_active boolean default true,
  cinema_id bigint references cinemas(id) on delete set null,
  hall_id bigint references halls(id) on delete set null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_foods_active on foods(is_active);
create index if not exists idx_foods_category on foods(category_id);
create index if not exists idx_foods_hall on foods(hall_id);

-- Заказы на еду (один активный на текущий сеанс)
create table if not exists food_orders (
  id bigserial primary key,
  user_id text not null,
  screening_id bigint references screenings(id) on delete cascade,
  seat_row text,
  seat_number int,
  status text not null default 'draft', -- draft | submitted | preparing | delivered | canceled
  total_amount numeric(10,2) not null default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_food_orders_user on food_orders(user_id);
create index if not exists idx_food_orders_screening on food_orders(screening_id);

-- Позиции заказа
create table if not exists food_order_items (
  id bigserial primary key,
  order_id bigint references food_orders(id) on delete cascade,
  food_id bigint references foods(id) on delete restrict,
  quantity int not null check (quantity > 0),
  unit_price numeric(8,2) not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists idx_food_order_items_order on food_order_items(order_id);
-- Удалён уникальный индекс, чтобы разрешить дубликаты позиций в заказе
-- drop он на реальной БД:
-- DROP INDEX IF EXISTS uq_food_order_item;
-- create unique index if not exists uq_food_order_item on food_order_items(order_id, food_id);

-- Триггер для обновления updated_at
create or replace function update_updated_at_column()
returns trigger as $$
begin
  NEW.updated_at = NOW();
  return NEW;
end;
$$ language 'plpgsql';

drop trigger if exists trg_food_categories_updated_at on food_categories;
create trigger trg_food_categories_updated_at
  before update on food_categories
  for each row execute function update_updated_at_column();

drop trigger if exists trg_foods_updated_at on foods;
create trigger trg_foods_updated_at
  before update on foods
  for each row execute function update_updated_at_column();

drop trigger if exists trg_food_orders_updated_at on food_orders;
create trigger trg_food_orders_updated_at
  before update on food_orders
  for each row execute function update_updated_at_column();

drop trigger if exists trg_food_order_items_updated_at on food_order_items;
create trigger trg_food_order_items_updated_at
  before update on food_order_items
  for each row execute function update_updated_at_column();


