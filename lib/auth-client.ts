// Client-side authentication utilities
import { storage, type User } from "./storage"

export interface AuthState {
  user: User | null
  isLoading: boolean
  error: string | null
}

// Simple JWT-like token for client-side (demo purposes)
function createToken(user: User): string {
  return btoa(
    JSON.stringify({
      userId: user.id,
      email: user.email,
      fullName: user.fullName,
      exp: Date.now() + 7 * 24 * 60 * 60 * 1000, // 7 days
    }),
  )
}

function verifyToken(token: string): User | null {
  try {
    const decoded = JSON.parse(atob(token))
    if (decoded.exp < Date.now()) return null
    return {
      id: decoded.userId,
      email: decoded.email,
      fullName: decoded.fullName,
    }
  } catch {
    return null
  }
}

export class AuthManager {
  private currentUser: User | null = null

  constructor() {
    this.loadUserFromStorage()
  }

  private loadUserFromStorage() {
    if (typeof window === "undefined") return
    const token = localStorage.getItem("auth_token")
    if (token) {
      this.currentUser = verifyToken(token)
    }
  }

  private saveUserToStorage(user: User) {
    if (typeof window === "undefined") return
    const token = createToken(user)
    localStorage.setItem("auth_token", token)
  }

  private clearUserFromStorage() {
    if (typeof window === "undefined") return
    localStorage.removeItem("auth_token")
  }

  getCurrentUser(): User | null {
    return this.currentUser
  }

  async login(email: string, password: string): Promise<{ success: boolean; error?: string }> {
    try {
      const user = await storage.authenticateUser(email, password)
      if (user) {
        this.currentUser = user
        this.saveUserToStorage(user)
        return { success: true }
      }
      return { success: false, error: "Invalid credentials" }
    } catch (error) {
      return { success: false, error: "Login failed" }
    }
  }

  async register(email: string, password: string, fullName: string): Promise<{ success: boolean; error?: string }> {
    try {
      const user = await storage.registerUser(email, password, fullName)
      if (user) {
        this.currentUser = user
        this.saveUserToStorage(user)
        return { success: true }
      }
      return { success: false, error: "Registration failed" }
    } catch (error) {
      return { success: false, error: "Registration failed" }
    }
  }

  logout() {
    this.currentUser = null
    this.clearUserFromStorage()
  }

  isAuthenticated(): boolean {
    return this.currentUser !== null
  }
}

export const authManager = new AuthManager()
