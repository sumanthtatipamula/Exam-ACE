const {onCall, onRequest} = require('firebase-functions/v2/https');
const {defineSecret} = require('firebase-functions/params');
const admin = require('firebase-admin');
const fetch = require('node-fetch');

admin.initializeApp();

// Define the Resend API key as a secret
const resendApiKey = defineSecret('RESEND_API_KEY');

/**
 * Send verification email using Resend API
 * 
 * Callable function - requires authentication
 * 
 * @param {Object} data
 * @param {string} data.email - Recipient email
 * @param {string} data.userName - User's display name
 * @param {string} data.verificationLink - Email verification link
 */
exports.sendVerificationEmail = onCall(
  {secrets: [resendApiKey]},
  async (request) => {
    // Verify user is authenticated
    if (!request.auth) {
      throw new Error('User must be authenticated to send verification email');
    }

    const {email, userName, verificationLink} = request.data;

    // Validate input
    if (!email || !userName || !verificationLink) {
      throw new Error('Missing required fields: email, userName, verificationLink');
    }

    try {
      const response = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${resendApiKey.value()}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: 'Exam Ace <noreply@resend.dev>', // Update with your verified domain
          to: [email],
          subject: 'Verify your Exam Ace account',
          html: buildVerificationEmailHtml(userName, verificationLink),
        }),
      });

      const result = await response.json();

      if (!response.ok) {
        console.error('Resend API error:', result);
        throw new Error('Failed to send email');
      }

      return {
        success: true,
        messageId: result.id,
      };
    } catch (error) {
      console.error('Error sending verification email:', error);
      throw new Error('Failed to send verification email: ' + error.message);
    }
  }
);

/**
 * Send password reset email using Resend API
 * 
 * Callable function - does NOT require authentication (user forgot password)
 * Generates a secure token, stores it in Firestore, and sends email via Resend
 * 
 * @param {Object} data
 * @param {string} data.email - User's email address
 */
exports.sendPasswordResetEmail = onCall(
  {secrets: [resendApiKey]},
  async (request) => {
    const {email} = request.data;

    // Validate input
    if (!email) {
      throw new Error('Email is required');
    }

    const normalizedEmail = email.trim().toLowerCase();

    try {
      // Check if user exists in Firebase Auth
      let userRecord;
      try {
        userRecord = await admin.auth().getUserByEmail(normalizedEmail);
      } catch (error) {
        console.log('User not found for email:', normalizedEmail);
        throw new Error('No account found with this email address');
      }

      // Generate secure random token
      const crypto = require('crypto');
      const token = crypto.randomBytes(32).toString('hex');
      
      const now = admin.firestore.Timestamp.now();
      const expiresAt = admin.firestore.Timestamp.fromMillis(
        now.toMillis() + 60 * 60 * 1000 // 1 hour from now
      );

      // Store token in Firestore
      await admin.firestore()
        .collection('passwordResetTokens')
        .doc(token)
        .set({
          email: normalizedEmail,
          token: token,
          createdAt: now,
          expiresAt: expiresAt,
          used: false,
        });

      // Build reset link - use a web URL that can redirect to app
      // For now, use Firebase hosting or your domain
      // This will open in browser and can be handled by your app
      const resetLink = `https://examace.sumanthtatipamula.com/reset-password?token=${token}`;
      
      // Get user's display name
      const userName = userRecord.displayName || normalizedEmail.split('@')[0];

      // Send email via Resend
      const response = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${resendApiKey.value()}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: 'Exam Ace <noreply@sumanthtatipamula.com>',
          to: [normalizedEmail],
          subject: 'Reset your Exam Ace password',
          html: buildPasswordResetEmailHtml(userName, resetLink),
        }),
      });

      const result = await response.json();

      if (!response.ok) {
        console.error('Resend API error:', result);
        throw new Error('Failed to send email');
      }

      return {
        success: true,
        messageId: result.id,
      };
    } catch (error) {
      console.error('Error sending password reset email:', error);
      throw new Error('Failed to send password reset email: ' + error.message);
    }
  }
);

