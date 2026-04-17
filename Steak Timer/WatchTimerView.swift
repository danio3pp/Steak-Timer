import SwiftUI

struct WatchTimerView: View {
    @Bindable var timerModel: SteakTimerModel

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Steak Timer")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.85))

                Text("Otočka \(timerModel.upcomingTurn)/\(timerModel.maxTurns)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.75))

                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.18), lineWidth: 10)

                    Circle()
                        .trim(from: 0, to: timerModel.turnProgress)
                        .stroke(
                            Color.white,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.25), value: timerModel.turnProgress)

                    VStack(spacing: 2) {
                        Text(timerModel.formatClock(timerModel.timeRemaining))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(.white)

                        Text("ďalšia otočka")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.75))
                    }
                }
                .frame(width: 132, height: 132)
                .padding(.vertical, 4)

                watchStatRow(title: "Zostáva", value: timerModel.formatClock(timerModel.totalRemainingTime))
                watchStatRow(title: "Jedna otočka", value: timerModel.formatTurnTime(timerModel.turnTime))

                if timerModel.completedTurns >= timerModel.maxTurns {
                    Text("Steak je hotový")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    watchButton(
                        title: timerModel.startButtonTitle,
                        color: timerModel.timerRunning ? .red : .green
                    ) {
                        if timerModel.timerRunning {
                            timerModel.pauseTimer()
                        } else {
                            timerModel.startTimer()
                        }
                    }
                }

                watchButton(title: "Reset", color: Color.white.opacity(0.14)) {
                    timerModel.resetTimer()
                }

                if timerModel.timerRunning == false {
                    VStack(spacing: 8) {
                        AdjustableWatchRow(
                            title: "Čas otočky",
                            valueText: timerModel.formatTurnTime(timerModel.turnTime),
                            onDecrease: {
                                timerModel.turnTime = max(10, timerModel.turnTime - 10)
                            },
                            onIncrease: {
                                timerModel.turnTime = min(300, timerModel.turnTime + 10)
                            }
                        )

                        AdjustableWatchRow(
                            title: "Počet otočení",
                            valueText: "\(timerModel.maxTurns)",
                            onDecrease: {
                                timerModel.maxTurns = max(1, timerModel.maxTurns - 1)
                            },
                            onIncrease: {
                                timerModel.maxTurns = min(20, timerModel.maxTurns + 1)
                            }
                        )
                    }
                }
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

    @ViewBuilder
    private func watchStatRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.75))

            Spacer()

            Text(value)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private func watchButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.footnote.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(.white)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

private struct AdjustableWatchRow: View {
    let title: String
    let valueText: String
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.75))

            HStack(spacing: 8) {
                miniButton(symbol: "minus", action: onDecrease)

                Text(valueText)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)

                miniButton(symbol: "plus", action: onIncrease)
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func miniButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.footnote.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(Color.white.opacity(0.16))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}

#Preview("Watch Layout") {
    WatchTimerView(timerModel: SteakTimerModel())
}
