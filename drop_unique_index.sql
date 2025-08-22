-- Удаление уникального индекса для разрешения дубликатов позиций в заказе
-- Выполните этот скрипт в Supabase SQL Editor

DROP INDEX IF EXISTS uq_food_order_item;

-- Проверка что индекс удалён
SELECT indexname FROM pg_indexes WHERE tablename = 'food_order_items';
