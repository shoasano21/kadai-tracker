import WebKit
import UserNotifications

class SubscribeMessage {
    var topic  = ""
    var eventValue = ""
    var unsubscribe = false
}

// Firebase/FCM removed. Remote push subscription is a no-op.
// The app uses the web Notification API (local notifications via WKWebView).
func handleSubscribeTouch(message: WKScriptMessage) { /* no-op */ }

func returnPermissionResult(isGranted: Bool) {
    DispatchQueue.main.async {
        let detail = isGranted ? "granted" : "denied"
        課題トラッカー.webView?.evaluateJavaScript("this.dispatchEvent(new CustomEvent('push-permission-request', { detail: '\(detail)' }))")
    }
}

func returnPermissionState(state: String) {
    DispatchQueue.main.async {
        課題トラッカー.webView?.evaluateJavaScript("this.dispatchEvent(new CustomEvent('push-permission-state', { detail: '\(state)' }))")
    }
}

func handlePushPermission() {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
        switch settings.authorizationStatus {
        case .notDetermined:
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                returnPermissionResult(isGranted: granted)
            }
        case .denied:
            returnPermissionResult(isGranted: false)
        case .authorized, .ephemeral, .provisional:
            returnPermissionResult(isGranted: true)
        @unknown default:
            return
        }
    }
}

func handlePushState() {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
        let state: String
        switch settings.authorizationStatus {
        case .notDetermined: state = "notDetermined"
        case .denied: state = "denied"
        case .authorized: state = "authorized"
        case .ephemeral: state = "ephemeral"
        case .provisional: state = "provisional"
        @unknown default: state = "unknown"
        }
        returnPermissionState(state: state)
    }
}

func checkViewAndEvaluate(event: String, detail: String) {
    guard let webView = 課題トラッカー.webView else { return }
    if !webView.isHidden && !webView.isLoading {
        DispatchQueue.main.async {
            webView.evaluateJavaScript("this.dispatchEvent(new CustomEvent('\(event)', { detail: \(detail) }))")
        }
    } else {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            checkViewAndEvaluate(event: event, detail: detail)
        }
    }
}

// FCM removed: report empty token to any JS listeners
func handleFCMToken() {
    checkViewAndEvaluate(event: "push-token", detail: "'NO_FCM'")
}

func sendPushToWebView(userInfo: [AnyHashable: Any]) {
    guard let jsonData = try? JSONSerialization.data(withJSONObject: userInfo),
          let json = String(data: jsonData, encoding: .utf8) else { return }
    checkViewAndEvaluate(event: "push-notification", detail: json)
}

func sendPushClickToWebView(userInfo: [AnyHashable: Any]) {
    guard let jsonData = try? JSONSerialization.data(withJSONObject: userInfo),
          let json = String(data: jsonData, encoding: .utf8) else { return }
    checkViewAndEvaluate(event: "push-notification-click", detail: json)
}

// ===== Local notification scheduling (JS ↔ Swift bridge) =====

private func parseIsoDate(_ s: String) -> Date? {
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let d = f.date(from: s) { return d }
    f.formatOptions = [.withInternetDateTime]
    return f.date(from: s)
}

func handleScheduleLocal(message: WKScriptMessage) {
    let bodyString: String
    if let s = message.body as? String {
        bodyString = s
    } else if let dict = message.body as? [String: Any],
              let data = try? JSONSerialization.data(withJSONObject: dict),
              let s = String(data: data, encoding: .utf8) {
        bodyString = s
    } else {
        return
    }
    guard let data = bodyString.data(using: .utf8),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

    let center = UNUserNotificationCenter.current()

    // Ensure permission before scheduling.
    center.getNotificationSettings { settings in
        let ensureAuth: (@escaping (Bool) -> Void) -> Void = { done in
            switch settings.authorizationStatus {
            case .authorized, .ephemeral, .provisional:
                done(true)
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in done(granted) }
            default:
                done(false)
            }
        }
        ensureAuth { granted in
            guard granted else { return }

            // Cancel previously-scheduled notifications owned by this app.
            center.getPendingNotificationRequests { requests in
                let ids = requests.map { $0.identifier }.filter { $0.hasPrefix("kadai-") }
                center.removePendingNotificationRequests(withIdentifiers: ids)

                // Schedule new ones.
                let notifications = (json["notifications"] as? [[String: Any]]) ?? []
                let now = Date()
                for n in notifications {
                    guard let id = n["id"] as? String,
                          let title = n["title"] as? String,
                          let body = n["body"] as? String,
                          let whenStr = n["when"] as? String,
                          let when = parseIsoDate(whenStr) else { continue }
                    if when <= now { continue }

                    let content = UNMutableNotificationContent()
                    content.title = title
                    content.body = body
                    content.sound = .default

                    let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: when)
                    let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                    let request = UNNotificationRequest(identifier: "kadai-\(id)", content: content, trigger: trigger)
                    center.add(request) { _ in }
                }
            }
        }
    }
}
