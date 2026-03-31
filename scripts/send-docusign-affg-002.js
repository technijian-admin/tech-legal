const fs = require("fs");
const path = require("path");
const https = require("https");
const crypto = require("crypto");

// --- Configuration ---
const DOCUMENT_PATH = path.join(__dirname, "../clients/AFFG/SOW-AFFG-002-WirelessAP.docx");
const CLIENT_ID = "97d42eae-c23f-4a5b-a212-c0ef2384d231";
const USER_ID = "9a6b1aeb-88c5-4405-a0d2-b75c52a8cb63";
const ACCOUNT_ID = "fe3baf59-68ed-48a9-9ed7-5185f111c2a4";
const BASE_URL = "na1.docusign.net";

const RSA_KEY = `-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAnlgyBeI3B2vQty5E1mtXEQhnOk0gew0QYJk9PfuZAgkuTERb
KmtwU9DbO40oQKYLWawVWNDuin3i2L/AH8N/MUOCjDutEQ+CETEq47B4eRpB63xA
1pakv01jaVmVUp0cPY+9F2ndyBJPfvCCIAK308xLwnzZFIX35WlLNDd0uh1UyjDs
n3IY4aE5OszzxZyuNSfFXczVs4HAtPeehoTXKNss6DHcjxS2BIXp1nlzfND41I/Z
x870dUTY5mee7VQw5mUa60KD1m9JO9OW6Yisza38OD/bXiKVC2yS8w2bwbPweYqQ
r3aq5CM+8V9THYuahzhoqBVV6ds4yCzxV5obDQIDAQABAoIBABxrE78+lEW+sdzO
bwhUh3HFIlGyWev7sj7EAdvH9fQJlceWVQ5N7gD88PvFH75KjqrvWX1xMf6lDTt9
XovU2FUNGrb0VuFC+UMAogPvPg/uCHqs+C4LJ1I2H2te6o/DJrhdvcAf/e/UaXQM
0i3QjxFyDv6+zW8DhDQmK5sZgNeN9zUcXgiWb5H3LQzbSTLr3KhgvNpuBKOxGCpK
acNIVwO9bPhdnfY4ojKt9h2+/O+7/kES22Kqz7GlrssGqOT2WHJhnZGnx4EFymGu
Z0al6l47xP6oq5ZUchPGBlGybENkyj225Rger7TuSBQ9/cNh9TN96hyPJoN6d8W2
obfbEnkCgYEA5QRpm0D9fULs3Oy+jYlw0qFaKuXbgvKfxyI+4oxhQH5wXbv2Tne1
lv5vREWY+MQktcx+Zoy7/A+naxJ2LvLKQXLiaT6Nfa87dCO3o/7jRhOT5TQ7R5XZ
JNwhlN2AU9v6aczPbyVt9AZbsPhtR/Kkrkp/3mQ8BD9m6cExpgVGpPMCgYEAsQAp
XbXwy6sYJxxLS/A7XRLshsR+NOXuu3gcuLgO58KnYzkPq28deAOakaKzPKHBgTZy
bMx1xouLDL2UohcGI6vhapsim3y19OHw1VY58nR+ku+yV/5v/zg24S+yf/fPbftz
uWSwqClZDa2X77a5/LQZclAvF+NIfYNs1TbMP/8CgYEAgq3l5OVMv/E0X0vn37OR
YV8YqGnIvAveCC8OWw9nXvnG/HWIsnW0dJhyvS5Jf4nMuMAbUED183qrOXmrXlbD
+lynvQ4ohpM7BaZr33ROE2qQdbU8LjjfUx0ZPGy4ESHw3fY0V2OwPhJyt6TKFsfq
GFoCZNAlPvc+rhvDTMyt5ukCgYAYIPOCqNjIiuxh+INzOK5/A6Nmw8aIo4el2rvf
moe9pFV5O0AdmKolwCgEDm/spghg+vEiT8UGaeNsuzNV3Vmi5z11cOyI0blkRqC0
FGsV2DehBDgFstPFsP4aOIxW0YtfbNXbwhQq+GgBa1a5AOndvxdw8+lXkk5BffcK
Icw6NQKBgQDgbeMp7iMqoHFIFR0zPSPHIvDi5fELtBBGCU/5SrrL6jz6G2a2q8Tm
ljWRdlgCvBfcex51yotpZ+fRbYzokZR/xOaYXXiLpi1dXmdfOxiLruy70FQM8S0v
xjYZZnp/OWKJZ/cczNHQ2B7iUEsGBpBoZy8joN8ZatVjLcuy+DYDEw==
-----END RSA PRIVATE KEY-----`;