/**
 * Verify password reset token and update password
 * 
 * @param {Object} data
 * @param {string} data.token - Reset token from email
 * @param {string} data.newPassword - New password
 */
exports.verifyPasswordResetToken = onCall(async (request) => {
  const {token, newPassword} = request.data;

  if (!token || !newPassword) {
    throw new Error('Token and new password are required');
  }

  if (newPassword.length < 6) {
    throw new Error('Password must be at least 6 characters');
  }

  try {
    // Get token from Firestore
    const tokenDoc = await admin.firestore()
      .collection('passwordResetTokens')
      .doc(token)
      .get();

    if (!tokenDoc.exists) {
      throw new Error('Invalid or expired reset link');
    }

    const tokenData = tokenDoc.data();

    // Check if token is already used
    if (tokenData.used) {
      throw new Error('This reset link has already been used');
    }

    // Check if token is expired
    const now = admin.firestore.Timestamp.now();
    if (now.toMillis() > tokenData.expiresAt.toMillis()) {
      throw new Error('This reset link has expired');
    }

    // Get user and update password
    const userRecord = await admin.auth().getUserByEmail(tokenData.email);
    await admin.auth().updateUser(userRecord.uid, {
      password: newPassword,
    });

    // Mark token as used
    await tokenDoc.ref.update({used: true});

    return {
      success: true,
      message: 'Password updated successfully',
    };
  } catch (error) {
    console.error('Error verifying reset token:', error);
    throw new Error(error.message || 'Failed to reset password');
  }
});

/**
 * Send email verification link using Resend API
 * 
 * Callable function - requires authentication
 * Generates a secure token, stores it in Firestore, and sends email via Resend
 * 
 * @param {Object} data
 * @param {string} data.email - User's email address
 * @param {string} data.userName - User's display name
 */
exports.sendEmailVerification = onCall(
  {secrets: [resendApiKey]},
  async (request) => {
    // Verify user is authenticated
    if (!request.auth) {
      throw new Error('User must be authenticated to send verification email');
    }

    const {email, userName} = request.data;

    // Validate input
    if (!email || !userName) {
      throw new Error('Email and userName are required');
    }

    const normalizedEmail = email.trim().toLowerCase();

    try {
      // Generate secure random token
      const crypto = require('crypto');
      const token = crypto.randomBytes(32).toString('hex');
      
      const now = admin.firestore.Timestamp.now();
      const expiresAt = admin.firestore.Timestamp.fromMillis(
        now.toMillis() + 24 * 60 * 60 * 1000 // 24 hours from now
      );

      // Store token in Firestore
      await admin.firestore()
        .collection('emailVerificationTokens')
        .doc(token)
        .set({
          email: normalizedEmail,
          token: token,
          createdAt: now,
          expiresAt: expiresAt,
          used: false,
        });

      // Build verification link - use a web URL that can redirect to app
      const verificationLink = `https://examace.sumanthtatipamula.com/verify-email?token=${token}`;

      // Send email via Resend
      const response = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${resendApiKey.value()}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          from: 'Exam Ace <noreply@sumanthtatipamula.com>',
          to: [normalizedEmail],
          subject: 'Verify your Exam Ace account',
          html: buildVerificationEmailHtml(userName, verificationLink),
        }),
      });

      const result = await response.json();

      if (!response.ok) {
        console.error('Resend API error:', result);
        throw new Error('Failed to send email');
      }

      return {
        success: true,
        messageId: result.id,
      };
    } catch (error) {
      console.error('Error sending verification email:', error);
      throw new Error('Failed to send verification email: ' + error.message);
    }
  }
);

/**
 * Verify email verification token
 * 
 * @param {Object} data
 * @param {string} data.token - Verification token from email
 */
