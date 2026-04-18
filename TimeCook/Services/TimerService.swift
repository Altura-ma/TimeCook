import Foundation

class TimerService: ObservableObject {
    @Published var remainingSeconds: Int = 0
    @Published var isRunning = false
    @Published var isFinished = false

    private var timer: Timer?
    private var endTime: Date?
    private var notificationId: String?

    func start(seconds: Int, title: String, body: String) {
        stop()
        remainingSeconds = seconds
        isFinished = false
        isRunning = true

        let end = Date().addingTimeInterval(TimeInterval(seconds))
        endTime = end

        let id = UUID().uuidString
        notificationId = id
        NotificationService.shared.schedule(identifier: id, title: title, body: body, after: TimeInterval(seconds))

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, let endTime = self.endTime else { return }
            let remaining = max(0, Int(endTime.timeIntervalSince(Date())))
            self.remainingSeconds = remaining
            if remaining == 0 { self.finish() }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        if let id = notificationId {
            NotificationService.shared.cancel(identifier: id)
            notificationId = nil
        }
    }

    func reset() {
        stop()
        remainingSeconds = 0
        isFinished = false
    }

    var formattedTime: String {
        String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60)
    }

    private func finish() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isFinished = true
    }

    deinit { timer?.invalidate() }
}
