const functions = require('firebase-functions');

// Import all function modules
const { sendOTPEmail, sendEmail } = require('./email');

// Export all functions
exports.sendOTPEmail = sendOTPEmail;
exports.sendEmail = sendEmail;
