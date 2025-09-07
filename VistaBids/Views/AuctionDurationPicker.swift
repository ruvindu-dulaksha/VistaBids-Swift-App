import SwiftUI

struct AuctionDurationPicker: View {
    @Binding var selectedDuration: AuctionDuration
    @State private var showCustomDuration = false
    @State private var customHours: Int = 1
    @State private var customMinutes: Int = 0
    
    private let predefinedDurations: [AuctionDuration] = [
        .fiveMinutes,
        .tenMinutes,
        .fifteenMinutes,
        .thirtyMinutes,
        .oneHour,
        .twoHours,
        .oneDay
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Auction Duration")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Select how long your auction will run")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(predefinedDurations, id: \.self) { duration in
                    DurationCard(
                        duration: duration,
                        isSelected: selectedDuration == duration,
                        onTap: {
                            selectedDuration = duration
                            showCustomDuration = false
                        }
                    )
                }
                
                // Custom duration option
                Button(action: {
                    showCustomDuration.toggle()
                }) {
                    VStack(spacing: 8) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Text("Custom")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Set your own")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(showCustomDuration ? Color.blue.opacity(0.1) : Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(showCustomDuration ? Color.blue : Color.clear, lineWidth: 2)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if showCustomDuration {
                customDurationView
            }
            
            // Duration info
            durationInfoView
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
    }
    
    private var customDurationView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Custom Duration")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack(spacing: 20) {
                VStack {
                    Text("Hours")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("Hours", selection: $customHours) {
                        ForEach(0...23, id: \.self) { hour in
                            Text("\(hour)").tag(hour)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 80, height: 100)
                    .clipped()
                }
                
                VStack {
                    Text("Minutes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("Minutes", selection: $customMinutes) {
                        ForEach([0, 15, 30, 45], id: \.self) { minute in
                            Text("\(minute)").tag(minute)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(width: 80, height: 100)
                    .clipped()
                }
                
                Spacer()
            }
            
            Button("Apply Custom Duration") {
                let totalMinutes = customHours * 60 + customMinutes
                if totalMinutes >= 5 { // Minimum 5 minutes
                    selectedDuration = .custom
                    showCustomDuration = false
                }
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                (customHours > 0 || customMinutes >= 5) ? Color.blue : Color.gray
            )
            .cornerRadius(8)
            .disabled(customHours == 0 && customMinutes < 5)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .transition(.opacity.combined(with: .scale))
        .animation(.easeInOut(duration: 0.3), value: showCustomDuration)
    }
    
    private var durationInfoView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("Selected Duration: \(selectedDuration.displayText)")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Duration Tips:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                Text("• Shorter durations create urgency and faster sales")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("• Longer durations allow more bidders to participate")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("• Popular times: 15-30 minutes for quick sales, 1-2 hours for premium properties")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(8)
    }
}

struct DurationCard: View {
    let duration: AuctionDuration
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(duration.displayText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(popularityText)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var iconName: String {
        switch duration {
        case .fiveMinutes, .tenMinutes, .fifteenMinutes:
            return "bolt.fill"
        case .thirtyMinutes:
            return "clock"
        case .oneHour, .twoHours, .threeHours:
            return "clock.badge"
        case .oneDay, .custom:
            return "calendar"
        }
    }
    
    private var popularityText: String {
        switch duration {
        case .fiveMinutes:
            return "Quick Sale"
        case .tenMinutes:
            return "Fast Pace"
        case .fifteenMinutes:
            return "Popular"
        case .thirtyMinutes:
            return "Most Popular"
        case .oneHour:
            return "Standard"
        case .twoHours:
            return "Extended"
        case .threeHours:
            return "Long Extended"
        case .oneDay:
            return "Maximum"
        case .custom:
            return "Custom"
        }
    }
}

struct AuctionSchedulePicker: View {
    @Binding var startTime: Date
    @Binding var duration: AuctionDuration
    @State private var scheduleOption: ScheduleOption = .now
    
    enum ScheduleOption: String, CaseIterable {
        case now = "Start Now"
        case later = "Schedule Later"
        
        var displayText: String {
            return self.rawValue
        }
    }
    
    var endTime: Date {
        return startTime.addingTimeInterval(duration.timeInterval)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Auction Schedule")
                .font(.headline)
            
            // Schedule option picker
            Picker("Schedule Option", selection: $scheduleOption) {
                ForEach(ScheduleOption.allCases, id: \.self) { option in
                    Text(option.displayText).tag(option)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: scheduleOption) { _, newOption in
                if newOption == .now {
                    startTime = Date()
                }
            }
            
            if scheduleOption == .later {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Start Date & Time")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    DatePicker(
                        "Auction Start Time",
                        selection: $startTime,
                        in: Date()...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(CompactDatePickerStyle())
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Duration picker
            AuctionDurationPicker(selectedDuration: $duration)
            
            // Schedule summary
            scheduleInfoView
        }
    }
    
    private var scheduleInfoView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Auction Summary")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Starts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(startTime, formatter: fullDateFormatter)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.blue)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Ends")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(endTime, formatter: fullDateFormatter)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
            
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                Text("Duration: \(duration.displayText)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(12)
    }
    
    private var fullDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            AuctionDurationPicker(selectedDuration: .constant(.thirtyMinutes))
            
            AuctionSchedulePicker(
                startTime: .constant(Date()),
                duration: .constant(.thirtyMinutes)
            )
        }
        .padding()
    }
}
