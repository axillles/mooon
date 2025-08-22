-- Примеры заполнения меню

insert into food_categories (name, position, is_active) values
  ('Попкорн', 1, true),
  ('Напитки', 2, true),
  ('Снэки', 3, true)
on conflict do nothing;

-- Пример блюд (price в BYN)
insert into foods (category_id, name, description, image_url, price, size_prices, is_active)
values
  ((select id from food_categories where name='Попкорн' limit 1), 'Попкорн малый', 'Сливочное масло', null, 6.90, 
   '{"S": {"price": 6.90, "volume": "Маленький"}, "M": {"price": 8.90, "volume": "Средний"}, "L": {"price": 10.90, "volume": "Большой"}}'::jsonb, true),
  ((select id from food_categories where name='Попкорн' limit 1), 'Попкорн средний', 'Карамель', null, 8.90, 
   '{"S": {"price": 8.90, "volume": "Маленький"}, "M": {"price": 10.90, "volume": "Средний"}, "L": {"price": 12.90, "volume": "Большой"}}'::jsonb, true),
  ((select id from food_categories where name='Попкорн' limit 1), 'Попкорн большой', 'Сырный', null, 10.90, 
   '{"S": {"price": 10.90, "volume": "Маленький"}, "M": {"price": 12.90, "volume": "Средний"}, "L": {"price": 14.90, "volume": "Большой"}}'::jsonb, true),
  ((select id from food_categories where name='Напитки' limit 1), 'Кола', 'Охлажденная', null, 3.50, 
   '{"S": {"price": 3.50, "volume": "330ml"}, "M": {"price": 4.50, "volume": "500ml"}, "L": {"price": 5.50, "volume": "750ml"}}'::jsonb, true),
  ((select id from food_categories where name='Напитки' limit 1), 'Сок', 'В ассортименте', null, 3.20, 
   '{"S": {"price": 3.20, "volume": "250ml"}, "M": {"price": 4.20, "volume": "400ml"}, "L": {"price": 5.20, "volume": "600ml"}}'::jsonb, true),
  ((select id from food_categories where name='Снэки' limit 1), 'Начос', 'С сырным соусом', null, 7.50, 
   '{"M": {"price": 7.50, "volume": "Стандарт"}}'::jsonb, true)
on conflict do nothing;


