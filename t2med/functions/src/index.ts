import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as nodemailer from "nodemailer";

admin.initializeApp();

// --- Start of diagnostic logging ---
console.log("Function container initializing...");

let gmailEmail: string | undefined;
let gmailPassword: string | undefined;
let transporter: nodemailer.Transporter;

try {
  // Access config variables.
  gmailEmail = functions.config().gmail.email as string;
  gmailPassword = functions.config().gmail.password as string;

  console.log(`Gmail email loaded: ${gmailEmail ? 'Exists' : 'MISSING'}`);
  console.log(`Gmail password loaded: ${gmailPassword ? 'Exists' : 'MISSING'}`);


  if (!gmailEmail || !gmailPassword) {
    console.error("Gmail credentials are not set in functions config.");
  } else {
    // Configure Nodemailer transporter using Gmail
    transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: gmailEmail,
        pass: gmailPassword,
      },
    });
    console.log("Nodemailer transporter created successfully.");
  }
} catch (error) {
    console.error("Error during initialization or transporter creation:", error);
}
// --- End of diagnostic logging ---


// Interface for the data expected by the function
interface EmailSendData {
  to: string;
  pdfBase64: string;
  subject: string;
  body: string;
}

/**
 * A callable function to send an email with a PDF attachment.
 */
export const sendEmail = functions.https.onCall(async (data, context) => {
  // --- Start of diagnostic logging ---
  console.log("sendEmail function triggered.");
  
  if (!transporter) {
    console.error("Nodemailer transporter is not initialized. Cannot send email.");
    throw new functions.https.HttpsError(
      "internal",
      "Email service is not configured correctly."
    );
  }
  // --- End of diagnostic logging ---

  // Cast the incoming data through 'unknown' to satisfy strict type checking
  const { to, pdfBase64, subject, body } = data as unknown as EmailSendData;
  
  console.log(`Attempting to send email to: ${to}`); // Log recipient

  if (!to || !pdfBase64 || !subject || !body) {
    console.error("Invalid arguments received:", { to: !!to, pdfBase64: !!pdfBase64, subject: !!subject, body: !!body });
    throw new functions.https.HttpsError(
      "invalid-argument",
      "The function must be called with arguments 'to', 'pdfBase64', 'subject', and 'body'."
    );
  }

  const mailOptions = {
    from: `T2Med App <${gmailEmail}>`,
    to: to,
    subject: subject,
    html: `<p>${body}</p>`,
    attachments: [
      {
        filename: "historial.pdf",
        content: pdfBase64,
        encoding: "base64",
      },
    ],
  };

  try {
    console.log("Sending mail with Nodemailer...");
    await transporter.sendMail(mailOptions);
    console.log(`Email successfully sent to ${to}`);
    return { success: true, message: "Email sent successfully!" };
  } catch (error) {
    console.error("There was an error while sending the email:", error);
    // Throwing a new error to be caught by the client
    throw new functions.https.HttpsError(
      "internal",
      "Error sending email.",
      error // Optionally pass the original error details
    );
  }
});
