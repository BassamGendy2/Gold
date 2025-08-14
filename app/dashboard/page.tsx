"use client"

import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import { DashboardHeader } from "@/components/dashboard/dashboard-header"
import { PortfolioSummary } from "@/components/dashboard/portfolio-summary"
import { HoldingsTable } from "@/components/dashboard/holdings-table"
import { storage, type Portfolio } from "@/lib/storage"
import { authManager } from "@/lib/auth-client"

export default function DashboardPage() {
  const [portfolioData, setPortfolioData] = useState<Portfolio | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const router = useRouter()

  useEffect(() => {
    const loadPortfolioData = async () => {
      const user = authManager.getCurrentUser()

      if (!user) {
        router.push("/login")
        return
      }

      try {
        const portfolio = await storage.getPortfolio(user.id)
        setPortfolioData(portfolio)
      } catch (error) {
        console.error("Error loading portfolio:", error)
        setPortfolioData({
          totalValue: 0,
          totalWeight: 0,
          holdings: [],
        })
      } finally {
        setIsLoading(false)
      }
    }

    loadPortfolioData()
  }, [router])

  if (isLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-background via-card to-muted flex items-center justify-center">
        <div className="text-center">
          <div className="w-16 h-16 bg-primary rounded-full flex items-center justify-center mx-auto mb-4 gold-shimmer">
            <span className="text-2xl font-bold text-primary-foreground">Au</span>
          </div>
          <p className="text-muted-foreground">Loading your portfolio...</p>
        </div>
      </div>
    )
  }

  if (!portfolioData) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-background via-card to-muted flex items-center justify-center">
        <div className="text-center">
          <p className="text-muted-foreground">Failed to load portfolio data</p>
        </div>
      </div>
    )
  }

  const summary = {
    totalWeight: portfolioData.totalWeight,
    totalInvestment: portfolioData.holdings.reduce((sum, h) => sum + h.avgPrice * h.weight, 0),
    currentValue: portfolioData.totalValue,
    profitLoss: portfolioData.totalValue - portfolioData.holdings.reduce((sum, h) => sum + h.avgPrice * h.weight, 0),
    profitLossPercentage:
      portfolioData.holdings.reduce((sum, h) => sum + h.avgPrice * h.weight, 0) > 0
        ? ((portfolioData.totalValue - portfolioData.holdings.reduce((sum, h) => sum + h.avgPrice * h.weight, 0)) /
            portfolioData.holdings.reduce((sum, h) => sum + h.avgPrice * h.weight, 0)) *
          100
        : 0,
    currentGoldPrice: 2000, // Mock current price
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-background via-card to-muted">
      <DashboardHeader />

      <main className="container mx-auto px-4 py-8 space-y-8">
        <div className="text-center">
          <h2 className="text-3xl font-bold text-foreground mb-2">Your Gold Portfolio</h2>
          <p className="text-muted-foreground">Track and manage your precious metal investments</p>
        </div>

        <PortfolioSummary summary={summary} />

        <HoldingsTable holdings={portfolioData.holdings} currentGoldPrice={summary.currentGoldPrice} />
      </main>
    </div>
  )
}
