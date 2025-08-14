import { type NextRequest, NextResponse } from "next/server"
import { holdingsQueries, priceQueries } from "@/lib/database"

export async function GET(request: NextRequest) {
  try {
    const userId = request.headers.get("x-user-id")
    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    }

    // Get user's holdings
    const holdings = holdingsQueries.getByUserId(Number.parseInt(userId))

    // Get portfolio totals
    const totals = holdingsQueries.getTotalValue(Number.parseInt(userId))

    // Get current gold price
    const currentPrice = priceQueries.getLatest()

    // Calculate current portfolio value
    const currentValue = holdings.reduce((total, holding) => {
      return total + holding.weight_grams * (currentPrice?.price_per_gram_usd || 0)
    }, 0)

    // Calculate profit/loss
    const totalInvestment = totals?.total_investment || 0
    const profitLoss = currentValue - totalInvestment
    const profitLossPercentage = totalInvestment > 0 ? (profitLoss / totalInvestment) * 100 : 0

    return NextResponse.json({
      holdings,
      summary: {
        totalWeight: totals?.total_weight || 0,
        totalInvestment,
        currentValue,
        profitLoss,
        profitLossPercentage,
        currentGoldPrice: currentPrice?.price_per_gram_usd || 0,
      },
    })
  } catch (error) {
    console.error("Portfolio API error:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
