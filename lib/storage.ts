// Hybrid storage system that works in browser and server environments
export interface User {
  id: number
  email: string
  fullName: string
  passwordHash?: string
}

export interface Transaction {
  id: number
  userId: number
  type: "buy" | "sell"
  goldType: string
  weight: number
  pricePerOz: number
  totalValue: number
  date: string
}

export interface Portfolio {
  totalValue: number
  totalWeight: number
  holdings: Array<{
    goldType: string
    weight: number
    avgPrice: number
    currentValue: number
  }>
}

// Browser-compatible storage using localStorage
class LocalStorage {
  private getItem<T>(key: string): T[] {
    if (typeof window === "undefined") return []
    const item = localStorage.getItem(key)
    return item ? JSON.parse(item) : []
  }

  private setItem<T>(key: string, data: T[]): void {
    if (typeof window === "undefined") return
    localStorage.setItem(key, JSON.stringify(data))
  }

  private initializeDemoData(): void {
    if (typeof window === "undefined") return

    // Initialize demo user if no users exist
    const users = this.getUsers()
    if (users.length === 0) {
      this.createUser("demo@goldbooks.com", "demo123", "Demo User")

      // Add some demo transactions
      const demoUserId = Date.now()
      const transactions: Transaction[] = [
        {
          id: Date.now() + 1,
          userId: demoUserId,
          type: "buy",
          goldType: "Gold Bars",
          weight: 10.0,
          pricePerOz: 1950,
          totalValue: 19500,
          date: "2024-12-01",
        },
        {
          id: Date.now() + 2,
          userId: demoUserId,
          type: "buy",
          goldType: "Gold Coins",
          weight: 5.2,
          pricePerOz: 2000,
          totalValue: 10400,
          date: "2024-12-10",
        },
      ]
      this.setItem("gold_app_transactions", transactions)
    }
  }

  // User operations
  getUsers(): User[] {
    this.initializeDemoData()
    return this.getItem<User>("gold_app_users")
  }

  createUser(email: string, passwordHash: string, fullName: string): User {
    const users = this.getUsers()
    const newUser: User = {
      id: Date.now(),
      email,
      fullName,
      passwordHash,
    }
    users.push(newUser)
    this.setItem("gold_app_users", users)
    return newUser
  }

  findUserByEmail(email: string): User | null {
    const users = this.getUsers()
    return users.find((u) => u.email === email) || null
  }

  // Transaction operations
  getTransactions(userId?: number): Transaction[] {
    const transactions = this.getItem<Transaction>("gold_app_transactions")
    return userId ? transactions.filter((t) => t.userId === userId) : transactions
  }

  createTransaction(transaction: Omit<Transaction, "id">): Transaction {
    const transactions = this.getTransactions()
    const newTransaction: Transaction = {
      ...transaction,
      id: Date.now(),
    }
    transactions.push(newTransaction)
    this.setItem("gold_app_transactions", transactions)
    return newTransaction
  }

  // Portfolio calculations
  getPortfolio(userId: number): Portfolio {
    const transactions = this.getTransactions(userId)
    const holdings = new Map<string, { weight: number; totalCost: number }>()

    transactions.forEach((t) => {
      const current = holdings.get(t.goldType) || { weight: 0, totalCost: 0 }
      if (t.type === "buy") {
        current.weight += t.weight
        current.totalCost += t.totalValue
      } else {
        current.weight -= t.weight
        current.totalCost -= (current.totalCost / current.weight) * t.weight
      }
      holdings.set(t.goldType, current)
    })

    const currentGoldPrice = 2000 // Mock current price
    let totalValue = 0
    let totalWeight = 0

    const holdingsArray = Array.from(holdings.entries()).map(([goldType, data]) => {
      const currentValue = data.weight * currentGoldPrice
      totalValue += currentValue
      totalWeight += data.weight
      return {
        goldType,
        weight: data.weight,
        avgPrice: data.totalCost / data.weight,
        currentValue,
      }
    })

    return {
      totalValue,
      totalWeight,
      holdings: holdingsArray,
    }
  }
}

// API-based storage for production
class ApiStorage {
  private async request<T>(endpoint: string, options?: RequestInit): Promise<T> {
    const response = await fetch(`/api${endpoint}`, {
      headers: {
        "Content-Type": "application/json",
        ...options?.headers,
      },
      ...options,
    })

    if (!response.ok) {
      throw new Error(`API request failed: ${response.statusText}`)
    }

    return response.json()
  }

  async getPortfolio(userId: number): Promise<Portfolio> {
    return this.request<Portfolio>(`/portfolio?userId=${userId}`)
  }

  async createTransaction(transaction: Omit<Transaction, "id">): Promise<Transaction> {
    return this.request<Transaction>("/transactions", {
      method: "POST",
      body: JSON.stringify(transaction),
    })
  }

  async getTransactions(userId: number): Promise<Transaction[]> {
    return this.request<Transaction[]>(`/transactions?userId=${userId}`)
  }

  async authenticateUser(email: string, password: string): Promise<User | null> {
    try {
      return await this.request<User>("/auth/login", {
        method: "POST",
        body: JSON.stringify({ email, password }),
      })
    } catch {
      return null
    }
  }

  async registerUser(email: string, password: string, fullName: string): Promise<User | null> {
    try {
      return await this.request<User>("/auth/register", {
        method: "POST",
        body: JSON.stringify({ email, password, fullName }),
      })
    } catch {
      return null
    }
  }
}

// Hybrid storage with fallback
class HybridStorage {
  private localStorage = new LocalStorage()
  private apiStorage = new ApiStorage()
  private useApi = typeof window !== "undefined" && window.location.hostname !== "localhost"

  async getPortfolio(userId: number): Promise<Portfolio> {
    if (this.useApi) {
      try {
        return await this.apiStorage.getPortfolio(userId)
      } catch {
        // Fallback to local storage
        return this.localStorage.getPortfolio(userId)
      }
    }
    return this.localStorage.getPortfolio(userId)
  }

  async createTransaction(transaction: Omit<Transaction, "id">): Promise<Transaction> {
    if (this.useApi) {
      try {
        return await this.apiStorage.createTransaction(transaction)
      } catch {
        // Fallback to local storage
        return this.localStorage.createTransaction(transaction)
      }
    }
    return this.localStorage.createTransaction(transaction)
  }

  async getTransactions(userId: number): Promise<Transaction[]> {
    if (this.useApi) {
      try {
        return await this.apiStorage.getTransactions(userId)
      } catch {
        return this.localStorage.getTransactions(userId)
      }
    }
    return this.localStorage.getTransactions(userId)
  }

  async authenticateUser(email: string, password: string): Promise<User | null> {
    if (this.useApi) {
      try {
        return await this.apiStorage.authenticateUser(email, password)
      } catch {
        // Simple password check for local storage (demo purposes)
        const user = this.localStorage.findUserByEmail(email)
        return user && user.passwordHash === password ? user : null
      }
    }

    // Local storage authentication (simplified for demo)
    const user = this.localStorage.findUserByEmail(email)
    return user && user.passwordHash === password ? user : null
  }

  async registerUser(email: string, password: string, fullName: string): Promise<User | null> {
    if (this.useApi) {
      try {
        return await this.apiStorage.registerUser(email, password, fullName)
      } catch {
        return this.localStorage.createUser(email, password, fullName)
      }
    }

    return this.localStorage.createUser(email, password, fullName)
  }
}

export const storage = new HybridStorage()
