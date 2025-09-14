const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

// Initialize Firebase Admin
if (!admin.apps.length) {
    admin.initializeApp();
}

// Configure email transporter (using Gmail for demo)
// In production, use a professional email service like SendGrid
const transporter = nodemailer.createTransporter({
    service: 'gmail',
    auth: {
        user: functions.config().email?.user || 'your-email@gmail.com',
        pass: functions.config().email?.password || 'your-app-password'
    }
});

// Cloud Function to send OTP email
exports.sendOTPEmail = functions.https.onCall(async (data, context) => {
    try {
        const { email, otp, amount, propertyTitle } = data;
        
        if (!email || !otp) {
            throw new functions.https.HttpsError('invalid-argument', 'Email and OTP are required');
        }
        
        const mailOptions = {
            from: 'VistaBids <noreply@vistabids.com>',
            to: email,
            subject: 'VistaBids Payment Verification - OTP',
            html: `
                <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                    <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; color: white;">
                        <h1>VistaBids</h1>
                        <h2>Payment Verification</h2>
                    </div>
                    
                    <div style="padding: 30px; background: #f9f9f9;">
                        <h3>Your OTP Code</h3>
                        <div style="background: white; padding: 20px; border-radius: 8px; text-align: center; margin: 20px 0;">
                            <h1 style="color: #667eea; font-size: 32px; letter-spacing: 5px; margin: 0;">${otp}</h1>
                        </div>
                        
                        <h4>Payment Details:</h4>
                        <ul style="list-style: none; padding: 0;">
                            <li><strong>Property:</strong> ${propertyTitle}</li>
                            <li><strong>Amount:</strong> $${Math.round(amount).toLocaleString()}</li>
                        </ul>
                        
                        <p style="color: #666; font-size: 14px;">
                            This OTP will expire in 5 minutes for your security.
                        </p>
                        
                        <p style="color: #666; font-size: 12px;">
                            If you did not request this payment, please ignore this email and contact our support team.
                        </p>
                    </div>
                    
                    <div style="padding: 20px; text-align: center; color: #666; font-size: 12px;">
                        Best regards,<br>
                        The VistaBids Team
                    </div>
                </div>
            `
        };
        
        await transporter.sendMail(mailOptions);
        
        // Log the email in Firestore
        await admin.firestore().collection('email_logs').add({
            to: email,
            subject: mailOptions.subject,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            type: 'otp_verification',
            status: 'sent'
        });
        
        return { success: true, message: 'OTP email sent successfully' };
        
    } catch (error) {
        console.error('Error sending OTP email:', error);
        throw new functions.https.HttpsError('internal', 'Failed to send email');
    }
});

// Cloud Function to send general emails
exports.sendEmail = functions.https.onCall(async (data, context) => {
    try {
        const { to, subject, text, html } = data;
        
        if (!to || !subject || (!text && !html)) {
            throw new functions.https.HttpsError('invalid-argument', 'Required fields missing');
        }
        
        const mailOptions = {
            from: 'VistaBids <noreply@vistabids.com>',
            to,
            subject,
            text,
            html
        };
        
        await transporter.sendMail(mailOptions);
        
        // Log the email in Firestore
        await admin.firestore().collection('email_logs').add({
            to,
            subject,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
            type: 'general',
            status: 'sent'
        });
        
        return { success: true, message: 'Email sent successfully' };
        
    } catch (error) {
        console.error('Error sending email:', error);
        throw new functions.https.HttpsError('internal', 'Failed to send email');
    }
});