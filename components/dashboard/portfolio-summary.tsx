"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { TrendingUp, TrendingDown, Weight, DollarSign } from "lucide-react"

interface PortfolioSummaryProps {
  summary: {
    totalWeight: number
    totalInvestment: number
    currentValue: number
    profitLoss: number
    profitLossPercentage: number
    currentGoldPrice: number
  }
}

export function PortfolioSummary({ summary }: PortfolioSummaryProps) {
  const isProfit = summary.profitLoss >= 0

  return (
    <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
      <Card className="border-border/50 shadow-sm">
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium text-muted-foreground">Total Weight</CardTitle>
          <Weight className="h-4 w-4 text-primary" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold text-foreground">{summary.totalWeight.toFixed(2)}g</div>
          <p className="text-xs text-muted-foreground">Gold in portfolio</p>
        </CardContent>
      </Card>

      <Card className="border-border/50 shadow-sm">
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium text-muted-foreground">Current Value</CardTitle>
          <DollarSign className="h-4 w-4 text-primary" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold text-foreground">${summary.currentValue.toFixed(2)}</div>
          <p className="text-xs text-muted-foreground">At ${summary.currentGoldPrice.toFixed(2)}/g</p>
        </CardContent>
      </Card>

      <Card className="border-border/50 shadow-sm">
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium text-muted-foreground">Total Investment</CardTitle>
          <DollarSign className="h-4 w-4 text-muted-foreground" />
        </CardHeader>
        <CardContent>
          <div className="text-2xl font-bold text-foreground">${summary.totalInvestment.toFixed(2)}</div>
          <p className="text-xs text-muted-foreground">Original cost basis</p>
        </CardContent>
      </Card>

      <Card className="border-border/50 shadow-sm">
        <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
          <CardTitle className="text-sm font-medium text-muted-foreground">Profit/Loss</CardTitle>
          {isProfit ? (
            <TrendingUp className="h-4 w-4 text-green-600" />
          ) : (
            <TrendingDown className="h-4 w-4 text-red-600" />
          )}
        </CardHeader>
        <CardContent>
          <div className={`text-2xl font-bold ${isProfit ? "text-green-600" : "text-red-600"}`}>
            {isProfit ? "+" : ""}${summary.profitLoss.toFixed(2)}
          </div>
          <p className={`text-xs ${isProfit ? "text-green-600" : "text-red-600"}`}>
            {isProfit ? "+" : ""}
            {summary.profitLossPercentage.toFixed(2)}%
          </p>
        </CardContent>
      </Card>
    </div>
  )
}
