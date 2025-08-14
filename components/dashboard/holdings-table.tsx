"use client"

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { format } from "date-fns"

interface Holding {
  id: number
  gold_type: string
  weight_grams: number
  purity: number
  purchase_price_per_gram: number
  purchase_date: string
  description: string
  storage_location: string
}

interface HoldingsTableProps {
  holdings: Holding[]
  currentGoldPrice: number
}

export function HoldingsTable({ holdings, currentGoldPrice }: HoldingsTableProps) {
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
        <CardTitle className="text-xl font-semibold text-foreground">Gold Holdings</CardTitle>
      </CardHeader>
      <CardContent>
        {holdings.length === 0 ? (
          <div className="text-center py-8">
            <p className="text-muted-foreground">No gold holdings found. Start building your portfolio!</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-border">
                  <th className="text-left py-3 px-2 text-sm font-medium text-muted-foreground">Type</th>
                  <th className="text-left py-3 px-2 text-sm font-medium text-muted-foreground">Weight</th>
                  <th className="text-left py-3 px-2 text-sm font-medium text-muted-foreground">Purity</th>
                  <th className="text-left py-3 px-2 text-sm font-medium text-muted-foreground">Purchase Price</th>
                  <th className="text-left py-3 px-2 text-sm font-medium text-muted-foreground">Current Value</th>
                  <th className="text-left py-3 px-2 text-sm font-medium text-muted-foreground">Date</th>
                  <th className="text-left py-3 px-2 text-sm font-medium text-muted-foreground">Location</th>
                </tr>
              </thead>
              <tbody>
                {holdings.map((holding) => {
                  const currentValue = holding.weight_grams * currentGoldPrice
                  const purchaseValue = holding.weight_grams * holding.purchase_price_per_gram
                  const profitLoss = currentValue - purchaseValue
                  const isProfit = profitLoss >= 0

                  return (
                    <tr key={holding.id} className="border-b border-border/50 hover:bg-muted/50 transition-colors">
                      <td className="py-3 px-2">
                        <Badge className={getGoldTypeColor(holding.gold_type)}>{holding.gold_type}</Badge>
                      </td>
                      <td className="py-3 px-2 text-sm text-foreground">{holding.weight_grams.toFixed(2)}g</td>
                      <td className="py-3 px-2 text-sm text-foreground">{(holding.purity * 100).toFixed(1)}%</td>
                      <td className="py-3 px-2 text-sm text-foreground">
                        ${holding.purchase_price_per_gram.toFixed(2)}/g
                      </td>
                      <td className="py-3 px-2">
                        <div className="text-sm text-foreground">${currentValue.toFixed(2)}</div>
                        <div className={`text-xs ${isProfit ? "text-green-600" : "text-red-600"}`}>
                          {isProfit ? "+" : ""}${profitLoss.toFixed(2)}
                        </div>
                      </td>
                      <td className="py-3 px-2 text-sm text-muted-foreground">
                        {format(new Date(holding.purchase_date), "MMM dd, yyyy")}
                      </td>
                      <td className="py-3 px-2 text-sm text-muted-foreground">{holding.storage_location}</td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        )}
      </CardContent>
    </Card>
  )
}
