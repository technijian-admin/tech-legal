#!/usr/bin/env node
// DocuSign JWT Generator - called by send-docusign.ps1
// Usage: node docusign-jwt-helper.js <clientId> <userId> <rsaKeyPath>
// Outputs the signed JWT to stdout

const crypto = require('crypto');
const fs = require('fs');

const clientId = process.argv[2];
const userId = process.argv[3];
const rsaKeyPath = process.argv[4];

if (!clientId || !userId || !rsaKeyPath) {
  console.error('Usage: node docusign-jwt-helper.js <clientId> <userId> <rsaKeyPath>');
  process.exit(1);
}

const rsaKey = fs.readFileSync(rsaKeyPath, 'utf8');

// Base64url encode
function base64url(str) {
  return Buffer.from(str)
    .toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

function base64urlFromBuffer(buf) {
  return buf.toString('base64')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

// JWT Header
const header = base64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));

// JWT Payload
const now = Math.floor(Date.now() / 1000);
const payload = base64url(JSON.stringify({
  iss: clientId,
  sub: userId,
  aud: 'account.docusign.com',
  iat: now,
  exp: now + 3600,
  scope: 'signature impersonation'
}));

// Sign
const dataToSign = `${header}.${payload}`;
const sign = crypto.createSign('RSA-SHA256');
sign.update(dataToSign);
const signature = base64urlFromBuffer(sign.sign(rsaKey));

// Output JWT
process.stdout.write(`${dataToSign}.${signature}`);