exports.verifyEmailToken = onCall(async (request) => {
  const {token} = request.data;

  if (!token) {
    throw new Error('Token is required');
  }

  try {
    // Get token from Firestore
    const tokenDoc = await admin.firestore()
      .collection('emailVerificationTokens')
      .doc(token)
      .get();

    if (!tokenDoc.exists) {
      throw new Error('Invalid or expired verification link');
    }

    const tokenData = tokenDoc.data();

    // Check if token is already used
    if (tokenData.used) {
      throw new Error('This verification link has already been used');
    }

    // Check if token is expired
    const now = admin.firestore.Timestamp.now();
    if (now.toMillis() > tokenData.expiresAt.toMillis()) {
      throw new Error('This verification link has expired');
    }

    // Get user by email and mark email as verified
    const userRecord = await admin.auth().getUserByEmail(tokenData.email);
    await admin.auth().updateUser(userRecord.uid, {
      emailVerified: true,
    });

    // Mark token as used
    await tokenDoc.ref.update({used: true});

    return {
      success: true,
      message: 'Email verified successfully',
    };
  } catch (error) {
    console.error('Error verifying email token:', error);
    throw new Error(error.message || 'Failed to verify email');
  }
});

/**
 * HTTP endpoint: Verify email token (called from web page)
 */
exports.verifyEmailTokenHttp = onRequest({cors: true}, async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json({error: 'Method not allowed'});
    return;
  }

  const {token} = req.body;
  if (!token) {
    res.status(400).json({error: 'Token is required'});
    return;
  }

  try {
    const tokenDoc = await admin.firestore()
      .collection('emailVerificationTokens')
      .doc(token)
      .get();

    if (!tokenDoc.exists) {
      res.status(400).json({error: 'Invalid or expired verification link'});
      return;
    }

    const tokenData = tokenDoc.data();

    if (tokenData.used) {
      res.status(400).json({error: 'This verification link has already been used. Your email is already verified!'});
      return;
    }

    const now = admin.firestore.Timestamp.now();
    if (now.toMillis() > tokenData.expiresAt.toMillis()) {
      res.status(400).json({error: 'This verification link has expired'});
      return;
    }

    const userRecord = await admin.auth().getUserByEmail(tokenData.email);
    await admin.auth().updateUser(userRecord.uid, {emailVerified: true});
    await tokenDoc.ref.update({used: true});

    res.json({success: true, message: 'Email verified successfully'});
  } catch (error) {
    console.error('Error verifying email token:', error);
    res.status(500).json({error: error.message || 'Failed to verify email'});
  }
});

/**
 * HTTP endpoint: Reset password (called from web page)
 */
exports.resetPasswordHttp = onRequest({cors: true}, async (req, res) => {
  if (req.method !== 'POST') {
    res.status(405).json({error: 'Method not allowed'});
    return;
  }

  const {token, newPassword} = req.body;
  if (!token || !newPassword) {
    res.status(400).json({error: 'Token and new password are required'});
    return;
  }

  if (newPassword.length < 6) {
    res.status(400).json({error: 'Password must be at least 6 characters'});
    return;
  }

  try {
    const tokenDoc = await admin.firestore()
      .collection('passwordResetTokens')
      .doc(token)
      .get();

    if (!tokenDoc.exists) {
      res.status(400).json({error: 'Invalid or expired reset link'});
      return;
    }

    const tokenData = tokenDoc.data();

    if (tokenData.used) {
      res.status(400).json({error: 'This reset link has already been used'});
      return;
    }

    const now = admin.firestore.Timestamp.now();
    if (now.toMillis() > tokenData.expiresAt.toMillis()) {
      res.status(400).json({error: 'This reset link has expired'});
      return;
    }

    const userRecord = await admin.auth().getUserByEmail(tokenData.email);
    await admin.auth().updateUser(userRecord.uid, {password: newPassword});
    await tokenDoc.ref.update({used: true});

    res.json({success: true, message: 'Password updated successfully'});
  } catch (error) {
    console.error('Error resetting password:', error);
    res.status(500).json({error: error.message || 'Failed to reset password'});
  }
});

/**
 * Build HTML for verification email
 */
