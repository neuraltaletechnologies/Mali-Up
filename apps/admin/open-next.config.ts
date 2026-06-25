import { defineCloudflareConfig } from "@opennextjs/cloudflare"

const base = defineCloudflareConfig()

export default {
  ...base,
  // jose@4.x (pulled in by jwks-rsa via firebase-admin) declares a
  // "workerd" export condition pointing to a browser dist that doesn't
  // exist in that version. Since we have nodejs_compat in wrangler.toml,
  // the Node.js condition works correctly at runtime — no workerd-specific
  // builds needed.
  cloudflare: {
    ...base.cloudflare,
    useWorkerdCondition: false,
  },
}
