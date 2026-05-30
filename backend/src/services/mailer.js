const nodemailer = require('nodemailer');

const PORT = Number(process.env.SMTP_PORT) || 465;

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: PORT,
  secure: PORT === 465, // 465 = SSL, 587 = STARTTLS
  auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
});

const FROM = process.env.SMTP_FROM || process.env.SMTP_USER;

/// Wraps content in a TeamUp-branded HTML email (indigo identity).
function brandedHtml({ title, intro, note }) {
  return `<!doctype html>
<html lang="fr"><body style="margin:0;background:#f8fafc;font-family:'Segoe UI',Arial,sans-serif;">
  <div style="max-width:480px;margin:0 auto;padding:24px;">
    <div style="text-align:center;padding:4px 0 18px;font-size:22px;font-weight:700;color:#0f172a;">
      <span style="color:#6366F1;">&#x2B21;</span> TeamUp
    </div>
    <div style="background:#ffffff;border:1px solid #e2e8f0;border-radius:16px;padding:24px;">
      <h1 style="margin:0 0 12px;font-size:18px;color:#0f172a;">${title}</h1>
      <p style="margin:0 0 14px;font-size:14px;color:#475569;line-height:1.5;">${intro}</p>
      <div style="margin-top:18px;padding-top:14px;border-top:1px solid #f1f5f9;font-size:12px;color:#94a3b8;line-height:1.5;">
        ${note || "Si tu n'es pas à l'origine de cette action, sécurise ton compte sans tarder."}
      </div>
    </div>
    <p style="text-align:center;font-size:11px;color:#94a3b8;margin-top:16px;">&copy; 2026 TeamUp &middot; Projet &eacute;tudiant</p>
  </div>
</body></html>`;
}

async function sendMail({ to, subject, html }) {
  if (!process.env.SMTP_USER || !process.env.SMTP_PASS) {
    console.warn('[mailer] SMTP not configured — skipping email to', to);
    return { skipped: true };
  }
  return transporter.sendMail({ from: FROM, to, subject, html });
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

function frenchDateTime() {
  return new Date().toLocaleString('fr-FR', {
    dateStyle: 'long',
    timeStyle: 'short',
    timeZone: 'Europe/Paris',
  });
}

// ── Code requests (change applied ONLY after the code is confirmed) ──────────

/// Sent to the user's CURRENT (old) address to validate switching to [newEmail].
async function sendEmailChangeRequest({ to, newEmail, code, name }) {
  return sendMail({
    to,
    subject: `Confirme le changement d'adresse e-mail : ${code}`,
    html: brandedHtml({
      title: "Demande de changement d'adresse e-mail",
      intro:
        `Bonjour,<br><br>` +
        `Une demande a été faite le <b>${frenchDateTime()}</b> pour remplacer l'adresse e-mail de ton compte TeamUp par&nbsp;:` +
        `<div style="margin:12px 0;padding:10px 14px;background:#F8FAFC;border:1px solid #E2E8F0;border-radius:10px;font-weight:600;color:#0f172a;">${newEmail}</div>` +
        `Par sécurité, ce changement doit être <b>validé depuis ton adresse actuelle</b> (celle-ci). Saisis ce code dans l'application&nbsp;:` +
        codeBlockHtml(code) +
        `<span style="font-size:13px;color:#94a3b8;">Le code expire dans 30&nbsp;minutes. Tant qu'il n'est pas saisi, ton adresse <b>reste inchangée</b>.</span>`,
      note: "Si tu n'es pas à l'origine de cette demande, ignore cet e-mail : aucune modification ne sera faite et ton adresse actuelle reste active.",
    }),
  });
}

/// Sent to the user's address to validate a password change.
async function sendPasswordChangeRequest({ to, code, name }) {
  return sendMail({
    to,
    subject: `Confirme le changement de mot de passe : ${code}`,
    html: brandedHtml({
      title: 'Demande de changement de mot de passe',
      intro:
        `Bonjour,<br><br>` +
        `Une demande de changement de mot de passe a été faite sur ton compte TeamUp le <b>${frenchDateTime()}</b>. Pour la valider, saisis ce code dans l'application&nbsp;:` +
        codeBlockHtml(code) +
        `<span style="font-size:13px;color:#94a3b8;">Le code expire dans 30&nbsp;minutes. Ton mot de passe actuel <b>reste valable</b> tant que le changement n'est pas confirmé.</span>`,
      note: "Si tu n'es pas à l'origine de cette demande, ignore cet e-mail et change ton mot de passe par précaution.",
    }),
  });
}

// ── "Done" confirmations (sent AFTER the change is applied) ──────────────────

async function sendEmailChanged({ to, newEmail }) {
  return sendMail({
    to,
    subject: 'Ton adresse e-mail TeamUp a été modifiée',
    html: brandedHtml({
      title: 'Adresse e-mail modifiée',
      intro:
        `Le <b>${frenchDateTime()}</b>, l'adresse e-mail de ton compte TeamUp a été remplacée par&nbsp;:` +
        `<div style="margin:12px 0;padding:10px 14px;background:#F8FAFC;border:1px solid #E2E8F0;border-radius:10px;font-weight:600;color:#0f172a;">${newEmail}</div>` +
        `Cette adresse (l'ancienne) ne recevra plus les notifications de ton compte. Toutes les prochaines communications iront vers la nouvelle adresse.`,
      note: "Tu n'es pas à l'origine de ce changement&nbsp;? Contacte-nous immédiatement à teamup.team28@gmail.com pour sécuriser ton compte.",
    }),
  });
}

async function sendPasswordChanged({ to }) {
  return sendMail({
    to,
    subject: 'Ton mot de passe TeamUp a été modifié',
    html: brandedHtml({
      title: 'Mot de passe modifié',
      intro:
        `Le mot de passe de ton compte TeamUp a été mis à jour avec succès le <b>${frenchDateTime()}</b>.<br><br>` +
        `Tu peux désormais te connecter avec ton nouveau mot de passe.`,
      note: "Tu n'es pas à l'origine de ce changement&nbsp;? Réinitialise ton mot de passe et contacte-nous à teamup.team28@gmail.com sans tarder.",
    }),
  });
}

/// Sends the e-mail verification code (format XXXX-XXXX) to a new sign-up.
async function sendVerificationCode({ to, code, name }) {
  const codeBlock = `
    <div style="margin:18px 0;text-align:center;">
      <span style="display:inline-block;font-family:'Consolas','Courier New',monospace;
        font-size:30px;font-weight:700;letter-spacing:6px;color:#4F46E5;
        background:#EEF2FF;border:1px solid #C7D2FE;border-radius:12px;padding:14px 22px;">
        ${code}
      </span>
    </div>`;
  return sendMail({
    to,
    subject: `Ton code de vérification TeamUp : ${code}`,
    html: brandedHtml({
      title: 'Vérifie ton adresse e-mail',
      intro:
        `Bienvenue ! Saisis ce code dans l'application pour activer ton compte TeamUp :` +
        codeBlock +
        `<span style="font-size:13px;color:#94a3b8;">Ce code expire dans 30&nbsp;minutes.</span>`,
      note: "Si tu n'es pas à l'origine de cette inscription, ignore simplement cet e-mail.",
    }),
  });
}

module.exports = {
  sendMail,
  sendEmailChangeRequest,
  sendPasswordChangeRequest,
  sendEmailChanged,
  sendPasswordChanged,
  sendVerificationCode,
  brandedHtml,
};
