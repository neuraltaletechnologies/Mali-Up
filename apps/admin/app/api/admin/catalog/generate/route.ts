import { NextResponse } from 'next/server'
import Anthropic from '@anthropic-ai/sdk'
import { adminFirestore } from '@/lib/firebase-admin'
import { requireAdminSession } from '@/lib/api-guard'

const anthropic = new Anthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
})

interface GeneratedCategory {
  categoryName: string
  description: string
  icon: string
  products: GeneratedProduct[]
}

interface GeneratedProduct {
  productName: string
  skuTemplate: string
  defaultUnit: string
  suggestedCostPrice: number
  suggestedSellingPrice: number
  searchableKeywords: string[]
}

export async function POST(request: Request) {
  const denied = await requireAdminSession()
  if (denied) return denied

  try {
    const body = (await request.json()) as {
      businessTypeId: string
      businessTypeEn: string
      businessTypeSw: string
    }

    const { businessTypeId, businessTypeEn, businessTypeSw } = body
    if (!businessTypeId || !businessTypeEn) {
      return NextResponse.json({ error: 'businessTypeId and businessTypeEn are required' }, { status: 400 })
    }

    const message = await anthropic.messages.create({
      model: 'claude-haiku-4-5-20251001',
      max_tokens: 4096,
      system: `You are a business catalog expert for Tanzania (East Africa).
Generate realistic product categories and products for Tanzanian SMEs.
Prices should be in TZS (Tanzanian Shillings). Typical ranges:
- Low-cost goods: 500–5,000 TZS
- Mid-range goods: 5,000–50,000 TZS
- High-value goods: 50,000–500,000 TZS
Use common Tanzanian brand names and locally relevant products where applicable.
Respond ONLY with valid JSON — no markdown, no explanation.`,
      messages: [
        {
          role: 'user',
          content: `Generate 4–6 product categories with 5–8 products each for a Tanzanian "${businessTypeEn}" (Kiswahili: "${businessTypeSw}") business.

Return JSON in this exact shape:
{
  "categories": [
    {
      "categoryName": "string",
      "description": "string (one sentence)",
      "icon": "single emoji",
      "products": [
        {
          "productName": "string",
          "skuTemplate": "string (e.g. ITEM-001)",
          "defaultUnit": "string (pcs/kg/litre/box/dozen/etc)",
          "suggestedCostPrice": number,
          "suggestedSellingPrice": number,
          "searchableKeywords": ["string", ...]
        }
      ]
    }
  ]
}`,
        },
      ],
    })

    const rawText = message.content[0].type === 'text' ? message.content[0].text : ''
    const parsed = JSON.parse(rawText) as { categories: GeneratedCategory[] }

    // Write to Firestore in batched chunks (max 400 per batch)
    type Op = { ref: FirebaseFirestore.DocumentReference; data: Record<string, unknown> }
    const ops: Op[] = []
    let categoriesAdded = 0
    let productsAdded = 0

    for (const cat of parsed.categories) {
      const catRef = adminFirestore.collection('master_categories').doc()
      ops.push({
        ref: catRef,
        data: {
          businessTypeId,
          categoryName:  cat.categoryName,
          description:   cat.description,
          icon:          cat.icon,
          source:        'admin',
          productCount:  cat.products.length,
          createdAt:     new Date(),
          updatedAt:     new Date(),
        },
      })
      categoriesAdded++

      for (const prod of cat.products) {
        const prodRef = adminFirestore.collection('master_products').doc()
        ops.push({
          ref: prodRef,
          data: {
            businessTypeId,
            categoryId:            catRef.id,
            categoryName:          cat.categoryName,
            productName:           prod.productName,
            skuTemplate:           prod.skuTemplate,
            barcode:               '',
            defaultUnit:           prod.defaultUnit,
            suggestedCostPrice:    prod.suggestedCostPrice,
            suggestedSellingPrice: prod.suggestedSellingPrice,
            searchableKeywords:    prod.searchableKeywords ?? [],
            source:                'admin',
            createdAt:             new Date(),
            updatedAt:             new Date(),
          },
        })
        productsAdded++
      }
    }

    // Flush in 400-op chunks
    for (let i = 0; i < ops.length; i += 400) {
      const chunk = ops.slice(i, i + 400)
      const batch = adminFirestore.batch()
      for (const op of chunk) batch.set(op.ref, op.data)
      await batch.commit()
    }

    return NextResponse.json({ categoriesAdded, productsAdded })
  } catch (err) {
    console.error('[POST /api/admin/catalog/generate]', err)
    const msg = err instanceof Error ? err.message : 'Generation failed'
    return NextResponse.json({ error: msg }, { status: 500 })
  }
}
