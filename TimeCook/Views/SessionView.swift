import SwiftUI
import Combine

struct SessionView: View {
    @ObservedObject var schedule: CookingSchedule
    let onStop: () -> Void

    @State private var now = Date()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var nextDishToStart: ScheduleEntry? {
        schedule.entries.first { $0.startTime > now }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
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
        VStack(spacing: 10) {
            // Dish count + countdown
            HStack(spacing: 6) {
                Text("\(schedule.entries.count) plat\(schedule.entries.count > 1 ? "s" : "")")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text("·").foregroundStyle(.secondary)
                Text("prêt dans")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text(schedule.targetEndTime, style: .timer)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.orange)
                    .monospacedDigit()
            }

            // End time — big
            Text(schedule.targetEndTime, style: .time)
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(.orange)

            // Next dish to start — or done state
            if let next = nextDishToStart {
                HStack(spacing: 4) {
                    Image(systemName: "bell.fill")
                        .font(.caption).foregroundStyle(.orange)
                    Text("Démarrer **\(next.dish.name)** dans")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text(next.startTime, style: .timer)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.orange)
                        .monospacedDigit()
                }
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, 2)
            } else {
                Label("Tous les plats sont prêts !", systemImage: "checkmark.circle.fill")
                    .font(.headline).foregroundStyle(.green)
                    .padding(.top, 2)
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
        VStack(alignment: .leading, spacing: 10) {
            Text("Planning")
                .font(.headline)
                .padding(.horizontal)
            ForEach(schedule.entries) { entry in
                ScheduleRow(entry: entry, now: now)
            }
        }
    }

    // MARK: - Stop button

    private var stopButton: some View {
        Button(action: onStop) {
            Text("Arrêter la cuisson")
                .font(.headline).foregroundStyle(.red)
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
            switch self {
            case .waiting: .gray
            case .cooking: .orange
            case .done:    .green
            }
        }
        var icon: String {
            switch self {
            case .waiting: "clock"
            case .cooking: "flame.fill"
            case .done:    "checkmark.circle.fill"
            }
        }
        var label: String {
            switch self {
            case .waiting: "En attente"
            case .cooking: "En cuisson"
            case .done:    "Prêt ✓"
            }
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
                .font(.title2)
                .foregroundStyle(status.color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.dish.name)
                    .font(.headline)
                    .lineLimit(1)

                switch status {
                case .waiting:
                    HStack(spacing: 4) {
                        Text("Démarre dans")
                            .font(.caption).foregroundStyle(.secondary)
                        Text(entry.startTime, style: .timer)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                case .cooking:
                    HStack(spacing: 4) {
                        Text("Encore")
                            .font(.caption).foregroundStyle(.orange)
                        Text(entry.endTime, style: .timer)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                            .monospacedDigit()
                    }
                case .done:
                    Text("Terminé à \(entry.endTime, style: .time)")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(status.label)
                .font(.caption).fontWeight(.medium)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(status.color.opacity(0.15))
                .foregroundStyle(status.color)
                .cornerRadius(8)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.3), value: status.label)
    }
}
