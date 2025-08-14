// Development data seeder
import { getDatabase, userQueries, holdingsQueries, transactionQueries } from "../lib/database.js"
import bcrypt from "bcryptjs"

async function seedDevData() {
  console.log("Seeding development data...")

  try {
    // Create test user
    const hashedPassword = await bcrypt.hash("password123", 10)
    const user = userQueries.create("test@example.com", hashedPassword, "Test User")
    const userId = user.lastInsertRowid

    console.log("Created test user:", userId)

    // Add sample gold holdings
    const holdings = [
      {
        userId,
        goldType: "Gold Coin",
        weightGrams: 31.1,
        purity: 0.999,
        purchasePricePerGram: 65.5,
        purchaseDate: "2024-01-15",
        description: "1 oz American Gold Eagle",
        storageLocation: "Home Safe",
        certificateNumber: "AGE-2024-001",
      },
      {
        userId,
        goldType: "Gold Bar",
        weightGrams: 100,
        purity: 0.9999,
        purchasePricePerGram: 64.8,
        purchaseDate: "2024-02-20",
        description: "100g PAMP Suisse Gold Bar",
        storageLocation: "Bank Vault",
        certificateNumber: "PAMP-100-2024",
      },
    ]

    holdings.forEach((holding) => {
      holdingsQueries.create(holding)
    })

    // Add sample transactions
    const transactions = [
      {
        userId,
        transactionType: "BUY",
        goldType: "Gold Coin",
        weightGrams: 31.1,
        pricePerGram: 65.5,
        totalAmount: 2037.05,
        transactionDate: "2024-01-15",
        notes: "First gold purchase - American Eagle",
      },
      {
        userId,
        transactionType: "BUY",
        goldType: "Gold Bar",
        weightGrams: 100,
        pricePerGram: 64.8,
        totalAmount: 6480.0,
        transactionDate: "2024-02-20",
        notes: "Investment grade gold bar",
      },
    ]

    transactions.forEach((transaction) => {
      transactionQueries.create(transaction)
    })

    // Add sample gold prices
    const prices = [
      { pricePerGram: 65.2, priceDate: "2024-01-01", source: "Market Data" },
      { pricePerGram: 66.1, priceDate: "2024-02-01", source: "Market Data" },
      { pricePerGram: 67.3, priceDate: "2024-03-01", source: "Market Data" },
    ]

    const db = getDatabase()
    const priceStmt = db.prepare(`
      INSERT INTO gold_prices (price_per_gram, price_date, source)
      VALUES (?, ?, ?)
    `)

    prices.forEach((price) => {
      priceStmt.run(price.pricePerGram, price.priceDate, price.source)
    })

    console.log("✅ Development data seeded successfully!")
    console.log("Test login: test@example.com / password123")
  } catch (error) {
    console.error("❌ Error seeding data:", error)
  }
}

seedDevData()
