// Kept free of three.js imports so the server-rendered shell can size itself
// without pulling the 3D bundle.

export type PhoneModel = "iphone" | "pixel"

/** Real-world body proportions (height / width) of each model, in mm. */
export const PHONE_DIMENSIONS: Record<PhoneModel, { width: number; height: number }> = {
  iphone: { width: 71, height: 150.5 },
  pixel: { width: 72, height: 157 },
}

/**
 * How far the canvas extends past the phone's layout box on each side, as a
 * fraction of that box. Gives a rotating phone room so it never clips.
 */
export const CANVAS_PADDING = 0.16
