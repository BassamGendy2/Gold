import { type NextRequest, NextResponse } from "next/server"
import { transactionQueries, holdingsQueries } from "@/lib/database"

export async function GET(request: NextRequest) {
  try {
    const userId = request.headers.get("x-user-id")
    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    }

    const transactions = transactionQueries.getByUserId(Number.parseInt(userId))
    return NextResponse.json({ transactions })
  } catch (error) {
    console.error("Transactions API error:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}

export async function POST(request: NextRequest) {
  try {
    const userId = request.headers.get("x-user-id")
    if (!userId) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 })
    }

    const body = await request.json()
    const {
      transactionType,
      goldType,
      weightGrams,
      pricePerGram,
      transactionDate,
      notes,
      description,
      storageLocation,
      certificateNumber,
      purity,
    } = body

    // Validate required fields
    if (!transactionType || !goldType || !weightGrams || !pricePerGram || !transactionDate) {
      return NextResponse.json({ error: "Missing required fields" }, { status: 400 })
    }

    const totalAmount = weightGrams * pricePerGram

    // Create transaction record
    const transactionResult = transactionQueries.create({
      userId: Number.parseInt(userId),
      transactionType,
      goldType,
      weightGrams: Number.parseFloat(weightGrams),
      pricePerGram: Number.parseFloat(pricePerGram),
      totalAmount,
      transactionDate,
      notes: notes || null,
    })

    // If it's a buy transaction, also add to holdings
    if (transactionType === "buy") {
      holdingsQueries.create({
        userId: Number.parseInt(userId),
        goldType,
        weightGrams: Number.parseFloat(weightGrams),
        purity: Number.parseFloat(purity || 0.999),
        purchasePricePerGram: Number.parseFloat(pricePerGram),
        purchaseDate: transactionDate,
        description: description || null,
        storageLocation: storageLocation || null,
        certificateNumber: certificateNumber || null,
      })
    }

    return NextResponse.json({
      message: "Transaction created successfully",
      transactionId: transactionResult.lastInsertRowid,
    })
  } catch (error) {
    console.error("Transaction creation error:", error)
    return NextResponse.json({ error: "Internal server error" }, { status: 500 })
  }
}
