// Environment configuration
export const config = {
  isDevelopment: process.env.NODE_ENV === "development",
  isProduction: process.env.NODE_ENV === "production",
  isTest: process.env.NODE_ENV === "test",

  port: process.env.PORT || 3000,
  jwtSecret: process.env.JWT_SECRET,
  appUrl: process.env.NEXT_PUBLIC_APP_URL,
  databasePath: process.env.DATABASE_PATH,

  // Database settings
  database: {
    maxConnections: process.env.NODE_ENV === "production" ? 10 : 5,
    timeout: 30000,
    busyTimeout: 30000,
  },

  // Security settings
  security: {
    bcryptRounds: process.env.NODE_ENV === "production" ? 12 : 10,
    jwtExpiresIn: "7d",
    sessionTimeout: 24 * 60 * 60 * 1000, // 24 hours
  },
}
