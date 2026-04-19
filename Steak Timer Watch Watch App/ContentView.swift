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
    @ObservationIgnored
    private var runStartedAt: Date?
    @ObservationIgnored
    private var runStartedRemaining: Int = 0
    @ObservationIgnored
    private var runStartedCompletedTurns: Int = 0

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
        runStartedAt = Date()
        runStartedRemaining = timeRemaining
        runStartedCompletedTurns = completedTurns

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.refreshFromWallClock()
        }
    }

    func pauseTimer() {
        refreshFromWallClock()
        timerRunning = false
        timer?.invalidate()
        timer = nil
        runStartedAt = nil
        runStartedRemaining = 0
        runStartedCompletedTurns = 0
    }

    func resetTimer() {
        pauseTimer()
        completedTurns = 0
        timeRemaining = turnTime
    }

    func refreshFromWallClock() {
        guard timerRunning, let startedAt = runStartedAt else { return }

        let elapsed = Int(Date().timeIntervalSince(startedAt))
        let turnsBefore = completedTurns

        let turnsCompletedThisRun: Int
        let remaining: Int

        if elapsed < runStartedRemaining {
            turnsCompletedThisRun = 0
            remaining = runStartedRemaining - elapsed
        } else {
            let elapsedAfterFirstTurn = elapsed - runStartedRemaining
            let extraFullTurns = elapsedAfterFirstTurn / turnTime
            let remainder = elapsedAfterFirstTurn % turnTime

            turnsCompletedThisRun = 1 + extraFullTurns
            remaining = remainder == 0 ? turnTime : (turnTime - remainder)
        }

        let totalTurns = runStartedCompletedTurns + turnsCompletedThisRun

        if totalTurns >= maxTurns {
            completedTurns = maxTurns
            timerRunning = false
            timer?.invalidate()
            timer = nil
            timeRemaining = 0
            runStartedAt = nil
            runStartedRemaining = 0
            runStartedCompletedTurns = 0
            WKInterfaceDevice.current().play(.success)
            return
        }

        completedTurns = totalTurns
        timeRemaining = max(1, remaining)

        if completedTurns > turnsBefore {
            WKInterfaceDevice.current().play(.notification)
        }
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
    @Environment(\.scenePhase) private var scenePhase
    private let topAnchorId = "watchTopAnchor"

    var body: some View {
        @Bindable var timerModel = timerModel

        GeometryReader { geometry in
            let width = geometry.size.width
            let circleSize = max(104, min(138, width * 0.68))
            let timerFontSize = max(24, min(32, width * 0.16))
            let rowPadding = max(8, min(10, width * 0.045))

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        Color.clear
                            .frame(height: 0)
                            .id(topAnchorId)

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
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    proxy.scrollTo(topAnchorId, anchor: .top)
                                }
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
        }
        .background(
            LinearGradient(
                colors: [Color.orange, Color.red],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                timerModel.refreshFromWallClock()
            }
        }
    }

    @ViewBuilder
    private func adjustmentRow(title: String, value: String, onMinus: @escaping () -> Void, onPlus: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.82))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                tinyActionButton(symbol: "chevron.left", action: onMinus)
                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(minWidth: 38)
                tinyActionButton(symbol: "chevron.right", action: onPlus)
            }
        }
        Text("swipe < >")
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.6))
            .frame(maxWidth: .infinity, alignment: .trailing)
        .padding(8)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
        .gesture(
            DragGesture(minimumDistance: 18)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height) else { return }

                    if value.translation.width > 24 {
                        onPlus()
                    } else if value.translation.width < -24 {
                        onMinus()
                    }
                }
        )
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
