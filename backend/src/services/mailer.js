// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

const nodemailer = require('nodemailer');

const PORT = Number(process.env.SMTP_PORT) || 465;

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: PORT,
  secure: PORT === 465, // 465 = SSL, 587 = STARTTLS
  auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
});

const FROM = process.env.SMTP_FROM || process.env.SMTP_USER;

// Tiny EN/FR picker. English is the default/fallback.
const t = (lang, en, fr) => (lang === 'fr' ? fr : en);

/// Wraps content in a TeamUp-branded HTML email (indigo identity, hollow hexagon).
function brandedHtml({ title, intro, note, lang = 'en' }) {
  const defaultNote = t(
    lang,
    "If you didn't initiate this action, secure your account right away.",
    "Si tu n'es pas à l'origine de cette action, sécurise ton compte sans tarder."
  );
  const footer = t(lang, '&copy; 2026 TeamUp &middot; Student project',
    '&copy; 2026 TeamUp &middot; Projet &eacute;tudiant');
  return `<!doctype html>
<html lang="${lang}"><body style="margin:0;background:#f8fafc;font-family:'Segoe UI',Arial,sans-serif;">
  <div style="max-width:480px;margin:0 auto;padding:24px;">
    <div style="text-align:center;padding:4px 0 18px;font-size:22px;font-weight:700;color:#0f172a;">
      <span style="color:#6366F1;">&#x2B21;</span> TeamUp
    </div>
    <div style="background:#ffffff;border:1px solid #e2e8f0;border-radius:16px;padding:24px;">
      <h1 style="margin:0 0 12px;font-size:18px;color:#0f172a;">${title}</h1>
      <p style="margin:0 0 14px;font-size:14px;color:#475569;line-height:1.5;">${intro}</p>
      <div style="margin-top:18px;padding-top:14px;border-top:1px solid #f1f5f9;font-size:12px;color:#94a3b8;line-height:1.5;">
        ${note || defaultNote}
      </div>
    </div>
    <p style="text-align:center;font-size:11px;color:#94a3b8;margin-top:16px;">${footer}</p>
  </div>
</body></html>`;
}

/// Sends via the Brevo transactional HTTP API (port 443) — used in production
/// because Render's free tier BLOCKS outbound SMTP. Falls through to SMTP when
/// no Brevo key is set (local dev).
async function sendViaBrevo({ to, subject, html, attachments }) {
  const sender = process.env.BREVO_SENDER || FROM || process.env.SMTP_USER;
  const senderName = process.env.BREVO_SENDER_NAME || 'TeamUp · Comptes & sécurité';
  const body = {
    sender: { email: sender, name: senderName },
    to: [{ email: to }],
    subject,
    htmlContent: html,
  };
  if (attachments && attachments.length) {
    body.attachment = attachments.map((a) => ({
      name: a.filename,
      content: Buffer.from(a.content).toString('base64'),
    }));
  }
  const r = await fetch('https://api.brevo.com/v3/smtp/email', {
    method: 'POST',
    headers: {
      'api-key': process.env.BREVO_API_KEY,
      'Content-Type': 'application/json',
      accept: 'application/json',
    },
    body: JSON.stringify(body),
  });
  if (!r.ok) {
    const txt = await r.text().catch(() => '');
    throw new Error(`Brevo ${r.status}: ${txt}`);
  }
  return { sent: true };
}

async function sendMail({ to, subject, html, attachments }) {
  // Production: Brevo HTTP (SMTP is blocked on Render free).
  if (process.env.BREVO_API_KEY) {
    return sendViaBrevo({ to, subject, html, attachments });
  }
  // Local/dev fallback: classic SMTP.
  if (!process.env.SMTP_USER || !process.env.SMTP_PASS) {
    console.warn('[mailer] no BREVO_API_KEY and SMTP not configured — skipping email to', to);
    return { skipped: true };
  }
  return transporter.sendMail({ from: FROM, to, subject, html, attachments });
}

