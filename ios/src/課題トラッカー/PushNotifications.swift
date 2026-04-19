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
