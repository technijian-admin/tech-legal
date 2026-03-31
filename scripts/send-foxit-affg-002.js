const fs = require("fs");
const path = require("path");
const https = require("https");
const querystring = require("querystring");

const DOCUMENT_PATH = path.join(__dirname, "../clients/AFFG/SOW-AFFG-002-WirelessAP.docx");
const BASE_HOST = "na1.foxitesign.foxit.com";
const CLIENT_ID = "c9a6bb6059dd4a0fadf02e70e8a52c52";
const CLIENT_SECRET = "af01e80b7e3448fe8a37d79c8ef1c852";

function httpsRequest(options, body) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => data += chunk);
      res.on("end", () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try { resolve(JSON.parse(data)); } catch { resolve(data); }
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    });
    req.setTimeout(90000, () => { req.destroy(new Error("Request timeout")); });
    req.on("error", reject);
    if (body) req.write(body);
    req.end();
  });
}

async function main() {
  // Step 1: Authenticate
  console.log("Authenticating with Foxit eSign...");
  const tokenBody = querystring.stringify({
    grant_type: "client_credentials",
    client_id: CLIENT_ID,
    client_secret: CLIENT_SECRET,
    scope: "read-write"
  });

  const tokenResponse = await httpsRequest({
    hostname: BASE_HOST,
    path: "/api/oauth2/access_token",
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

  // Step 3: Create envelope (parallel signing)
  console.log("Creating envelope (parallel signing)...");

  const envelope = {
    folderName: "SOW-AFFG-002-WirelessAP",
    inputType: "base64",
    base64FileString: [base64File],
    fileNames: [fileName],
    sendNow: true,
    createEmbeddedSigningSession: false,
    emailSubject: "Technijian - SOW-AFFG-002 Wireless Access Point - Signature Required",
    emailMessage: "Please review and sign the attached Statement of Work for Wireless Access Point Deployment from Technijian, Inc. If you have any questions, please contact Ravi Jain at rjain@technijian.com.",
    signInSequence: false,
    inPersonEnable: false,
    parties: [
      {
        firstName: "Iris",
        lastName: "Liu",
        emailId: "iris.liu@americanfundstars.com",
        permission: "FILL_FIELDS_AND_SIGN",
        sequence: 1,
        workflowSequence: 1
      },
      {
        firstName: "Ravi",
        lastName: "Jain",
        emailId: "rjain@technijian.com",
        permission: "FILL_FIELDS_AND_SIGN",
        sequence: 2,
        workflowSequence: 1
      }
    ],
    fields: [
      // Client signature block
      { type: "signature", x: 72, y: 50, width: 200, height: 30, pageNumber: -1, documentNumber: 1, party: 1, required: true },
      { type: "textfield", x: 72, y: 85, width: 200, height: 20, pageNumber: -1, documentNumber: 1, party: 1, name: "client_name", required: true },
      { type: "textfield", x: 72, y: 110, width: 200, height: 20, pageNumber: -1, documentNumber: 1, party: 1, name: "client_title", required: true },
      { type: "datefield", x: 72, y: 135, width: 120, height: 20, pageNumber: -1, documentNumber: 1, party: 1, name: "client_date", required: true },
      // Technijian signature block
      { type: "signature", x: 350, y: 50, width: 200, height: 30, pageNumber: -1, documentNumber: 1, party: 2, required: true },
      { type: "textfield", x: 350, y: 85, width: 200, height: 20, pageNumber: -1, documentNumber: 1, party: 2, name: "tech_name", value: "Ravi Jain", required: true },
      { type: "textfield", x: 350, y: 110, width: 200, height: 20, pageNumber: -1, documentNumber: 1, party: 2, name: "tech_title", value: "CEO", required: true },
      { type: "datefield", x: 350, y: 135, width: 120, height: 20, pageNumber: -1, documentNumber: 1, party: 2, name: "tech_date", required: true }
    ]
  };

  const envelopeBody = JSON.stringify(envelope);

  const response = await httpsRequest({
    hostname: BASE_HOST,
    path: "/api/folders/createfolder",
    method: "POST",
    headers: {
      "Authorization": `Bearer ${accessToken}`,
      "Content-Type": "application/json",
      "Content-Length": Buffer.byteLength(envelopeBody)
    }
  }, envelopeBody);

  console.log("\n========================================");
  console.log(" FOXIT ESIGN - ENVELOPE SENT (PARALLEL)");
  console.log("========================================");
  console.log(`Folder ID:    ${response.folderId}`);
  console.log(`Document:     ${fileName}`);
  console.log(`Signer 1:     Iris Liu <iris.liu@americanfundstars.com> (parallel)`);
  console.log(`Signer 2:     Ravi Jain <rjain@technijian.com> (parallel)`);
  console.log(`Status:       Both signers notified simultaneously`);
  console.log("========================================\n");
}

main().catch(err => {
  console.error("Error:", err.message);
  process.exit(1);
});