// Escapes user-supplied text before dropping it into HTML emails.
function esc(s) {
  return String(s ?? '')
    .replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

// A prominent monospace code block reused by the code-bearing e-mails.
function codeBlockHtml(code) {
  return `
    <div style="margin:18px 0;text-align:center;">
      <span style="display:inline-block;font-family:'Consolas','Courier New',monospace;
        font-size:30px;font-weight:700;letter-spacing:6px;color:#4F46E5;
        background:#EEF2FF;border:1px solid #C7D2FE;border-radius:12px;padding:14px 22px;">
        ${code}
      </span>
    </div>`;
}

// A highlighted value box (used for the new e-mail address).
const valueBox = (v) =>
  `<div style="margin:12px 0;padding:10px 14px;background:#F8FAFC;border:1px solid #E2E8F0;border-radius:10px;font-weight:600;color:#0f172a;">${v}</div>`;

const muted = (s) => `<span style="font-size:13px;color:#94a3b8;">${s}</span>`;

function dateTime(lang) {
  return new Date().toLocaleString(lang === 'fr' ? 'fr-FR' : 'en-GB', {
    dateStyle: 'long',
    timeStyle: 'short',
    timeZone: 'Europe/Paris',
  });
}

// ── Sign-up verification code ───────────────────────────────────────────────

async function sendVerificationCode({ to, code, name, lang = 'en' }) {
  return sendMail({
    to,
    subject: t(lang, `Your TeamUp verification code: ${code}`,
      `Ton code de vérification TeamUp : ${code}`),
    html: brandedHtml({
      lang,
      title: t(lang, 'Verify your e-mail', 'Vérifie ton adresse e-mail'),
      intro:
        t(lang,
          'Welcome! Enter this code in the app to activate your TeamUp account:',
          "Bienvenue ! Saisis ce code dans l'application pour activer ton compte TeamUp :") +
        codeBlockHtml(code) +
        muted(t(lang, 'This code expires in 30 minutes.', 'Ce code expire dans 30 minutes.')),
      note: t(lang,
        "If you didn't sign up, just ignore this e-mail.",
        "Si tu n'es pas à l'origine de cette inscription, ignore simplement cet e-mail."),
    }),
  });
}

// ── Code requests (change applied ONLY after the code is confirmed) ──────────

/// Sent to the user's CURRENT (old) address to validate switching to [newEmail].
async function sendEmailChangeRequest({ to, newEmail, code, name, lang = 'en' }) {
  return sendMail({
    to,
    subject: t(lang, `Confirm your e-mail change: ${code}`,
      `Confirme le changement d'adresse e-mail : ${code}`),
    html: brandedHtml({
      lang,
      title: t(lang, 'E-mail change request', "Demande de changement d'adresse e-mail"),
      intro:
        t(lang, 'Hello,<br><br>', 'Bonjour,<br><br>') +
        t(lang,
          `A request was made on <b>${dateTime(lang)}</b> to change your TeamUp e-mail address to:`,
          `Une demande a été faite le <b>${dateTime(lang)}</b> pour remplacer l'adresse e-mail de ton compte TeamUp par&nbsp;:`) +
        valueBox(newEmail) +
        t(lang,
          'For security, this change must be <b>validated from your current address</b> (this one). Enter this code in the app:',
          "Par sécurité, ce changement doit être <b>validé depuis ton adresse actuelle</b> (celle-ci). Saisis ce code dans l'application&nbsp;:") +
        codeBlockHtml(code) +
        muted(t(lang,
          'The code expires in 30 minutes. Until it is entered, your address <b>stays unchanged</b>.',
          "Le code expire dans 30 minutes. Tant qu'il n'est pas saisi, ton adresse <b>reste inchangée</b>.")),
      note: t(lang,
        "If you didn't request this, ignore this e-mail: no change will be made and your current address stays active.",
        "Si tu n'es pas à l'origine de cette demande, ignore cet e-mail : aucune modification ne sera faite et ton adresse actuelle reste active."),
    }),
  });
}

/// Sent to the user's address to validate a password change.
async function sendPasswordChangeRequest({ to, code, name, lang = 'en' }) {
  return sendMail({
    to,
    subject: t(lang, `Confirm your password change: ${code}`,
      `Confirme le changement de mot de passe : ${code}`),
    html: brandedHtml({
      lang,
      title: t(lang, 'Password change request', 'Demande de changement de mot de passe'),
      intro:
        t(lang, 'Hello,<br><br>', 'Bonjour,<br><br>') +
        t(lang,
          `A password change was requested on your TeamUp account on <b>${dateTime(lang)}</b>. To confirm it, enter this code in the app:`,
          `Une demande de changement de mot de passe a été faite sur ton compte TeamUp le <b>${dateTime(lang)}</b>. Pour la valider, saisis ce code dans l'application&nbsp;:`) +
        codeBlockHtml(code) +
        muted(t(lang,
          'The code expires in 30 minutes. Your current password <b>stays valid</b> until the change is confirmed.',
          "Le code expire dans 30 minutes. Ton mot de passe actuel <b>reste valable</b> tant que le changement n'est pas confirmé.")),
      note: t(lang,
        "If you didn't request this, ignore this e-mail and change your password as a precaution.",
        "Si tu n'es pas à l'origine de cette demande, ignore cet e-mail et change ton mot de passe par précaution."),
    }),
  });
}

// ── "Done" confirmations (sent AFTER the change is applied) ──────────────────

async function sendEmailChanged({ to, newEmail, lang = 'en' }) {
  return sendMail({
    to,
    subject: t(lang, 'Your TeamUp e-mail address was changed',
      'Ton adresse e-mail TeamUp a été modifiée'),
    html: brandedHtml({
      lang,
      title: t(lang, 'E-mail address changed', 'Adresse e-mail modifiée'),
      intro:
        t(lang,
          `On <b>${dateTime(lang)}</b>, your TeamUp e-mail address was changed to:`,
          `Le <b>${dateTime(lang)}</b>, l'adresse e-mail de ton compte TeamUp a été remplacée par&nbsp;:`) +
        valueBox(newEmail) +
        t(lang,
          'This (old) address will no longer receive your account notifications. All future messages will go to the new address.',
          "Cette adresse (l'ancienne) ne recevra plus les notifications de ton compte. Toutes les prochaines communications iront vers la nouvelle adresse."),
      note: t(lang,
        'Not you? Contact us immediately at teamup.team28@gmail.com to secure your account.',
        "Tu n'es pas à l'origine de ce changement&nbsp;? Contacte-nous immédiatement à teamup.team28@gmail.com pour sécuriser ton compte."),
    }),
  });
}

async function sendPasswordChanged({ to, lang = 'en' }) {
  return sendMail({
    to,
    subject: t(lang, 'Your TeamUp password was changed',
      'Ton mot de passe TeamUp a été modifié'),
    html: brandedHtml({
      lang,
      title: t(lang, 'Password changed', 'Mot de passe modifié'),
      intro:
        t(lang,
          `Your TeamUp password was successfully updated on <b>${dateTime(lang)}</b>.<br><br>You can now sign in with your new password.`,
          `Le mot de passe de ton compte TeamUp a été mis à jour avec succès le <b>${dateTime(lang)}</b>.<br><br>Tu peux désormais te connecter avec ton nouveau mot de passe.`),
      note: t(lang,
        'Not you? Reset your password and contact us at teamup.team28@gmail.com right away.',
        "Tu n'es pas à l'origine de ce changement&nbsp;? Réinitialise ton mot de passe et contacte-nous à teamup.team28@gmail.com sans tarder."),
    }),
  });
}

// ── Abuse report (sent to the TeamUp team inbox) ─────────────────────────────

/// Sent to the moderation inbox when a user reports another account.
async function sendAbuseReport({ reportedName, reportedId, reporterName, reporterEmail, reason, details }) {
  const to = process.env.REPORT_TO || process.env.SMTP_USER || 'teamup.team28@gmail.com';
  const rows = [
    ['Reported user', `${esc(reportedName)} (id ${esc(reportedId)})`],
    ['Reason', esc(reason)],
    ['Reported by', `${esc(reporterName)} (${esc(reporterEmail)})`],
    ['Date', dateTime('en')],
  ].map(([k, v]) =>
    `<tr><td style="padding:4px 12px 4px 0;color:#94a3b8;font-size:13px;white-space:nowrap;">${k}</td>
         <td style="padding:4px 0;color:#0f172a;font-size:13px;font-weight:600;">${v}</td></tr>`).join('');
  return sendMail({
    to,
    subject: `[TeamUp] Report: ${reportedName} (id ${reportedId})`,
    html: brandedHtml({
      lang: 'en',
      title: 'New account report',
      intro:
        '<table style="border-collapse:collapse;margin-bottom:14px;">' + rows + '</table>' +
        '<div style="font-size:13px;color:#475569;line-height:1.5;"><b>Details:</b><br>' +
        (esc(details).replace(/\n/g, '<br>') || muted('(none provided)')) + '</div>',
      note: 'Review this report in the admin tools and take action if warranted.',
    }),
  });
}

// ── GDPR data export (sent to the user with their data attached) ─────────────

/// Emails the user a copy of all their data as a JSON attachment.
async function sendDataExport({ to, name, json, counts = {}, lang = 'en' }) {
  const summary = Object.entries(counts)
    .map(([k, v]) => `<li style="margin:2px 0;">${esc(k)}: <b>${esc(v)}</b></li>`)
    .join('');
  return sendMail({
    to,
    subject: t(lang, 'Your TeamUp data export', 'Ton export de données TeamUp'),
    html: brandedHtml({
      lang,
      title: t(lang, 'Your data export', 'Ton export de données'),
      intro:
        t(lang, `Hello ${esc(name)},<br><br>`, `Bonjour ${esc(name)},<br><br>`) +
        t(lang,
          'As requested, here is a copy of the personal data we hold about you, attached as a JSON file. It includes:',
          'Comme demandé, voici une copie des données personnelles que nous détenons sur toi, jointe en fichier JSON. Elle comprend :') +
        `<ul style="font-size:13px;color:#475569;line-height:1.5;margin:12px 0;">${summary}</ul>`,
      note: t(lang,
        'You requested this export from the app. If this wasn’t you, change your password and contact teamup.team28@gmail.com.',
        "Tu as demandé cet export depuis l'application. Si ce n'est pas toi, change ton mot de passe et contacte teamup.team28@gmail.com."),
    }),
    attachments: [
      { filename: 'teamup-my-data.json', content: json, contentType: 'application/json' },
    ],
  });
}

module.exports = {
  sendMail,
  sendEmailChangeRequest,
  sendPasswordChangeRequest,
  sendEmailChanged,
  sendPasswordChanged,
  sendVerificationCode,
  sendAbuseReport,
  sendDataExport,
  brandedHtml,
};