// --- Helper: base64url encode ---
function b64url(data) {
  const b64 = (typeof data === "string")
    ? Buffer.from(data).toString("base64")
    : data.toString("base64");
  return b64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

// --- Helper: HTTPS request ---
function httpsRequest(options, body) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => data += chunk);
      res.on("end", () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          resolve(JSON.parse(data));
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });
    req.on("error", reject);
    if (body) req.write(body);
    req.end();
  });
}

// --- Create JWT ---
function createJWT() {
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const now = Math.floor(Date.now() / 1000);
  const payload = b64url(JSON.stringify({
    iss: CLIENT_ID,
    sub: USER_ID,
    aud: "account.docusign.com",
    iat: now,
    exp: now + 3600,
    scope: "signature impersonation"
  }));

  const dataToSign = `${header}.${payload}`;
  const sign = crypto.createSign("RSA-SHA256");
  sign.update(dataToSign);
  const signature = b64url(sign.sign(RSA_KEY));
  return `${dataToSign}.${signature}`;
}

async function main() {
  // Step 1: Authenticate
  console.log("Authenticating with DocuSign (JWT Grant)...");
  const jwt = createJWT();
  const tokenBody = `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`;

  const tokenResponse = await httpsRequest({
    hostname: "account.docusign.com",
    path: "/oauth/token",
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      "Content-Length": Buffer.byteLength(tokenBody)
    }
  }, tokenBody);

  const accessToken = tokenResponse.access_token;
  console.log("Authentication successful.");

  // Step 2: Read document
  console.log("Reading document...");
  const fileName = path.basename(DOCUMENT_PATH);
  const fileBytes = fs.readFileSync(DOCUMENT_PATH);
  const base64File = fileBytes.toString("base64");
  console.log(`Document: ${fileName} (${fileBytes.length} bytes)`);

  // Step 3: Create envelope with parallel signing (both routingOrder = 1)
  console.log("Creating DocuSign envelope (parallel signing)...");

  const envelope = {
    emailSubject: "Technijian - SOW-AFFG-002 Wireless Access Point - Signature Required",
    emailBlurb: "Please review and sign the attached Statement of Work for Wireless Access Point Deployment from Technijian, Inc. If you have any questions, please contact Ravi Jain at rjain@technijian.com.",
    status: "sent",
    documents: [{
      documentBase64: base64File,
      name: fileName,
      fileExtension: "docx",
      documentId: "1"
    }],
    recipients: {
      signers: [
        {
          email: "iris.liu@americanfundstars.com",
          name: "Iris Liu",
          recipientId: "1",
          routingOrder: "1",
          tabs: {
            signHereTabs: [{
              documentId: "1",
              pageNumber: "0",
              recipientId: "1",
              anchorString: "AMERICAN FUNDSTARS",
              anchorXOffset: "0",
              anchorYOffset: "40",
              anchorUnits: "pixels",
              anchorCaseSensitive: "false"
            }]
          }
        },
        {
          email: "rjain@technijian.com",
          name: "Ravi Jain",
          recipientId: "2",
          routingOrder: "1",
          tabs: {
            signHereTabs: [{
              documentId: "1",
              pageNumber: "0",
              recipientId: "2",
              anchorString: "TECHNIJIAN, INC.",
              anchorXOffset: "0",
              anchorYOffset: "40",
              anchorUnits: "pixels",
              anchorCaseSensitive: "false"
            }]
          }
        }
      ]
    }
  };

  const envelopeBody = JSON.stringify(envelope);

  const response = await httpsRequest({
    hostname: BASE_URL,
    path: `/restapi/v2.1/accounts/${ACCOUNT_ID}/envelopes`,
    method: "POST",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "application/json",
      "Content-Length": Buffer.byteLength(envelopeBody)
    }
  }, envelopeBody);

  console.log("\n========================================");
  console.log(" DOCUSIGN ENVELOPE SENT SUCCESSFULLY");
  console.log("========================================");
  console.log(`Envelope ID:  ${response.envelopeId}`);
  console.log(`Status:       ${response.status}`);
  console.log(`Document:     ${fileName}`);
  console.log(`Signer 1:     Iris Liu <iris.liu@americanfundstars.com> (parallel)`);
  console.log(`Signer 2:     Ravi Jain <rjain@technijian.com> (parallel)`);
  console.log("========================================\n");
}

main().catch(err => {
  console.error("Error:", err.message);
  process.exit(1);
});
