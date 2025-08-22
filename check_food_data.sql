-- Проверка данных в таблицах еды
-- Выполните эти запросы в Supabase SQL Editor

-- Проверяем категории
SELECT * FROM food_categories WHERE is_active = true ORDER BY position;

-- Проверяем товары
SELECT 
  f.id,
  f.name,
  f.category_id,
  fc.name as category_name,
  f.is_active,
  f.size_prices
FROM foods f
LEFT JOIN food_categories fc ON f.category_id = fc.id
WHERE f.is_active = true
ORDER BY fc.position, f.name;

-- Проверяем количество товаров по категориям
SELECT 
  fc.name as category_name,
  COUNT(f.id) as items_count
FROM food_categories fc
LEFT JOIN foods f ON fc.id = f.category_id AND f.is_active = true
WHERE fc.is_active = true
GROUP BY fc.id, fc.name
ORDER BY fc.position;
