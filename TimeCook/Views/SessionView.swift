import SwiftUI
import Combine

struct SessionView: View {
    @ObservedObject var schedule: CookingSchedule
    let onStop: () -> Void

    @State private var now = Date()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var totalRemaining: Int {
        max(0, Int(schedule.targetEndTime.timeIntervalSince(now)))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                summaryCard
                scheduleList
                stopButton
            }
            .padding(.vertical)
        }
        .onReceive(ticker) { _ in now = Date() }
    }

    // MARK: - Summary card

    private var summaryCard: some View {
        VStack(spacing: 8) {
            Text("Tous les plats prêts à")
                .font(.subheadline).foregroundColor(.secondary)
            Text(schedule.targetEndTime, style: .time)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.orange)

            if totalRemaining > 0 {
                Text("Dans \(totalRemaining / 60) min \(totalRemaining % 60) sec")
                    .font(.subheadline).foregroundColor(.secondary)
            } else {
                Label("Tous les plats sont prêts !", systemImage: "checkmark.circle.fill")
                    .font(.headline).foregroundColor(.green)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(18)
        .padding(.horizontal)
    }

    // MARK: - Schedule list

    private var scheduleList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Planning").font(.headline).padding(.horizontal)
            ForEach(schedule.entries) { entry in
                ScheduleRow(entry: entry, now: now)
            }
        }
    }

    // MARK: - Stop button

    private var stopButton: some View {
        Button(action: onStop) {
            Text("Arrêter la cuisson")
                .font(.headline).foregroundColor(.red)
                .frame(maxWidth: .infinity).padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(14)
                .padding(.horizontal)
        }
    }
}

// MARK: - Schedule Row

struct ScheduleRow: View {
    let entry: ScheduleEntry
    let now: Date

    enum Status {
        case waiting, cooking, done

        var color: Color {
            switch self { case .waiting: .gray; case .cooking: .orange; case .done: .green }
        }
        var icon: String {
            switch self { case .waiting: "clock"; case .cooking: "flame.fill"; case .done: "checkmark.circle.fill" }
        }
        var label: String {
            switch self { case .waiting: "En attente"; case .cooking: "En cuisson"; case .done: "Prêt" }
        }
    }

    var status: Status {
        if now >= entry.endTime { return .done }
        if now >= entry.startTime { return .cooking }
        return .waiting
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: status.icon)
                .font(.title2).foregroundColor(status.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.dish.name).font(.headline)

                HStack(spacing: 4) {
                    Text("Démarrage :").font(.caption).foregroundColor(.secondary)
                    Text(entry.startTime, style: .time).font(.caption).fontWeight(.semibold)
                }

                if status == .cooking {
                    let rem = max(0, Int(entry.endTime.timeIntervalSince(now)))
                    Text("Encore \(rem / 60) min \(rem % 60) sec")
                        .font(.caption).foregroundColor(.orange)
                }
            }

            Spacer()

            Text(status.label)
                .font(.caption).fontWeight(.medium)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(status.color.opacity(0.15))
                .foregroundColor(status.color)
                .cornerRadius(8)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
        .padding(.horizontal)
    }
}
