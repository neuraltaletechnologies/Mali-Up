import {defineSecret} from "firebase-functions/params";

/**
 * Shared Beem Africa SMS sender, used by the welcome and staff invitation
 * SMS functions. Functions calling sendBeemSms must bind BEEM_API_KEY and
 * BEEM_SECRET_KEY in their `secrets` option.
 */

export const BEEM_API_KEY = defineSecret("BEEM_API_KEY");
export const BEEM_SECRET_KEY = defineSecret("BEEM_SECRET_KEY");

const BEEM_SMS_SEND_URL = "https://apisms.beem.africa/v1/send";

export function beemAuthHeader(): string {
  return "Basic " + Buffer.from(`${BEEM_API_KEY.value()}:${BEEM_SECRET_KEY.value()}`).toString("base64");
}

export function digitsOnly(phone: unknown): string {
  return String(phone ?? "").replace(/\D/g, "");
}

/**
 * Sends a single SMS message via Beem Africa SMS API.
 */
export async function sendBeemSms(
  phone: string,
  message: string,
  sourceAddr?: string,
): Promise<{success: boolean; error?: string; responseData?: unknown}> {
  const formattedDest = digitsOnly(phone);
  if (formattedDest.length < 9 || formattedDest.length > 15) {
    return {success: false, error: `Invalid destination phone number: ${phone}`};
  }

  const senderId =
    sourceAddr ||
    process.env.BEEM_SMS_SENDER_ID ||
    "Mali Up";

  try {
    const payload = {
      source_addr: senderId,
      schedule_time: "",
      encoding: 0,
      message: message,
      recipients: [
        {
          recipient_id: 1,
          dest_addr: formattedDest,
        },
      ],
    };

    const response = await fetch(BEEM_SMS_SEND_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": beemAuthHeader(),
      },
      body: JSON.stringify(payload),
    });

    const responseBody = await response.json().catch(() => ({}));

    if (!response.ok) {
      console.error("[BeemSMS] Send failed", response.status, responseBody);
      return {
        success: false,
        error: `Beem HTTP ${response.status}: ${JSON.stringify(responseBody)}`,
        responseData: responseBody,
      };
    }

    return {success: true, responseData: responseBody};
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    console.error("[BeemSMS] Network error sending SMS:", err);
    return {success: false, error: msg};
  }
}
