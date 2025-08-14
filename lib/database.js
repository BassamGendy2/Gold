let db
const mockData = {
  users: [],
  holdings: [],
  transactions: [],
  prices: [
    {
      id: 1,
      price_per_gram: 65.5,
      price_date: new Date().toISOString(),
      source: "mock",
    },
  ],
}

// Check if we're in browser environment
const isBrowser = typeof window !== "undefined"

export function getDatabase() {
  if (isBrowser) {
    // Return mock database for browser preview
    return {
      pragma: () => {},
      exec: () => {},
      prepare: (sql) => ({
        run: (...params) => ({ lastInsertRowid: Date.now(), changes: 1 }),
        get: (...params) => {
          // Mock responses based on SQL patterns
          if (sql.includes("SELECT * FROM users WHERE email")) {
            return mockData.users.find((u) => u.email === params[0])
          }
          if (sql.includes("SELECT * FROM users WHERE id")) {
            return mockData.users.find((u) => u.id === params[0])
          }
          if (sql.includes("gold_prices")) {
            return mockData.prices[0]
          }
          return null
        },
        all: (...params) => {
          if (sql.includes("gold_holdings")) {
            return mockData.holdings.filter((h) => h.user_id === params[0])
          }
          if (sql.includes("transactions")) {
            return mockData.transactions.filter((t) => t.user_id === params[0])
          }
          if (sql.includes("gold_prices")) {
            return mockData.prices
          }
          return []
        },
      }),
    }
  }

  // Server-side database logic
  if (!db) {
    try {
      const Database = require("better-sqlite3")
      const { readFileSync } = require("fs")
      const { join } = require("path")

      const isProduction = process.env.NODE_ENV === "production"
      const dbPath =
        process.env.DATABASE_PATH ||
        (isProduction ? "/var/lib/gold-financial/gold_financial.db" : "gold_financial_dev.db")

      db = new Database(dbPath)

      // Enable foreign keys
      db.pragma("foreign_keys = ON")

      if (isProduction) {
        db.pragma("journal_mode = WAL")
        db.pragma("synchronous = NORMAL")
      }

      // Initialize tables if they don't exist
      try {
        const schemaSQL = readFileSync(join(process.cwd(), "scripts", "01-create-tables.sql"), "utf8")
        db.exec(schemaSQL)
        console.log(`Database initialized: ${dbPath}`)
      } catch (error) {
        console.error("Error initializing database:", error)
      }
    } catch (error) {
      console.error("Database initialization failed:", error)
      // Fallback to mock for development
      return getDatabase()
    }
  }

  return db
}

// User operations
export const userQueries = {
  create: (email, passwordHash, fullName) => {
    if (isBrowser) {
      const user = {
        id: Date.now(),
        email,
        password_hash: passwordHash,
        full_name: fullName,
        created_at: new Date().toISOString(),
      }
      mockData.users.push(user)
      return { lastInsertRowid: user.id, changes: 1 }
    }

    const db = getDatabase()
    const stmt = db.prepare(`
      INSERT INTO users (email, password_hash, full_name)
      VALUES (?, ?, ?)
    `)
    return stmt.run(email, passwordHash, fullName)
  },

  findByEmail: (email) => {
    const db = getDatabase()
    const stmt = db.prepare("SELECT * FROM users WHERE email = ?")
    return stmt.get(email)
  },

  findById: (id) => {
    const db = getDatabase()
    const stmt = db.prepare("SELECT * FROM users WHERE id = ?")
    return stmt.get(id)
  },
}

// Gold holdings operations
export const holdingsQueries = {
  getByUserId: (userId) => {
    const db = getDatabase()
    const stmt = db.prepare(`
      SELECT * FROM gold_holdings 
      WHERE user_id = ? 
      ORDER BY purchase_date DESC
    `)
    return stmt.all(userId)
  },

  create: (holding) => {
    if (isBrowser) {
      const newHolding = {
        id: Date.now(),
        ...holding,
        user_id: holding.userId,
        gold_type: holding.goldType,
        weight_grams: holding.weightGrams,
        purchase_price_per_gram: holding.purchasePricePerGram,
        purchase_date: holding.purchaseDate,
        storage_location: holding.storageLocation,
        certificate_number: holding.certificateNumber,
        created_at: new Date().toISOString(),
      }
      mockData.holdings.push(newHolding)
      return { lastInsertRowid: newHolding.id, changes: 1 }
    }

    const db = getDatabase()
    const stmt = db.prepare(`
      INSERT INTO gold_holdings 
      (user_id, gold_type, weight_grams, purity, purchase_price_per_gram, purchase_date, description, storage_location, certificate_number)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `)
    return stmt.run(
      holding.userId,
      holding.goldType,
      holding.weightGrams,
      holding.purity,
      holding.purchasePricePerGram,
      holding.purchaseDate,
      holding.description,
      holding.storageLocation,
      holding.certificateNumber,
    )
  },

  getTotalValue: (userId) => {
    if (isBrowser) {
      const userHoldings = mockData.holdings.filter((h) => h.user_id === userId)
      const totalInvestment = userHoldings.reduce((sum, h) => sum + h.weight_grams * h.purchase_price_per_gram, 0)
      const totalWeight = userHoldings.reduce((sum, h) => sum + h.weight_grams, 0)
      return { total_investment: totalInvestment, total_weight: totalWeight }
    }

    const db = getDatabase()
    const stmt = db.prepare(`
      SELECT 
        SUM(weight_grams * purchase_price_per_gram) as total_investment,
        SUM(weight_grams) as total_weight
      FROM gold_holdings 
      WHERE user_id = ?
    `)
    return stmt.get(userId)
  },
}

// Transaction operations
export const transactionQueries = {
  getByUserId: (userId) => {
    const db = getDatabase()
    const stmt = db.prepare(`
      SELECT * FROM transactions 
      WHERE user_id = ? 
      ORDER BY transaction_date DESC
    `)
    return stmt.all(userId)
  },

  create: (transaction) => {
    if (isBrowser) {
      const newTransaction = {
        id: Date.now(),
        ...transaction,
        user_id: transaction.userId,
        transaction_type: transaction.transactionType,
        gold_type: transaction.goldType,
        weight_grams: transaction.weightGrams,
        price_per_gram: transaction.pricePerGram,
        total_amount: transaction.totalAmount,
        transaction_date: transaction.transactionDate,
        created_at: new Date().toISOString(),
      }
      mockData.transactions.push(newTransaction)
      return { lastInsertRowid: newTransaction.id, changes: 1 }
    }

    const db = getDatabase()
    const stmt = db.prepare(`
      INSERT INTO transactions 
      (user_id, transaction_type, gold_type, weight_grams, price_per_gram, total_amount, transaction_date, notes)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `)
    return stmt.run(
      transaction.userId,
      transaction.transactionType,
      transaction.goldType,
      transaction.weightGrams,
      transaction.pricePerGram,
      transaction.totalAmount,
      transaction.transactionDate,
      transaction.notes,
    )
  },
}

// Gold price operations
export const priceQueries = {
  getLatest: () => {
    const db = getDatabase()
    const stmt = db.prepare(`
      SELECT * FROM gold_prices 
      ORDER BY price_date DESC 
      LIMIT 1
    `)
    return stmt.get()
  },

  getHistory: (days = 30) => {
    const db = getDatabase()
    const stmt = db.prepare(`
      SELECT * FROM gold_prices 
      ORDER BY price_date DESC 
      LIMIT ?
    `)
    return stmt.all(days)
  },
}
