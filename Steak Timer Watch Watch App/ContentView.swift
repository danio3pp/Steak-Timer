import SwiftUI
import Observation
import WatchKit

@Observable
final class WatchSteakTimerModel {
    var timeRemaining: Int
    var timerRunning = false
    var completedTurns = 0
    var turnTime: Int {
        didSet {
            if timerRunning == false && completedTurns == 0 {
                timeRemaining = turnTime
            }
        }
    }
    var maxTurns: Int

    @ObservationIgnored
    private var timer: Timer?

    init(turnTime: Int = 60, maxTurns: Int = 8) {
        self.turnTime = turnTime
        self.maxTurns = maxTurns
        self.timeRemaining = turnTime
    }

    var upcomingTurn: Int { min(completedTurns + 1, maxTurns) }

    var turnProgress: Double {
        guard turnTime > 0 else { return 0 }
        return 1 - (Double(timeRemaining) / Double(turnTime))
    }

    var totalRemainingTime: Int {
        guard completedTurns < maxTurns else { return 0 }
        return ((maxTurns - completedTurns - 1) * turnTime) + timeRemaining
    }

    var startButtonTitle: String {
        if timerRunning { return "Pauza" }
        if completedTurns == 0 && timeRemaining == turnTime { return "Štart" }
        return "Pokračovať"
    }

    func startTimer() {
        guard timer == nil else { return }
        timerRunning = true

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }

            if self.timeRemaining > 1 {
                self.timeRemaining -= 1
            } else {
                self.completedTurns += 1
                WKInterfaceDevice.current().play(.notification)

                if self.completedTurns >= self.maxTurns {
                    self.pauseTimer()
                    self.timeRemaining = 0
                    WKInterfaceDevice.current().play(.success)
                } else {
                    self.timeRemaining = self.turnTime
                }
            }
        }
    }

    func pauseTimer() {
        timerRunning = false
        timer?.invalidate()
        timer = nil
    }

    func resetTimer() {
        pauseTimer()
        completedTurns = 0
        timeRemaining = turnTime
    }

    func formatClock(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct ContentView: View {
    @State private var timerModel = WatchSteakTimerModel()

    var body: some View {
        @Bindable var timerModel = timerModel

        ScrollView {
            VStack(spacing: 12) {
                Text("Steak Timer")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.85))

                Text("Otocka \(timerModel.upcomingTurn)/\(timerModel.maxTurns)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.18), lineWidth: 10)

                    Circle()
                        .trim(from: 0, to: timerModel.turnProgress)
                        .stroke(Color.white, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.25), value: timerModel.turnProgress)

                    VStack(spacing: 2) {
                        Text(timerModel.formatClock(timerModel.timeRemaining))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)

                        Text("dalsia otocka")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
                .frame(width: 132, height: 132)

                HStack {
                    Text("Zostava")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.75))
                    Spacer()
                    Text(timerModel.formatClock(timerModel.totalRemainingTime))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                }
                .padding(10)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))

                Button(action: {
                    if timerModel.timerRunning {
                        timerModel.pauseTimer()
                    } else {
                        timerModel.startTimer()
                    }
                }) {
                    Text(timerModel.startButtonTitle)
                        .font(.footnote.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(.white)
                        .background(timerModel.timerRunning ? Color.red : Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)

                Button(action: { timerModel.resetTimer() }) {
                    Text("Reset")
                        .font(.footnote.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(.white)
                        .background(Color.white.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
            .padding(12)
        }
        .background(
            LinearGradient(
                colors: [Color.orange, Color.red],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
    }
}

#Preview {
    ContentView()
}
