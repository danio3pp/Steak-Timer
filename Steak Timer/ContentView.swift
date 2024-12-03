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
    @State private var maxTurns: Int = 6
    @State private var showTimePicker: Bool = false
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.orange, Color.red]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
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
                    
                    Button(action: {
                        showTimePicker = true
                    }) {
                        Image(systemName: "pencil.circle")
                            .font(.title)
                            .foregroundColor(.yellow)
                            .shadow(radius: 5)
                    }
                    .sheet(isPresented: $showTimePicker) {
                        TimePickerView(turnTime: $turnTime, maxTurns: $maxTurns)
                    }
                }
                
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
    }
    
    func playSystemSound() {
        AudioServicesPlaySystemSound(1005)
    }
}

struct TimePickerView: View {
    @Binding var turnTime: Int
    @Binding var maxTurns: Int
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.yellow, Color.orange]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Text("Čas otočenia")
                    .font(.system(size: 36))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.top)
                
                VStack(spacing: 20) {
                    Text("\(turnTime) s")
                        .font(.system(size: 48))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            if turnTime > 10 { turnTime -= 10 }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.red)
                        }
                        
                        Button(action: {
                            if turnTime < 300 { turnTime += 10 }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                        }
                    }
                }
                
                VStack(spacing: 20) {
                    Text("Počet otočení")
                        .font(.system(size: 36))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("\(maxTurns)")
                        .font(.system(size: 48))
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            if maxTurns > 1 { maxTurns -= 1 }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.red)
                        }
                        
                        Button(action: {
                            maxTurns += 1
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.green)
                        }
                    }
                }
                
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
