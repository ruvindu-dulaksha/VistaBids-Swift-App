//
//  EventViews.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-09.
//

import SwiftUI
import CoreLocation

//  New Event View
struct NewEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @State private var eventTitle = ""
    @State private var eventDescription = ""
    @State private var eventDate = Date()
    @State private var eventLocation = ""
    @State private var selectedCategory: EventCategory = .auction
    @State private var isLocationPickerPresented = false
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var isSubmitting = false
    
    let communityService: CommunityService
    
    private let categories: [EventCategory] = [.auction, .viewing, .seminar, .networking, .consultation, .workshop]
    
    var isFormValid: Bool {
        !eventTitle.isEmpty && !eventDescription.isEmpty && !eventLocation.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                eventFormContent()
            }
            .navigationTitle("New Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $isLocationPickerPresented) {
                LocationPickerView(selectedLocation: $eventLocation, selectedCoordinate: $selectedLocation)
            }
        }
    }
    
    @ViewBuilder
    private func eventFormContent() -> some View {
        VStack(spacing: 20) {
            
            // Event Title
            VStack(alignment: .leading, spacing: 8) {
                Text("Event Title")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                TextField("Enter event title", text: $eventTitle)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(12)
                    .background(Color.inputFields)
                    .cornerRadius(10)
            }
            
            // Event Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                TextField("Describe your event", text: $eventDescription, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(12)
                    .background(Color.inputFields)
                    .cornerRadius(10)
                    .lineLimit(5...10)
            }
            
            // Event Category
            categorySection()
            
            // Event Date & Time
            VStack(alignment: .leading, spacing: 8) {
                Text("Date & Time")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.textPrimary)
                
                DatePicker("Select date and time", selection: $eventDate, in: Date()...)
                    .datePickerStyle(CompactDatePickerStyle())
                    .padding(12)
                    .background(Color.inputFields)
                    .cornerRadius(10)
            }
            
            // Location
            locationSection()
            
            Spacer(minLength: 30)
            
            // Submit Button
            submitButton()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    @ViewBuilder
    private func categorySection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        HStack {
                            Image(systemName: categoryIcon(for: category))
                                .font(.title2)
                            
                            Text(categoryTitle(for: category))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                        }
                        .foregroundColor(selectedCategory == category ? .white : .textPrimary)
                        .padding(12)
                        .background(selectedCategory == category ? Color.accentBlues : Color.inputFields)
                        .cornerRadius(10)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func locationSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)
            
            Button(action: {
                isLocationPickerPresented = true
            }) {
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(.accentBlues)
                    
                    Text(eventLocation.isEmpty ? "Add location" : eventLocation)
                        .foregroundColor(eventLocation.isEmpty ? .secondary : .textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(Color.inputFields)
                .cornerRadius(10)
            }
        }
    }
    
    @ViewBuilder
    private func submitButton() -> some View {
        Button(action: createEvent) {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(isSubmitting ? "Creating Event..." : "Create Event")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isFormValid && !isSubmitting ? Color.accentBlues : Color.gray)
            .cornerRadius(12)
        }
        .disabled(!isFormValid || isSubmitting)
    }
    
    private func categoryIcon(for category: EventCategory) -> String {
        switch category {
        case .auction: return "hammer.fill"
        case .viewing: return "eye.fill"
        case .seminar: return "person.3.fill"
        case .networking: return "network"
        case .consultation: return "person.2.fill"
        case .workshop: return "wrench.and.screwdriver.fill"
        case .meetup: return "person.2.wave.2.fill"
        }
    }
    
    private func categoryTitle(for category: EventCategory) -> String {
        switch category {
        case .auction: return "Auction"
        case .viewing: return "Property Viewing"
        case .seminar: return "Seminar"
        case .networking: return "Networking"
        case .consultation: return "Consultation"
        case .workshop: return "Workshop"
        case .meetup: return "Meetup"
        }
    }
    
    private func createEvent() {
        isSubmitting = true
        
        Task {
            do {
                let eventLocationStruct = EventLocation(
                    name: eventLocation,
                    address: eventLocation,
                    latitude: selectedLocation?.latitude ?? 0,
                    longitude: selectedLocation?.longitude ?? 0
                )
                
                // Create the event using communityService
                await communityService.createEvent(
                    title: eventTitle, 
                    description: eventDescription, 
                    date: eventDate, 
                    location: eventLocationStruct, 
                    category: selectedCategory, 
                    maxAttendees: 50
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("Failed to create event: \(error)")
                await MainActor.run {
                    isSubmitting = false
                }
            }
        }
    }
}

