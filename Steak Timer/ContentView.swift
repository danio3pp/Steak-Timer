import SwiftUI
import AVFoundation
import AudioToolbox

struct ContentView: View {
    @State private var timerModel = SteakTimerModel()
    @State private var showTimePicker: Bool = false
    @State private var showCompletionScreen: Bool = false

    var body: some View {
        @Bindable var timerModel = timerModel

        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.orange, Color.red]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            if showTimePicker {
                TimePickerView(
                    turnTime: $timerModel.turnTime,
                    maxTurns: $timerModel.maxTurns,
                    showTimePicker: $showTimePicker
                )
                    .background(Color.black.opacity(0.5).ignoresSafeArea())
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }

            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Text("Otočka \(timerModel.upcomingTurn) z \(timerModel.maxTurns)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.9))

                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.18), lineWidth: 16)
                            .frame(width: 220, height: 220)

                        Circle()
                            .trim(from: 0, to: timerModel.turnProgress)
                            .stroke(
                                Color.white,
                                style: StrokeStyle(lineWidth: 16, lineCap: .round)
                            )
                            .frame(width: 220, height: 220)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.25), value: timerModel.turnProgress)

                        VStack(spacing: 6) {
                            Text(timerModel.formatClock(timerModel.timeRemaining))
                                .font(.system(size: 54, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text("do ďalšej otočky")
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.85))
                        }
                    }

                    VStack(spacing: 4) {
                        Text("Zostáva spolu \(timerModel.formatClock(timerModel.totalRemainingTime))")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("Jedna otočka trvá \(timerModel.formatTurnTime(timerModel.turnTime))")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.82))
                    }
                }

                Button(action: {
                    withAnimation {
                        showTimePicker = true
                    }
                }) {
                    HStack {
                        Image(systemName: "clock.circle")
                            .font(.title)
                        Text("Upraviť časovač")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        LinearGradient(gradient: Gradient(colors: [Color.red, Color.orange]),
                                       startPoint: .leading,
                                       endPoint: .trailing)
                    )
                    .cornerRadius(15)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5)
                }
                .padding(.horizontal)
                .disabled(timerModel.timerRunning)
                .opacity(timerModel.timerRunning ? 0.55 : 1)

                HStack(spacing: 12) {
                    Button(action: {
                        if timerModel.timerRunning {
                            timerModel.pauseTimer()
                        } else {
                            timerModel.startTimer()
                        }
                    }) {
                        Text(timerModel.startButtonTitle)
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(timerModel.timerRunning ? Color.red : Color.green)
                            .cornerRadius(15)
                            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                            .foregroundColor(.white)
                    }

                    Button(action: {
                        timerModel.resetTimer()
                        showCompletionScreen = false
                    }) {
                        Text("Reset")
                            .font(.title3)
                            .fontWeight(.bold)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.white.opacity(0.18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
                            )
                            .cornerRadius(15)
                            .foregroundColor(.white)
                    }
                }
                .padding(.horizontal)

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(timerModel.timerMessages, id: \.self) { message in
                                Text(message)
                                    .font(.system(size: 26, weight: .medium, design: .rounded))
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 5)
                                    .padding(.horizontal, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white.opacity(0.2))
                                    )
                            }
                        }
                        .onChange(of: timerModel.timerMessages) { _, _ in
                            if let lastMessage = timerModel.timerMessages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 260)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 24)

            if showCompletionScreen {
                CompletionScreen(showCompletionScreen: $showCompletionScreen)
            }
        }
        .onChange(of: timerModel.completedTurns) { oldValue, newValue in
            guard newValue > oldValue else { return }

            if newValue >= timerModel.maxTurns {
                showCompletionScreen = true
            } else {
                playSystemSound()
            }
        }
    }

    func playSystemSound() {
        AudioServicesPlaySystemSound(1005)
    }
}

struct CompletionScreen: View {
    @Binding var showCompletionScreen: Bool

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.yellow, Color.orange]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("Steak je hotový!")
                    .font(.system(size: 48))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()

                Button(action: {
                    showCompletionScreen = false // Zatvorí obrazovku
                }) {
                    Text("OK")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color.red, Color.orange]),
                                           startPoint: .leading,
                                           endPoint: .trailing)
                        )
                        .cornerRadius(15)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5)
                        .padding(.horizontal)
                }
            }
            .padding()
        }
        .onAppear {
            playCompletionSound() // Prehrať zvuk pri zobrazení obrazovky
        }
    }

    func playCompletionSound() {
        AudioServicesPlaySystemSound(1016) // Zvuk "Tweet Sent" (príklad)
    }
}

struct TimePickerView: View {
    @Binding var turnTime: Int
    @Binding var maxTurns: Int
    @Binding var showTimePicker: Bool

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.yellow, Color.orange]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                Text("Nastavenie časovača")
                    .font(.system(size: 36))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top)

                VStack(spacing: 20) {
                    Text("Čas otočenia: \(formatTurnTime(turnTime))")
                        .font(.system(size: 24))
                        .fontWeight(.medium)
                        .foregroundColor(.white)

                    Slider(value: Binding(get: {
                        Double(turnTime)
                    }, set: { newValue in
                        turnTime = Int(newValue)
                    }), in: 10...300, step: 10)
                        .accentColor(.red)
                        .padding(.horizontal)
                }

                VStack(spacing: 20) {
                    Text("Maximálny počet otočení: \(maxTurns)")
                        .font(.system(size: 24))
                        .fontWeight(.medium)
                        .foregroundColor(.white)

                    Slider(value: Binding(get: {
                        Double(maxTurns)
                    }, set: { newValue in
                        maxTurns = Int(newValue)
                    }), in: 1...20, step: 1)
                        .accentColor(.green)
                        .padding(.horizontal)
                }

                VStack {
                    Text("Celkový čas pečenia: \(formatTime(turnTime * maxTurns))")
                        .font(.system(size: 20))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.top)
                }

                Button(action: {
                    withAnimation {
                        showTimePicker = false
                    }
                }) {
                    Text("Potvrdiť")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Color.red, Color.orange]),
                                           startPoint: .leading,
                                           endPoint: .trailing)
                        )
                        .cornerRadius(15)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 5)
                }
                .padding(.horizontal)
            }
            .padding()
        }
    }

    func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes) min \(seconds) s"
    }

    func formatTurnTime(_ seconds: Int) -> String {
        if seconds >= 60 {
            let minutes = seconds / 60
            let remainingSeconds = seconds % 60
            return "\(minutes) min \(remainingSeconds) s"
        } else {
            return "\(seconds) s"
        }
    }
}
