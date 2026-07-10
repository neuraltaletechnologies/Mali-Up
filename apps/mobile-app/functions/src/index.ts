import {onCall, HttpsError} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import {GoogleAuth} from "google-auth-library";

admin.initializeApp();

// Must match `applicationId` in android/app/build.gradle.kts.
const PACKAGE_NAME = "com.neuraltale.maliup";
const PLAY_INTEGRITY_SCOPE = "https://www.googleapis.com/auth/playintegrity";
const DECODE_URL = `https://playintegrity.googleapis.com/v1/${PACKAGE_NAME}:decodeIntegrityToken`;
// Rejects tokens older than this to guard against replay of a captured token.
const MAX_TOKEN_AGE_MS = 5 * 60 * 1000;

const googleAuth = new GoogleAuth({scopes: [PLAY_INTEGRITY_SCOPE]});

interface CheckDeviceIntegrityRequest {
  integrityToken: string;
  nonce: string;
}

interface CheckDeviceIntegrityResponse {
  deviceRecognitionVerdict: string[];
  recentDeviceActivityLevel: string | null;
  sdkVersion: number | null;
  playProtectVerdict: string | null;
  appAccessRiskApps: string[] | null;
  appRecognitionVerdict: string | null;
  appLicensingVerdict: string | null;
}

interface DecodedIntegrityPayload {
  requestDetails?: {
    nonce?: string;
    timestampMillis?: string;
    requestPackageName?: string;
  };
  appIntegrity?: {
    appRecognitionVerdict?: string;
  };
  deviceIntegrity?: {
    deviceRecognitionVerdict?: string[];
    recentDeviceActivity?: {deviceActivityLevel?: string};
    deviceAttributes?: {sdkVersion?: number};
  };
  accountDetails?: {
    appLicensingVerdict?: string;
  };
  environmentDetails?: {
    playProtectVerdict?: string;
    appAccessRiskVerdict?: {appsDetected?: string[]};
  };
}

/**
 * Decodes a Play Integrity standard-request token via the Play Integrity API
 * and returns the subset of verdict fields the app logs for visibility.
 * This function never blocks or scores risk — enforcement, if any, is left
 * to the caller. It only rejects tokens that fail replay/identity checks.
 */
export const checkDeviceIntegrity = onCall<CheckDeviceIntegrityRequest>(
  {region: "us-central1"},
  async (request): Promise<CheckDeviceIntegrityResponse> => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }

    const {integrityToken, nonce} = request.data ?? ({} as CheckDeviceIntegrityRequest);
    if (!integrityToken || typeof integrityToken !== "string") {
      throw new HttpsError("invalid-argument", "integrityToken is required.");
    }
    if (!nonce || typeof nonce !== "string") {
      throw new HttpsError("invalid-argument", "nonce is required.");
    }

    const client = await googleAuth.getClient();

    let payload: DecodedIntegrityPayload | undefined;
    try {
      const response = await client.request<{
        tokenPayloadExternal?: DecodedIntegrityPayload;
      }>({
        url: DECODE_URL,
        method: "POST",
        data: {integrityToken},
      });
      payload = response.data.tokenPayloadExternal;
    } catch (err) {
      throw new HttpsError("internal", "Failed to decode integrity token.");
    }

    if (!payload) {
      throw new HttpsError("internal", "Integrity token decoded with no payload.");
    }

    const details = payload.requestDetails;
    if (!details || details.nonce !== nonce) {
      throw new HttpsError("failed-precondition", "Nonce mismatch — possible replay.");
    }
    if (details.requestPackageName !== PACKAGE_NAME) {
      throw new HttpsError("failed-precondition", "Package name mismatch.");
    }
    const tokenAgeMs = Date.now() - Number(details.timestampMillis ?? 0);
    if (!Number.isFinite(tokenAgeMs) || tokenAgeMs < 0 || tokenAgeMs > MAX_TOKEN_AGE_MS) {
      throw new HttpsError("failed-precondition", "Integrity token is stale.");
    }

    return {
      deviceRecognitionVerdict: payload.deviceIntegrity?.deviceRecognitionVerdict ?? [],
      recentDeviceActivityLevel:
        payload.deviceIntegrity?.recentDeviceActivity?.deviceActivityLevel ?? null,
      sdkVersion: payload.deviceIntegrity?.deviceAttributes?.sdkVersion ?? null,
      playProtectVerdict: payload.environmentDetails?.playProtectVerdict ?? null,
      appAccessRiskApps: payload.environmentDetails?.appAccessRiskVerdict?.appsDetected ?? null,
      appRecognitionVerdict: payload.appIntegrity?.appRecognitionVerdict ?? null,
      appLicensingVerdict: payload.accountDetails?.appLicensingVerdict ?? null,
    };
  }
);
