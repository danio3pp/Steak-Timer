import SwiftUI
import AVFoundation
import AudioToolbox

struct ContentView: View {
    @State private var timeElapsed: Int = 0
    @State private var timerRunning: Bool = false
    @State private var timerMessages: [String] = []
    @State private var totalMinutes: Int = 0
    @State private var timer: Timer? = nil
    @State private var turnTime: Int = 60
    @State private var maxTurns: Int = 8
    @State private var showTimePicker: Bool = false
    @State private var showCompletionScreen: Bool = false // Nový stav pre zobrazenie

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.orange, Color.red]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            if showTimePicker {
                TimePickerView(turnTime: $turnTime, maxTurns: $maxTurns, showTimePicker: $showTimePicker)
                    .background(Color.black.opacity(0.5).ignoresSafeArea()) // Polopriehľadné pozadie
                    .transition(.move(edge: .bottom)) // Animácia
                    .zIndex(1) // Zabezpečí, že bude na vrchu
            }

            VStack(spacing: 20) { // Nastavenie rovnakého odstupu
                // Časovač
                Text("\(timeElapsed) s")
                    .font(.system(size: 80))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 140, height: 140)
                    )

                // Tlačidlo na úpravu časovača
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

                // Tlačidlo štart/stop
                Button(action: {
                    if timerRunning {
                        stopTimer()
                    } else {
                        startTimer()
                    }
                }) {
                    Text(timerRunning ? "Stop" : "Štart")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(timerRunning ? Color.red : Color.green)
                        .cornerRadius(15)
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 5)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                }
            

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading) {
                            ForEach(timerMessages, id: \.self) { message in
                                Text(message)
                                    .font(.system(size: 60))
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
                        .onChange(of: timerMessages) { _, _ in
                            if let lastMessage = timerMessages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 500)
                .padding(.horizontal)

                Spacer()
            }

            // Obrazovka po dosiahnutí maximálneho počtu otočení
            if showCompletionScreen {
                CompletionScreen(showCompletionScreen: $showCompletionScreen)
            }
        }
    }

    func startTimer() {
        timerRunning = true
        timerMessages = []
        timeElapsed = 0
        totalMinutes = 0
        UIApplication.shared.isIdleTimerDisabled = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeElapsed += 1
            if timeElapsed == turnTime {
                totalMinutes += 1
                timerMessages.append("\(totalMinutes). otočenie")
                timeElapsed = 0

                if totalMinutes >= maxTurns {
                    stopTimer()
                } else {
                    playSystemSound()
                }
            }
        }
    }

    func stopTimer() {
        timerRunning = false
        timer?.invalidate()
        timer = nil
        UIApplication.shared.isIdleTimerDisabled = false

        if totalMinutes >= maxTurns {
            showCompletionScreen = true // Zobrazí novú obrazovku
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
    @Binding var showTimePicker: Bool // Prenos väzby na zatvorenie obrazovky

    var body: some View {
        ZStack {
            // Gradientné pozadie
            LinearGradient(gradient: Gradient(colors: [Color.yellow, Color.orange]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                // Nadpis
                Text("Nastavenie časovača")
                    .font(.system(size: 36))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top)

                // Nastavenie času otočenia
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

                // Nastavenie maximálnych otočení
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

                // Celkový čas pečenia
                VStack {
                    Text("Celkový čas pečenia: \(formatTime(turnTime * maxTurns))")
                        .font(.system(size: 20))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.top)
                }

                // Tlačidlo potvrdenia
                Button(action: {
                    withAnimation {
                        showTimePicker = false // Manuálne zatvorenie obrazovky
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

    // Funkcia na formátovanie celkového času
    func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return "\(minutes) min \(seconds) s"
    }

    // Funkcia na formátovanie času otočenia
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
