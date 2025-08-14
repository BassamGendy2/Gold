import Link from "next/link"
import { Button } from "@/components/ui/button"

export default function HomePage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-background via-card to-muted flex items-center justify-center">
      <div className="text-center space-y-8 max-w-2xl mx-auto px-4">
        <div className="space-y-4">
          <div className="mx-auto w-24 h-24 bg-primary rounded-full flex items-center justify-center gold-shimmer">
            <span className="text-4xl font-bold text-primary-foreground">Au</span>
          </div>
          <h1 className="text-5xl font-bold text-foreground">Gold Financial Books</h1>
          <p className="text-xl text-muted-foreground">
            Securely manage your gold investments with elegance and precision
          </p>
        </div>

        <div className="flex flex-col sm:flex-row gap-4 justify-center">
          <Button asChild size="lg" className="bg-primary hover:bg-secondary text-primary-foreground font-semibold">
            <Link href="/login">Sign In</Link>
          </Button>
          <Button
            asChild
            variant="outline"
            size="lg"
            className="border-primary text-primary hover:bg-primary hover:text-primary-foreground bg-transparent"
          >
            <Link href="/register">Create Account</Link>
          </Button>
        </div>

        <div className="grid md:grid-cols-3 gap-6 mt-12">
          <div className="text-center space-y-2">
            <div className="w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center mx-auto">
              <span className="text-primary font-bold">📊</span>
            </div>
            <h3 className="font-semibold text-foreground">Portfolio Tracking</h3>
            <p className="text-sm text-muted-foreground">Monitor your gold investments in real-time</p>
          </div>
          <div className="text-center space-y-2">
            <div className="w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center mx-auto">
              <span className="text-primary font-bold">🔒</span>
            </div>
            <h3 className="font-semibold text-foreground">Secure Storage</h3>
            <p className="text-sm text-muted-foreground">Your financial data is encrypted and protected</p>
          </div>
          <div className="text-center space-y-2">
            <div className="w-12 h-12 bg-primary/10 rounded-lg flex items-center justify-center mx-auto">
              <span className="text-primary font-bold">📈</span>
            </div>
            <h3 className="font-semibold text-foreground">Market Insights</h3>
            <p className="text-sm text-muted-foreground">Stay updated with gold market trends</p>
          </div>
        </div>
      </div>
    </div>
  )
}
