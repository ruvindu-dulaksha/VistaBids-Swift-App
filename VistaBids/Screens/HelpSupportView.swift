//
//  HelpSupportView.swift
//  VistaBids
//
//  Created by Ruvindu Dulaksha on 2025-08-21.
//

import SwiftUI
import MessageUI

struct HelpSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCategory: HelpCategory?
    @State private var showingContactSheet = false
    @State private var showingMailComposer = false
    @State private var searchText = ""
    
    enum HelpCategory: String, CaseIterable {
        case account = "Account & Profile"
        case bidding = "Bidding & Auctions"
        case selling = "Selling Properties"
        case payments = "Payments & Transactions"
        case technical = "Technical Issues"
        case policies = "Policies & Terms"
        
        var icon: String {
            switch self {
            case .account: return "person.circle.fill"
            case .bidding: return "hand.raised.fill"
            case .selling: return "house.fill"
            case .payments: return "creditcard.fill"
            case .technical: return "gear.circle.fill"
            case .policies: return "doc.text.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search help articles...", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal, 16)
                    
                    // Quick Actions
                    HelpSupportQuickActionsSection(
                        onContactSupport: {
                            showingContactSheet = true
                        },
                        onEmailSupport: {
                            showingMailComposer = true
                        }
                    )
                    
                    // Help Categories
                    HelpCategoriesSection(
                        selectedCategory: $selectedCategory,
                        searchText: searchText
                    )
                    
                    // FAQ Section
                    FAQSection()
                    
                    // Contact Information
                    ContactInfoSection()
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingContactSheet) {
                ContactSupportView()
            }
            .sheet(isPresented: $showingMailComposer) {
                if MFMailComposeViewController.canSendMail() {
                    MailComposeView()
                } else {
                    MailNotAvailableView()
                }
            }
        }
    }
}

struct HelpSupportQuickActionsSection: View {
    let onContactSupport: () -> Void
    let onEmailSupport: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)
            
            HStack(spacing: 12) {
                QuickActionCard(
                    icon: "message.circle.fill",
                    title: "Contact Support",
                    subtitle: "Get instant help",
                    color: .blue,
                    action: onContactSupport
                )
                
                QuickActionCard(
                    icon: "envelope.fill",
                    title: "Email Us",
                    subtitle: "Send detailed inquiry",
                    color: .green,
                    action: onEmailSupport
                )
            }
            .padding(.horizontal, 16)
        }
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HelpCategoriesSection: View {
    @Binding var selectedCategory: HelpSupportView.HelpCategory?
    let searchText: String
    
    var filteredCategories: [HelpSupportView.HelpCategory] {
        if searchText.isEmpty {
            return HelpSupportView.HelpCategory.allCases
        }
        return HelpSupportView.HelpCategory.allCases.filter {
            $0.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Help Categories")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)
            
            LazyVStack(spacing: 12) {
                ForEach(filteredCategories, id: \.self) { category in
                    CategoryRow(
                        category: category,
                        isSelected: selectedCategory == category,
                        onTap: {
                            selectedCategory = category
                        }
                    )
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

struct CategoryRow: View {
    let category: HelpSupportView.HelpCategory
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: category.icon)
                    .font(.title2)
                    .foregroundColor(.accentBlues)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.rawValue)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(articleCount(for: category))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentBlues.opacity(0.1) : Color.cardBackground)
                    .stroke(isSelected ? Color.accentBlues : Color.clear, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func articleCount(for category: HelpSupportView.HelpCategory) -> String {
        let count = Int.random(in: 5...15) // Mock article count
        return "\(count) articles"
    }
}

struct FAQSection: View {
    @State private var expandedFAQ: String?
    
    private let faqs = [
        FAQ(
            question: "How do I place a bid on a property?",
            answer: "To place a bid, navigate to the property listing, tap 'Place Bid', enter your bid amount (must be higher than current bid), and confirm. You'll receive notifications about bid status updates."
        ),
        FAQ(
            question: "What payment methods are accepted?",
            answer: "We accept credit cards, debit cards, bank transfers, and digital wallets. All payments are processed securely through our encrypted payment system."
        ),
        FAQ(
            question: "How do I list my property for sale?",
            answer: "Go to 'My Properties' in your profile, tap the '+' button, fill in property details, upload photos, set your price, and submit for review. Your listing will be live within 24 hours."
        ),
        FAQ(
            question: "What happens if I win an auction?",
            answer: "You'll receive a notification and email confirmation. You have 48 hours to complete the payment. Once paid, you'll receive property documents and can coordinate the transfer process."
        ),
        FAQ(
            question: "How can I contact the seller?",
            answer: "Use the 'Contact Seller' button on any property listing. This opens a secure messaging channel where you can ask questions and negotiate terms."
        )
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Frequently Asked Questions")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)
            
            LazyVStack(spacing: 8) {
                ForEach(faqs, id: \.question) { faq in
                    FAQRow(
                        faq: faq,
                        isExpanded: expandedFAQ == faq.question,
                        onTap: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                expandedFAQ = expandedFAQ == faq.question ? nil : faq.question
                            }
                        }
                    )
                    .padding(.horizontal, 16)
                }
            }
        }
    }
}

