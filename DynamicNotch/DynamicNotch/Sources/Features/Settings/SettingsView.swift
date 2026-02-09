import SwiftUI

struct SettingsView: View {
    @AppStorage("hoverDelay") private var hoverDelay: Double = 2.0
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    @AppStorage("showCalendar") private var showCalendar: Bool = true
    
    var body: some View {
        Form {
            Section {
                // --- KAPANMA GECİKMESİ ---
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "timer")
                        Text("Kapanma Gecikmesi")
                            .font(.headline)
                    }
                    
                    HStack {
                        Text("Hızlı (0.5s)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Slider(value: $hoverDelay, in: 0.5...5.0, step: 0.5) {
                            Text("Süre")
                        }
                        
                        Text("Yavaş (5.0s)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Seçili Süre: **\(String(format: "%.1f", hoverDelay)) saniye**")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 5)
                
            } header: {
                Text("Davranış")
            } footer: {
                Text("Fareyi çentikten çektikten sonra pencerenin ne kadar açık kalacağını belirler.")
            }
            
            Section("Görünüm") {
                Toggle(isOn: $showCalendar) {
                    HStack {
                        Image(systemName: "calendar")
                        Text("Takvimi Göster")
                    }
                }
            }
            
            Section("Sistem") {
                Toggle(isOn: $launchAtLogin) {
                    HStack {
                        Image(systemName: "laptopcomputer")
                        Text("Başlangıçta Çalıştır")
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 400, height: 350)
        .padding()
    }
}

#Preview {
    SettingsView()
}