function buildVerificationEmailHtml(userName, verificationLink) {
  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Verify your email</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f5f5;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 40px 0;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
          <tr>
            <td style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px 30px; text-align: center;">
              <h1 style="margin: 0; color: #ffffff; font-size: 28px; font-weight: 600;">Exam Ace</h1>
            </td>
          </tr>
          <tr>
            <td style="padding: 40px 30px;">
              <h2 style="margin: 0 0 20px 0; color: #333333; font-size: 24px; font-weight: 600;">Welcome, ${userName}!</h2>
              <p style="margin: 0 0 20px 0; color: #666666; font-size: 16px; line-height: 1.6;">
                Thanks for signing up for Exam Ace. To get started, please verify your email address by clicking the button below.
              </p>
              <table width="100%" cellpadding="0" cellspacing="0" style="margin: 30px 0;">
                <tr>
                  <td align="center">
                    <a href="${verificationLink}" style="display: inline-block; padding: 16px 40px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #ffffff; text-decoration: none; border-radius: 8px; font-size: 16px; font-weight: 600; box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);">
                      Verify Email Address
                    </a>
                  </td>
                </tr>
              </table>
              <p style="margin: 20px 0 0 0; color: #999999; font-size: 14px; line-height: 1.6;">
                If the button doesn't work, copy and paste this link into your browser:<br>
                <a href="${verificationLink}" style="color: #667eea; word-break: break-all;">${verificationLink}</a>
              </p>
              <p style="margin: 30px 0 0 0; color: #999999; font-size: 14px; line-height: 1.6;">
                If you didn't create an account with Exam Ace, you can safely ignore this email.
              </p>
            </td>
          </tr>
          <tr>
            <td style="background-color: #f9f9f9; padding: 30px; text-align: center; border-top: 1px solid #eeeeee;">
              <p style="margin: 0; color: #999999; font-size: 14px;">
                © ${new Date().getFullYear()} Exam Ace. All rights reserved.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
`;
}

/**
 * Build HTML for password reset email
 */
function buildPasswordResetEmailHtml(userName, resetLink) {
  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Reset your password</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; background-color: #f5f5f5;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f5f5f5; padding: 40px 0;">
    <tr>
      <td align="center">
        <table width="600" cellpadding="0" cellspacing="0" style="background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">
          <tr>
            <td style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px 30px; text-align: center;">
              <h1 style="margin: 0; color: #ffffff; font-size: 28px; font-weight: 600;">Exam Ace</h1>
            </td>
          </tr>
          <tr>
            <td style="padding: 40px 30px;">
              <h2 style="margin: 0 0 20px 0; color: #333333; font-size: 24px; font-weight: 600;">Reset your password</h2>
              <p style="margin: 0 0 20px 0; color: #666666; font-size: 16px; line-height: 1.6;">
                Hi ${userName},
              </p>
              <p style="margin: 0 0 20px 0; color: #666666; font-size: 16px; line-height: 1.6;">
                We received a request to reset your password. Click the button below to create a new password.
              </p>
              <table width="100%" cellpadding="0" cellspacing="0" style="margin: 30px 0;">
                <tr>
                  <td align="center">
                    <a href="${resetLink}" style="display: inline-block; padding: 16px 40px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: #ffffff; text-decoration: none; border-radius: 8px; font-size: 16px; font-weight: 600; box-shadow: 0 4px 12px rgba(102, 126, 234, 0.4);">
                      Reset Password
                    </a>
                  </td>
                </tr>
              </table>
              <p style="margin: 20px 0 0 0; color: #999999; font-size: 14px; line-height: 1.6;">
                If the button doesn't work, copy and paste this link into your browser:<br>
                <a href="${resetLink}" style="color: #667eea; word-break: break-all;">${resetLink}</a>
              </p>
              <p style="margin: 30px 0 0 0; color: #999999; font-size: 14px; line-height: 1.6;">
                If you didn't request a password reset, you can safely ignore this email. Your password will remain unchanged.
              </p>
              <p style="margin: 20px 0 0 0; color: #999999; font-size: 14px; line-height: 1.6;">
                This link will expire in 1 hour for security reasons.
              </p>
            </td>
          </tr>
          <tr>
            <td style="background-color: #f9f9f9; padding: 30px; text-align: center; border-top: 1px solid #eeeeee;">
              <p style="margin: 0; color: #999999; font-size: 14px;">
                © ${new Date().getFullYear()} Exam Ace. All rights reserved.
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
`;
}
