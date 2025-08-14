"use client"

import type React from "react"

import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Alert, AlertDescription } from "@/components/ui/alert"
import { Loader2, Plus } from "lucide-react"

interface AddTransactionFormProps {
  onSuccess?: () => void
}

export function AddTransactionForm({ onSuccess }: AddTransactionFormProps) {
  const [formData, setFormData] = useState({
    transactionType: "",
    goldType: "",
    weightGrams: "",
    pricePerGram: "",
    purity: "0.999",
    transactionDate: new Date().toISOString().split("T")[0],
    description: "",
    storageLocation: "",
    certificateNumber: "",
    notes: "",
  })
  const [error, setError] = useState("")
  const [isLoading, setIsLoading] = useState(false)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsLoading(true)
    setError("")

    try {
      const response = await fetch("/api/transactions", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(formData),
      })

      const data = await response.json()

      if (response.ok) {
        // Reset form
        setFormData({
          transactionType: "",
          goldType: "",
          weightGrams: "",
          pricePerGram: "",
          purity: "0.999",
          transactionDate: new Date().toISOString().split("T")[0],
          description: "",
          storageLocation: "",
          certificateNumber: "",
          notes: "",
        })
        onSuccess?.()
      } else {
        setError(data.error || "Transaction failed")
      }
    } catch (error) {
      setError("Network error. Please try again.")
    } finally {
      setIsLoading(false)
    }
  }

  const handleInputChange = (field: string, value: string) => {
    setFormData((prev) => ({ ...prev, [field]: value }))
  }

  const totalAmount = Number.parseFloat(formData.weightGrams || "0") * Number.parseFloat(formData.pricePerGram || "0")

  return (
    <Card className="w-full max-w-2xl mx-auto shadow-lg border-border/50">
      <CardHeader className="text-center space-y-2">
        <div className="mx-auto w-12 h-12 bg-primary rounded-full flex items-center justify-center gold-shimmer">
          <Plus className="h-6 w-6 text-primary-foreground" />
        </div>
        <CardTitle className="text-2xl font-bold text-foreground">Add Transaction</CardTitle>
        <CardDescription className="text-muted-foreground">Record a new gold purchase or sale</CardDescription>
      </CardHeader>
      <CardContent>
        <form onSubmit={handleSubmit} className="space-y-6">
          {error && (
            <Alert variant="destructive">
              <AlertDescription>{error}</AlertDescription>
            </Alert>
          )}

          <div className="grid md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="transactionType" className="text-sm font-medium">
                Transaction Type
              </Label>
              <Select
                value={formData.transactionType}
                onValueChange={(value) => handleInputChange("transactionType", value)}
              >
                <SelectTrigger>
                  <SelectValue placeholder="Select type" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="buy">Buy</SelectItem>
                  <SelectItem value="sell">Sell</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="goldType" className="text-sm font-medium">
                Gold Type
              </Label>
              <Select value={formData.goldType} onValueChange={(value) => handleInputChange("goldType", value)}>
                <SelectTrigger>
                  <SelectValue placeholder="Select gold type" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="bar">Gold Bar</SelectItem>
                  <SelectItem value="coin">Gold Coin</SelectItem>
                  <SelectItem value="jewelry">Jewelry</SelectItem>
                  <SelectItem value="etf">ETF</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="grid md:grid-cols-3 gap-4">
            <div className="space-y-2">
              <Label htmlFor="weightGrams" className="text-sm font-medium">
                Weight (grams)
              </Label>
              <Input
                id="weightGrams"
                type="number"
                step="0.001"
                value={formData.weightGrams}
                onChange={(e) => handleInputChange("weightGrams", e.target.value)}
                placeholder="0.000"
                required
                className="transition-all duration-200 focus:ring-2 focus:ring-primary/20"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="pricePerGram" className="text-sm font-medium">
                Price per Gram ($)
              </Label>
              <Input
                id="pricePerGram"
                type="number"
                step="0.01"
                value={formData.pricePerGram}
                onChange={(e) => handleInputChange("pricePerGram", e.target.value)}
                placeholder="0.00"
                required
                className="transition-all duration-200 focus:ring-2 focus:ring-primary/20"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="purity" className="text-sm font-medium">
                Purity
              </Label>
              <Select value={formData.purity} onValueChange={(value) => handleInputChange("purity", value)}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="0.999">99.9% (24k)</SelectItem>
                  <SelectItem value="0.916">91.6% (22k)</SelectItem>
                  <SelectItem value="0.875">87.5% (21k)</SelectItem>
                  <SelectItem value="0.750">75.0% (18k)</SelectItem>
                  <SelectItem value="0.583">58.3% (14k)</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="transactionDate" className="text-sm font-medium">
              Transaction Date
            </Label>
            <Input
              id="transactionDate"
              type="date"
              value={formData.transactionDate}
              onChange={(e) => handleInputChange("transactionDate", e.target.value)}
              required
              className="transition-all duration-200 focus:ring-2 focus:ring-primary/20"
            />
          </div>

          {formData.transactionType === "buy" && (
            <>
              <div className="grid md:grid-cols-2 gap-4">
                <div className="space-y-2">
                  <Label htmlFor="storageLocation" className="text-sm font-medium">
                    Storage Location
                  </Label>
                  <Input
                    id="storageLocation"
                    value={formData.storageLocation}
                    onChange={(e) => handleInputChange("storageLocation", e.target.value)}
                    placeholder="e.g., Home Safe, Bank Vault"
                    className="transition-all duration-200 focus:ring-2 focus:ring-primary/20"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="certificateNumber" className="text-sm font-medium">
                    Certificate Number
                  </Label>
                  <Input
                    id="certificateNumber"
                    value={formData.certificateNumber}
                    onChange={(e) => handleInputChange("certificateNumber", e.target.value)}
                    placeholder="Optional certificate/serial number"
                    className="transition-all duration-200 focus:ring-2 focus:ring-primary/20"
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="description" className="text-sm font-medium">
                  Description
                </Label>
                <Input
                  id="description"
                  value={formData.description}
                  onChange={(e) => handleInputChange("description", e.target.value)}
                  placeholder="e.g., 1oz American Eagle, Krugerrand"
                  className="transition-all duration-200 focus:ring-2 focus:ring-primary/20"
                />
              </div>
            </>
          )}

          <div className="space-y-2">
            <Label htmlFor="notes" className="text-sm font-medium">
              Notes
            </Label>
            <Textarea
              id="notes"
              value={formData.notes}
              onChange={(e) => handleInputChange("notes", e.target.value)}
              placeholder="Additional notes about this transaction"
              className="transition-all duration-200 focus:ring-2 focus:ring-primary/20"
              rows={3}
            />
          </div>

          {totalAmount > 0 && (
            <div className="bg-muted/50 p-4 rounded-lg">
              <div className="text-center">
                <p className="text-sm text-muted-foreground">Total Amount</p>
                <p className="text-2xl font-bold text-foreground">${totalAmount.toFixed(2)}</p>
              </div>
            </div>
          )}

          <Button
            type="submit"
            className="w-full bg-primary hover:bg-secondary text-primary-foreground font-semibold py-2 px-4 rounded-lg transition-all duration-200 transform hover:scale-105"
            disabled={isLoading}
          >
            {isLoading ? (
              <>
                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                Processing...
              </>
            ) : (
              `${formData.transactionType === "buy" ? "Record Purchase" : "Record Sale"}`
            )}
          </Button>
        </form>
      </CardContent>
    </Card>
  )
}
