import { LoginForm } from "@/components/auth/login-form"
import Link from "next/link"

export default function LoginPage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-background via-card to-muted flex items-center justify-center p-4">
      <div className="w-full max-w-md space-y-6">
        <div className="text-center">
          <h1 className="text-3xl font-bold text-foreground mb-2">Welcome to Your Gold Financial Hub</h1>
          <p className="text-muted-foreground">Securely manage your gold investments with elegance</p>
        </div>

        <LoginForm />

        <div className="text-center">
          <p className="text-sm text-muted-foreground">
            {"Don't have an account? "}
            <Link href="/register" className="text-primary hover:text-secondary font-medium transition-colors">
              Create one here
            </Link>
          </p>
        </div>
      </div>
    </div>
  )
}
