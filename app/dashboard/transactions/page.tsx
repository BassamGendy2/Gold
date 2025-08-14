"use client"

import { useState, useEffect } from "react"
import { DashboardHeader } from "@/components/dashboard/dashboard-header"
import { AddTransactionForm } from "@/components/transactions/add-transaction-form"
import { TransactionHistory } from "@/components/transactions/transaction-history"
import { Button } from "@/components/ui/button"
import { Plus, History } from "lucide-react"

interface Transaction {
  id: number
  transaction_type: string
  gold_type: string
  weight_grams: number
  price_per_gram: number
  total_amount: number
  transaction_date: string
  notes: string
}

export default function TransactionsPage() {
  const [transactions, setTransactions] = useState<Transaction[]>([])
  const [showAddForm, setShowAddForm] = useState(false)
  const [isLoading, setIsLoading] = useState(true)

  const fetchTransactions = async () => {
    try {
      const response = await fetch("/api/transactions")
      if (response.ok) {
        const data = await response.json()
        setTransactions(data.transactions)
      }
    } catch (error) {
      console.error("Error fetching transactions:", error)
    } finally {
      setIsLoading(false)
    }
  }

  useEffect(() => {
    fetchTransactions()
  }, [])

  const handleTransactionSuccess = () => {
    setShowAddForm(false)
    fetchTransactions()
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-background via-card to-muted">
      <DashboardHeader />

      <main className="container mx-auto px-4 py-8 space-y-8">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-3xl font-bold text-foreground">Transactions</h2>
            <p className="text-muted-foreground">Manage your gold purchases and sales</p>
          </div>
          <Button
            onClick={() => setShowAddForm(!showAddForm)}
            className="bg-primary hover:bg-secondary text-primary-foreground font-semibold transition-all duration-200 transform hover:scale-105"
          >
            {showAddForm ? (
              <>
                <History className="h-4 w-4 mr-2" />
                View History
              </>
            ) : (
              <>
                <Plus className="h-4 w-4 mr-2" />
                Add Transaction
              </>
            )}
          </Button>
        </div>

        {showAddForm ? (
          <AddTransactionForm onSuccess={handleTransactionSuccess} />
        ) : (
          <TransactionHistory transactions={transactions} />
        )}
      </main>
    </div>
  )
}
