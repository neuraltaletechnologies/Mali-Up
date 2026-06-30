import ActivityKit
import SwiftUI
import WidgetKit

// MARK: – Attributes
//
// Must be redefined here exactly as the live_activities plugin defines it internally.
// ContentState is intentionally empty — data is passed via UserDefaults (App Groups).

struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
    public typealias LiveDeliveryData = ContentState

    public struct ContentState: Codable, Hashable {}

    var id = UUID()
}

// Keys are prefixed with the activity UUID so concurrent activities don't clash.
extension LiveActivitiesAppAttributes {
    func prefixedKey(_ key: String) -> String {
        return "\(id)_\(key)"
    }
}

// MARK: – Shared UserDefaults (App Group)

private let sharedDefault = UserDefaults(suiteName: "group.com.neuraltale.maliup")!

// MARK: – Brand colours (matching Flutter AppColors)

private let navy   = Color(red: 0.08, green: 0.12, blue: 0.27)
private let yellow = Color(red: 0.98, green: 0.80, blue: 0.08)

// MARK: – Helpers

private func icon(for status: String) -> String {
    switch status {
    case "done":  return "checkmark.circle.fill"
    case "error": return "exclamationmark.circle.fill"
    default:      return "arrow.triangle.2.circlepath"
    }
}

private func tintColor(for status: String) -> Color {
    switch status {
    case "done":  return .green
    case "error": return .red
    default:      return yellow
    }
}

private func statusLabel(for status: String) -> String {
    switch status {
    case "done":  return "Data synced"
    case "error": return "Sync failed"
    default:      return "Syncing data…"
    }
}

// MARK: – Lock-screen / banner view

@available(iOSApplicationExtension 16.1, *)
struct MaliUpLockScreenView: View {
    let context: ActivityViewContext<LiveActivitiesAppAttributes>

    var body: some View {
        let status   = sharedDefault.string(forKey: context.attributes.prefixedKey("status")) ?? "syncing"
        let business = sharedDefault.string(forKey: context.attributes.prefixedKey("businessName")) ?? ""

        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(navy)
                    .frame(width: 44, height: 44)
                Image(systemName: icon(for: status))
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(tintColor(for: status))
                    .symbolEffect(.rotate, isActive: status == "syncing")
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Mali Up")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Text(statusLabel(for: status))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                if !business.isEmpty {
                    Text(business)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if status == "syncing" {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.8)
            }
        }
        .padding(16)
        .activityBackgroundTint(Color(.systemBackground))
    }
}

// MARK: – Widget bundle entry point

@main
struct MaliUpWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOSApplicationExtension 16.1, *) {
            MaliUpSyncWidget()
        }
    }
}

// MARK: – Dynamic Island widget

@available(iOSApplicationExtension 16.1, *)
struct MaliUpSyncWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            MaliUpLockScreenView(context: context)
        } dynamicIsland: { context in
            let status   = sharedDefault.string(forKey: context.attributes.prefixedKey("status")) ?? "syncing"
            let business = sharedDefault.string(forKey: context.attributes.prefixedKey("businessName")) ?? ""

            DynamicIsland {
                // Expanded (long-press)
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        Image(systemName: icon(for: status))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(tintColor(for: status))
                            .symbolEffect(.rotate, isActive: status == "syncing")
                        Text("Mali Up")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(status == "syncing" ? "Syncing…" : status == "done" ? "Synced ✓" : "Failed ✗")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if !business.isEmpty {
                        Text(business)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.bottom, 4)
                    }
                }
            } compactLeading: {
                // Left side of compact pill
                Image(systemName: icon(for: status))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(yellow)
                    .symbolEffect(.rotate, isActive: status == "syncing")
                    .padding(.leading, 4)
            } compactTrailing: {
                // Right side of compact pill
                Text(status == "syncing" ? "Sync" : status == "done" ? "✓" : "✗")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.trailing, 4)
            } minimal: {
                // Tiny dot when two apps share the island
                Image(systemName: icon(for: status))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(yellow)
            }
            .widgetURL(URL(string: "maliup://dashboard"))
            .keylineTint(yellow)
        }
    }
}
