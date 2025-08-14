// Browser-compatible authentication utilities
export const hashPassword = async (password: string): Promise<string> => {
  // Simple browser-compatible hash for demo purposes
  const encoder = new TextEncoder()
  const data = encoder.encode(password + "gold-salt-2024")
  const hashBuffer = await crypto.subtle.digest("SHA-256", data)
  const hashArray = Array.from(new Uint8Array(hashBuffer))
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("")
}

export const verifyPassword = async (password: string, hash: string): Promise<boolean> => {
  const passwordHash = await hashPassword(password)
  return passwordHash === hash
}

export const generateToken = (userId: string): string => {
  // Simple token for demo - in production use proper JWT
  const payload = {
    userId,
    exp: Date.now() + 24 * 60 * 60 * 1000, // 24 hours
  }
  return btoa(JSON.stringify(payload))
}

export const verifyToken = (token: string): { userId: string } | null => {
  try {
    const payload = JSON.parse(atob(token))
    if (payload.exp < Date.now()) return null
    return { userId: payload.userId }
  } catch {
    return null
  }
}