struct FAQ {
    let question: String
    let answer: String
}

struct FAQRow: View {
    let faq: FAQ
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack {
                    Text(faq.question)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(16)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 0) {
                    Divider()
                        .padding(.horizontal, 16)
                    
                    Text(faq.answer)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

struct ContactInfoSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contact Information")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)
            
            VStack(spacing: 12) {
                ContactInfoRow(
                    icon: "envelope.fill",
                    title: "Email Support",
                    subtitle: "support@vistabids.com",
                    action: {
                        if let url = URL(string: "mailto:support@vistabids.com") {
                            UIApplication.shared.open(url)
                        }
                    }
                )
                
                ContactInfoRow(
                    icon: "phone.fill",
                    title: "Phone Support",
                    subtitle: "+1 (555) 123-4567",
                    action: {
                        if let url = URL(string: "tel:+15551234567") {
                            UIApplication.shared.open(url)
                        }
                    }
                )
                
                ContactInfoRow(
                    icon: "clock.fill",
                    title: "Support Hours",
                    subtitle: "Mon-Fri: 9AM-6PM EST",
                    action: nil
                )
            }
            .padding(.horizontal, 16)
        }
    }
}

struct ContactInfoRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentBlues)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if action != nil {
                Button(action: action!) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color.cardBackground)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .contentShape(Rectangle())
        .onTapGesture {
            action?()
        }
    }
}

struct ContactSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var subject = ""
    @State private var message = ""
    @State private var selectedCategory = "General"
    @State private var isSubmitting = false
    
    private let categories = ["General", "Account", "Bidding", "Technical", "Billing", "Other"]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("Your full name", text: $name)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("your.email@example.com", text: $email)
                            .textFieldStyle(CustomTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Picker("Category", selection: $selectedCategory) {
                            ForEach(categories, id: \.self) { category in
                                Text(category).tag(category)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Subject")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("Brief description of your issue", text: $subject)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Message")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextEditor(text: $message)
                            .frame(minHeight: 120)
                            .padding(12)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Button(action: submitSupportRequest) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isSubmitting ? "Submitting..." : "Submit Request")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .foregroundColor(.white)
                        .background(Color.accentBlues)
                        .cornerRadius(12)
                    }
                    .disabled(isSubmitting || !isFormValid)
                    .opacity(isFormValid ? 1.0 : 0.6)
                }
                .padding(20)
            }
            .navigationTitle("Contact Support")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && !subject.isEmpty && !message.isEmpty
    }
    
    private func submitSupportRequest() {
        isSubmitting = true
        
        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isSubmitting = false
            // Show success message and dismiss
            dismiss()
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
    }
}

struct MailComposeView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mail = MFMailComposeViewController()
        mail.mailComposeDelegate = context.coordinator
        mail.setToRecipients(["support@vistabids.com"])
        mail.setSubject("VistaBids Support Request")
        return mail
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView
        
        init(_ parent: MailComposeView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.dismiss()
        }
    }
}

struct MailNotAvailableView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "envelope.slash")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            Text("Mail Not Available")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Please configure your email app or contact us at support@vistabids.com")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("OK") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(20)
    }
}

#Preview {
    HelpSupportView()
}
