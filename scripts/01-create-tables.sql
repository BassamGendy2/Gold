-- Gold Financial Books Database Schema
-- Create users table for authentication
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  full_name TEXT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Create gold_holdings table for portfolio tracking
CREATE TABLE IF NOT EXISTS gold_holdings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  gold_type TEXT NOT NULL, -- 'bar', 'coin', 'jewelry', 'etf'
  weight_grams DECIMAL(10,3) NOT NULL,
  purity DECIMAL(5,3) NOT NULL, -- 0.999 for 24k, 0.916 for 22k, etc.
  purchase_price_per_gram DECIMAL(10,2) NOT NULL,
  purchase_date DATE NOT NULL,
  description TEXT,
  storage_location TEXT,
  certificate_number TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create transactions table for buy/sell records
CREATE TABLE IF NOT EXISTS transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('buy', 'sell')),
  gold_type TEXT NOT NULL,
  weight_grams DECIMAL(10,3) NOT NULL,
  price_per_gram DECIMAL(10,2) NOT NULL,
  total_amount DECIMAL(12,2) NOT NULL,
  transaction_date DATE NOT NULL,
  notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create gold_prices table for historical price tracking
CREATE TABLE IF NOT EXISTS gold_prices (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  price_date DATE UNIQUE NOT NULL,
  price_per_gram_usd DECIMAL(10,2) NOT NULL,
  price_per_ounce_usd DECIMAL(10,2) NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Insert some sample gold price data
INSERT OR IGNORE INTO gold_prices (price_date, price_per_gram_usd, price_per_ounce_usd) VALUES
('2024-01-01', 65.50, 2037.00),
('2024-02-01', 67.20, 2090.00),
('2024-03-01', 69.80, 2171.00),
('2024-04-01', 71.30, 2218.00),
('2024-05-01', 73.90, 2299.00),
('2024-06-01', 75.20, 2339.00);
