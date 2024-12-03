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
        ZStack {
            // Farebné pozadie s jemnejším gradientom
            LinearGradient(gradient: Gradient(colors: [Color.yellow, Color.orange]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("Nastav čas otočenia")
                    .font(.system(size: 36))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top)
                
                // Nastavenie času pomocou vlastných tlačidiel
                VStack(spacing: 20) {
                    Text("\(turnTime) sekúnd")
                        .font(.system(size: 48))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 20) {
                        // Tlačidlo na zníženie času
                        Button(action: {
                            if turnTime > 10 { turnTime -= 10 }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.red)
                        }
                        
                        // Tlačidlo na zvýšenie času
                        Button(action: {
                            if turnTime < 300 { turnTime += 10 }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // Tlačidlo na zatvorenie
                Button(action: {
                    dismiss()
                }) {
                    Text("Nastav")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
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
}
