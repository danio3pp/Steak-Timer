import SwiftUI
import AVFoundation
import AudioToolbox // Import pre systémové zvuky

struct ContentView: View {
    @State private var timeElapsed: Int = 0 // Uchováva počet sekúnd od aktuálneho štartu
    @State private var timerRunning: Bool = false
    @State private var timerMessages: [String] = [] // Ukladá správy o otočeniach
    @State private var totalMinutes: Int = 0 // Sleduje celkový počet otočení
    @State private var timer: Timer? = nil // Uchováva časovač
    @State private var turnTime: Int = 60 // Predvolený čas pre otočenie
    @State private var showTimePicker: Bool = false // Riadi zobrazenie dialogu pre výber času
    
    var body: some View {
        ZStack {
            // Farebné pozadie s gradientom
            LinearGradient(gradient: Gradient(colors: [Color.orange, Color.red]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Zobrazenie časovača
                VStack {
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
                    
                    // Ikona na úpravu času pod časovačom
                    Button(action: {
                        showTimePicker = true // Zobraz výber času
                    }) {
                        Image(systemName: "pencil.circle")
                            .font(.title)
                            .foregroundColor(.yellow)
                            .shadow(radius: 5)
                    }
                    .sheet(isPresented: $showTimePicker) {
                        TimePickerView(turnTime: $turnTime)
                    }
                }
                
                // Tlačidlo Start
                Button(action: {
                    if timerRunning {
                        stopTimer()
                    } else {
                        startTimer()
                    }
                }) {
                    Text(timerRunning ? "Stop" : "Start")
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
                
                // Zobrazenie správ o otočeniach
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
        }
    }
    
    // Spustenie časovača
    func startTimer() {
        timerRunning = true
        timerMessages = [] // Vyčisti správy pri novom štarte
        timeElapsed = 0
        totalMinutes = 0
        UIApplication.shared.isIdleTimerDisabled = true // Zabráni stlmeniu obrazovky
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            timeElapsed += 1
            if timeElapsed == turnTime { // Reset po dosiahnutí nastaveného času
                totalMinutes += 1
                timerMessages.append("\(totalMinutes). otočenie")
                timeElapsed = 0 // Reset časovača
                playSystemSound() // Prehraj systémový tón
            }
        }
    }
    
    // Zastavenie časovača
    func stopTimer() {
        timerRunning = false
        timer?.invalidate()
        timer = nil
        UIApplication.shared.isIdleTimerDisabled = false // Obnoví automatické stlmenie obrazovky
    }
    
    // Funkcia na prehrávanie systémového zvuku
    func playSystemSound() {
        AudioServicesPlaySystemSound(1005) // 1005 je kód pre "Mail Sent"
    }
}

// View pre výber času otočenia
struct TimePickerView: View {
    @Binding var turnTime: Int
    @Environment(\.dismiss) var dismiss // Umožní zatvoriť sheet
    
    var body: some View {
        VStack {
            Text("Nastav čas otočenia (sekundy)")
                .font(.headline)
                .padding()
            
            Stepper(value: $turnTime, in: 10...300, step: 10) {
                Text("\(turnTime) s")
                    .font(.title)
            }
            .padding()
            
            Button("Hotovo") {
                dismiss() // Zatvor výber
            }
            .font(.title2)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}
