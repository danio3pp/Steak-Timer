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
    @State private var showSettings = false

    var body: some View {
        @Bindable var timerModel = timerModel

        GeometryReader { geometry in
            let width = geometry.size.width
            let circleSize = max(104, min(138, width * 0.68))
            let timerFontSize = max(24, min(32, width * 0.16))
            let rowPadding = max(8, min(10, width * 0.045))

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.18), lineWidth: 9)

                        Circle()
                            .trim(from: 0, to: timerModel.turnProgress)
                            .stroke(Color.white, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.25), value: timerModel.turnProgress)

                        VStack(spacing: 2) {
                            Text("Otocka \(timerModel.upcomingTurn)/\(timerModel.maxTurns)")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.82))
                                .lineLimit(1)

                            Text(timerModel.formatClock(timerModel.timeRemaining))
                                .font(.system(size: timerFontSize, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .minimumScaleFactor(0.7)
                                .foregroundStyle(.white)
                                .lineLimit(1)

                            Text("dalsia otocka")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.75))
                                .lineLimit(1)
                        }
                    }
                    .frame(width: circleSize, height: circleSize)
                    .padding(.vertical, 2)

                    HStack {
                        Text("Zostava")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.75))
                            .lineLimit(1)

                        Spacer(minLength: 8)

                        Text(timerModel.formatClock(timerModel.totalRemainingTime))
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white)
                            .monospacedDigit()
                            .lineLimit(1)
                    }
                    .padding(rowPadding)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showSettings.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            Text("Upravit casovac")
                        }
                        .font(.caption.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundStyle(.white)
                        .background(Color.white.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(timerModel.timerRunning)
                    .opacity(timerModel.timerRunning ? 0.5 : 1)

                    if showSettings {
                        VStack(spacing: 8) {
                            adjustmentRow(
                                title: "Cas otocky",
                                value: "\(timerModel.turnTime)s",
                                onMinus: { timerModel.turnTime = max(10, timerModel.turnTime - 10) },
                                onPlus: { timerModel.turnTime = min(300, timerModel.turnTime + 10) }
                            )

                            adjustmentRow(
                                title: "Pocet otoceni",
                                value: "\(timerModel.maxTurns)",
                                onMinus: { timerModel.maxTurns = max(1, timerModel.maxTurns - 1) },
                                onPlus: { timerModel.maxTurns = min(20, timerModel.maxTurns + 1) }
                            )
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }

                    HStack(spacing: 8) {
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
                                .padding(.vertical, 9)
                                .foregroundStyle(.white)
                                .background(timerModel.timerRunning ? Color.red : Color.green)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)

                        Button(action: { timerModel.resetTimer() }) {
                            Text("Reset")
                                .font(.footnote.weight(.bold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .foregroundStyle(.white)
                                .background(Color.white.opacity(0.14))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, max(10, width * 0.07))
                .padding(.top, 0.01)
                .padding(.bottom, 80)
            }
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

    @ViewBuilder
    private func adjustmentRow(title: String, value: String, onMinus: @escaping () -> Void, onPlus: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.82))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                tinyActionButton(symbol: "minus", action: onMinus)
                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(minWidth: 38)
                tinyActionButton(symbol: "plus", action: onPlus)
            }
        }
        .padding(8)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func tinyActionButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.white.opacity(0.18))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