// Event Detail View
struct EventDetailView: View {
    let event: CommunityEvent
    let communityService: CommunityService
    
    @State private var isAttending = false
    @State private var isJoining = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                eventImageHeader()
                eventDetailsContent()
            }
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkAttendanceStatus()
        }
    }
    
    @ViewBuilder
    private func eventImageHeader() -> some View {
        Rectangle()
            .fill(Color.accentBlues.opacity(0.3))
            .frame(height: 200)
            .overlay(
                VStack {
                    Image(systemName: categoryIcon(for: event.category))
                        .font(.system(size: 40))
                        .foregroundColor(.accentBlues)
                    
                    Text(categoryTitle(for: event.category))
                        .font(.caption)
                        .foregroundColor(.accentBlues)
                }
            )
            .cornerRadius(12)
    }
    
    @ViewBuilder
    private func eventDetailsContent() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            
            // Event Title
            Text(event.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)
            
            // Event Details
            eventDetailsSection()
            
            Divider()
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.textPrimary)
                
                Text(event.description)
                    .font(.body)
                    .foregroundColor(.textPrimary)
                    .lineSpacing(4)
            }
            
            Spacer(minLength: 30)
            
            // Join Button
            attendanceButton()
        }
        .padding(.horizontal, 20)
    }
    
    @ViewBuilder
    private func eventDetailsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Date & Time
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.accentBlues)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.date, style: .date)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.textPrimary)
                    
                    Text(event.date, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Location
            HStack {
                Image(systemName: "location")
                    .foregroundColor(.accentBlues)
                
                Text(event.location.name)
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
            }
            
            // Attendees
            HStack {
                Image(systemName: "person.3")
                    .foregroundColor(.accentBlues)
                
                Text("\(event.attendees.count) attending")
                    .font(.subheadline)
                    .foregroundColor(.textPrimary)
                
                Text("/ \(event.maxAttendees) max")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Created by
            HStack {
                Image(systemName: "person.circle")
                    .foregroundColor(.accentBlues)
                
                Text("Organized by User ID: \(event.userId)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private func attendanceButton() -> some View {
        Button(action: toggleAttendance) {
            HStack {
                if isJoining {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(isAttending ? "Leave Event" : "Join Event")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(isAttending ? Color.red : Color.accentBlues)
            .cornerRadius(12)
        }
        .disabled(isJoining)
    }
    
    private func categoryIcon(for category: EventCategory) -> String {
        switch category {
        case .auction: return "hammer.fill"
        case .viewing: return "eye.fill"
        case .seminar: return "person.3.fill"
        case .networking: return "network"
        case .consultation: return "person.2.fill"
        case .workshop: return "wrench.and.screwdriver.fill"
        case .meetup: return "person.2.wave.2.fill"
        }
    }
    
    private func categoryTitle(for category: EventCategory) -> String {
        switch category {
        case .auction: return "Auction"
        case .viewing: return "Property Viewing"
        case .seminar: return "Seminar"
        case .networking: return "Networking"
        case .consultation: return "Consultation"
        case .workshop: return "Workshop"
        case .meetup: return "Meetup"
        }
    }
    
    private func checkAttendanceStatus() {
        isAttending = event.attendees.contains("user1") 
    }
    
    private func toggleAttendance() {
        isJoining = true
        
        Task {
            do {
                if isAttending {
                    try await communityService.leaveEvent(eventId: event.id ?? "")
                } else {
                    try await communityService.joinEvent(event.id ?? "")
                }
                
                await MainActor.run {
                    isAttending.toggle()
                    isJoining = false
                }
            } catch {
                print("Failed to toggle attendance: \(error)")
                await MainActor.run {
                    isJoining = false
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        NewEventView(communityService: CommunityService())
    }
}
