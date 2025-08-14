"use client"

import { Button } from "@/components/ui/button"
import { authManager } from "@/lib/auth-client"
import { LogOut, Plus, Home, History } from "lucide-react"
import Link from "next/link"
import { usePathname } from "next/navigation"

export function DashboardHeader() {
  const user = authManager.getCurrentUser()
  const pathname = usePathname()

  const handleLogout = () => {
    authManager.logout()
    window.location.href = "/login"
  }

  return (
    <header className="border-b border-border bg-card/50 backdrop-blur-sm">
      <div className="container mx-auto px-4 py-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <Link href="/dashboard" className="flex items-center space-x-4">
              <div className="w-10 h-10 bg-primary rounded-full flex items-center justify-center gold-shimmer">
                <span className="text-lg font-bold text-primary-foreground">Au</span>
              </div>
              <div>
                <h1 className="text-2xl font-bold text-foreground">Gold Financial Books</h1>
                <p className="text-sm text-muted-foreground">Welcome back, {user?.fullName}</p>
              </div>
            </Link>
          </div>

          <div className="flex items-center space-x-3">
            <div className="flex items-center space-x-2 mr-4">
              <Button
                asChild
                variant={pathname === "/dashboard" ? "default" : "ghost"}
                size="sm"
                className={
                  pathname === "/dashboard"
                    ? "bg-primary text-primary-foreground"
                    : "text-muted-foreground hover:text-foreground"
                }
              >
                <Link href="/dashboard">
                  <Home className="h-4 w-4 mr-2" />
                  Dashboard
                </Link>
              </Button>
              <Button
                asChild
                variant={pathname === "/dashboard/transactions" ? "default" : "ghost"}
                size="sm"
                className={
                  pathname === "/dashboard/transactions"
                    ? "bg-primary text-primary-foreground"
                    : "text-muted-foreground hover:text-foreground"
                }
              >
                <Link href="/dashboard/transactions">
                  <History className="h-4 w-4 mr-2" />
                  Transactions
                </Link>
              </Button>
            </div>

            <Button
              asChild
              variant="outline"
              size="sm"
              className="border-primary text-primary hover:bg-primary hover:text-primary-foreground transition-colors bg-transparent"
            >
              <Link href="/dashboard/transactions">
                <Plus className="h-4 w-4 mr-2" />
                Add Gold
              </Link>
            </Button>
            <Button
              variant="ghost"
              size="sm"
              onClick={handleLogout}
              className="text-muted-foreground hover:text-foreground"
            >
              <LogOut className="h-4 w-4 mr-2" />
              Logout
            </Button>
          </div>
        </div>
      </div>
    </header>
  )
}
