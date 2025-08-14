"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { format } from "date-fns"
import { TrendingUp, TrendingDown } from "lucide-react"

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

interface TransactionHistoryProps {
  transactions: Transaction[]
}

export function TransactionHistory({ transactions }: TransactionHistoryProps) {
  const getTransactionIcon = (type: string) => {
    return type === "buy" ? (
      <TrendingDown className="h-4 w-4 text-green-600" />
    ) : (
      <TrendingUp className="h-4 w-4 text-red-600" />
    )
  }

  const getTransactionColor = (type: string) => {
    return type === "buy"
      ? "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200"
      : "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
  }

  const getGoldTypeColor = (type: string) => {
    switch (type.toLowerCase()) {
      case "bar":
        return "bg-primary text-primary-foreground"
      case "coin":
        return "bg-secondary text-secondary-foreground"
      case "jewelry":
        return "bg-accent text-accent-foreground"
      case "etf":
        return "bg-muted text-muted-foreground"
      default:
        return "bg-muted text-muted-foreground"
    }
  }

  return (
    <Card className="border-border/50 shadow-sm">
      <CardHeader>
        <CardTitle className="text-xl font-semibold text-foreground">Transaction History</CardTitle>
      </CardHeader>
      <CardContent>
        {transactions.length === 0 ? (
          <div className="text-center py-8">
            <p className="text-muted-foreground">No transactions found. Start by adding your first transaction!</p>
          </div>
        ) : (
          <div className="space-y-4">
            {transactions.map((transaction) => (
              <div
                key={transaction.id}
                className="flex items-center justify-between p-4 border border-border rounded-lg hover:bg-muted/50 transition-colors"
              >
                <div className="flex items-center space-x-4">
                  <div className="flex items-center space-x-2">
                    {getTransactionIcon(transaction.transaction_type)}
                    <Badge className={getTransactionColor(transaction.transaction_type)}>
                      {transaction.transaction_type.toUpperCase()}
                    </Badge>
                  </div>
                  <div>
                    <div className="flex items-center space-x-2">
                      <Badge className={getGoldTypeColor(transaction.gold_type)}>{transaction.gold_type}</Badge>
                      <span className="font-medium text-foreground">{transaction.weight_grams.toFixed(3)}g</span>
                    </div>
                    <p className="text-sm text-muted-foreground">
                      {format(new Date(transaction.transaction_date), "MMM dd, yyyy")} • $
                      {transaction.price_per_gram.toFixed(2)}/g
                    </p>
                    {transaction.notes && <p className="text-sm text-muted-foreground mt-1">{transaction.notes}</p>}
                  </div>
                </div>
                <div className="text-right">
                  <p className="font-semibold text-foreground">${transaction.total_amount.toFixed(2)}</p>
                  <p className="text-sm text-muted-foreground">Total</p>
                </div>
              </div>
            ))}
          </div>
        )}
      </CardContent>
    </Card>
  )
}
