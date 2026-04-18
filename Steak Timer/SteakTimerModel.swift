import Foundation
import Observation

#if canImport(UIKit)
import UIKit
#endif

@Observable
final class SteakTimerModel {
    var timeRemaining: Int
    var timerRunning = false
    var timerMessages: [String] = []
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

    var upcomingTurn: Int {
        min(completedTurns + 1, maxTurns)
    }

    var totalRemainingTime: Int {
        guard completedTurns < maxTurns else { return 0 }
        return ((maxTurns - completedTurns - 1) * turnTime) + timeRemaining
    }

    var turnProgress: Double {
        guard turnTime > 0 else { return 0 }
        return 1 - (Double(timeRemaining) / Double(turnTime))
    }

    var startButtonTitle: String {
        if timerRunning {
            return "Pauza"
        }

        if completedTurns == 0 && timeRemaining == turnTime {
            return "Štart"
        }

        return "Pokračovať"
    }

    func startTimer() {
        guard timer == nil else { return }

        timerRunning = true
        setIdleTimer(enabled: true)

        if completedTurns == 0 && timeRemaining == turnTime && timerMessages.isEmpty == false {
            timerMessages = []
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }

            if self.timeRemaining > 1 {
                self.timeRemaining -= 1
            } else {
                self.completedTurns += 1
                self.timerMessages.append("\(self.completedTurns). otočenie")

                if self.completedTurns >= self.maxTurns {
                    self.stopTimer()
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
        setIdleTimer(enabled: false)
    }

    func stopTimer() {
        pauseTimer()

        if completedTurns >= maxTurns {
            timeRemaining = 0
        }
    }

    func resetTimer() {
        pauseTimer()
        timerMessages = []
        completedTurns = 0
        timeRemaining = turnTime
    }

    func formatClock(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    func formatTurnTime(_ seconds: Int) -> String {
        if seconds >= 60 {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            return "\(minutes) min \(remainingSeconds) s"
        }

        return "\(seconds) s"
    }

    private func setIdleTimer(enabled: Bool) {
#if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = enabled
#endif
    }
}
