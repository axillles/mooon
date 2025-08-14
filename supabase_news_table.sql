-- Создание таблицы новостей для mooon
CREATE TABLE IF NOT EXISTS news (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  subtitle TEXT,
  content TEXT,
  image_url VARCHAR(500),
  published_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_active BOOLEAN DEFAULT true,
  priority INTEGER DEFAULT 0, -- для сортировки (0 = обычная, 1 = важная, 2 = срочная)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Индексы для быстрого поиска
CREATE INDEX IF NOT EXISTS idx_news_published_at ON news(published_at DESC);
CREATE INDEX IF NOT EXISTS idx_news_is_active ON news(is_active);
CREATE INDEX IF NOT EXISTS idx_news_priority ON news(priority DESC);

-- RLS (Row Level Security) - разрешаем всем читать активные новости
ALTER TABLE news ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to active news" ON news
  FOR SELECT USING (is_active = true);

-- Триггер для автоматического обновления updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_news_updated_at 
  BEFORE UPDATE ON news 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- Вставка тестовых данных
INSERT INTO news (title, subtitle, content, priority) VALUES
(
  'Снова на больших экранах: ретроспектива Нолана',
  'Только на этой неделе — IMAX показы в mooon',
  'С 15 по 21 декабря в кинотеатрах mooon пройдет ретроспектива фильмов Кристофера Нолана в формате IMAX. В программе: "Интерстеллар", "Начало", "Темный рыцарь" и другие культовые работы режиссера. Билеты уже в продаже!',
  1
),
(
  'Mooon Store открылся в фойе Palazzo',
  'Мерч, сладости и кофе перед сеансом',
  'Новый магазин mooon Store открыл свои двери в фойе кинотеатра Palazzo. Здесь вы найдете фирменный мерч, свежую выпечку, кофе и другие угощения. Идеальное место для встречи перед сеансом!',
  0
),
(
  'Новогодние показы для всей семьи',
  'Специальная программа на каникулах',
  'В новогодние праздники mooon подготовил специальную программу для всей семьи. Анимационные фильмы, комедии и блокбастеры — каждый найдет что-то для себя. Скидки на детские билеты!',
  1
),
(
  'Технология Dolby Atmos в зале Premium',
  'Погружение в звук нового уровня',
  'Зал Premium в mooon Dana Mall теперь оснащен системой Dolby Atmos. Погрузитесь в трехмерный звук и почувствуйте каждый эффект как никогда раньше. Первые показы уже в расписании.',
  0
),
(
  'Программа лояльности: новые бонусы',
  'Больше возможностей для наших гостей',
  'Обновили программу лояльности mooon! Теперь вы можете получать бонусы не только за билеты, но и за покупки в Mooon Store. Накопительные скидки и эксклюзивные предложения ждут вас.',
  2
);
