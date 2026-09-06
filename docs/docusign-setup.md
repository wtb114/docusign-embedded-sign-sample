# Setting up a DocuSign developer account

*English | [日本語](docusign-setup.ja.md)*

Only needed to run against the real API. Mock mode (`DOCUSIGN_MOCK=true`)
requires none of this.

## 1. Create a developer account

Sign up at https://developers.docusign.com/. You get a sandbox environment on
`demo.docusign.net`.

## 2. Create an Integration Key

Go to **Settings → Apps and Keys** and choose *Add App and Integration Key*.

That screen gives you three of the four values you need:

| Shown as | Environment variable |
|---|---|
| Integration Key | `DOCUSIGN_INTEGRATION_KEY` |
| API Account ID | `DOCUSIGN_ACCOUNT_ID` |
| User ID (under My Account Information) | `DOCUSIGN_USER_ID` |

## 3. Generate an RSA key pair

Press **Generate RSA** on the same screen. The private key is displayed once and
**never again** — copy it before closing the dialog.

It contains newlines, so encode it to a single line before putting it in `.env`:

```bash
base64 -w0 private.key
```

Use the output as `DOCUSIGN_PRIVATE_KEY_BASE64`.

## 4. Register a redirect URI

Add the consent callback under **Redirect URIs** on the same screen. For local
use this is enough:

```
http://localhost:3000/
```

## 5. Grant impersonation consent

JWT Grant means the application acts *as* a specific user, so **that user has to
approve it once in a browser**. Skip this and token requests fail with
`consent_required`.

Generate the consent URL:

```bash
docker compose run --rm web bin/rails runner 'puts Docusign::JwtClient.consent_url(redirect_uri: "http://localhost:3000/")'
```

Open it, sign in, and approve. From then on the server can mint tokens on its own.

## 6. Fill in .env

```dotenv
DOCUSIGN_MOCK=false
DOCUSIGN_INTEGRATION_KEY=...
DOCUSIGN_ACCOUNT_ID=...
DOCUSIGN_USER_ID=...
DOCUSIGN_PRIVATE_KEY_BASE64=...
```

`DOCUSIGN_OAUTH_BASE_URL` and `DOCUSIGN_API_HOST` can stay at their defaults
(`account-d.docusign.com` / `https://demo.docusign.net`) for a developer account.
Production accounts use `account.docusign.com` and `https://www.docusign.net`.

Compose reads `.env` at container creation, so recreate rather than restart:

```bash
docker compose up -d --force-recreate
```

## Common failures

**`consent_required`**
Step 5 has not been completed. Open the consent URL again.

**`USER_AUTHENTICATION_FAILED`**
`DOCUSIGN_USER_ID` is probably wrong. It is the GUID-shaped User ID (API
Username), not the account's email address.

**"This link is no longer valid" on the signing screen**
RecipientView URLs expire within minutes. Redirect to them immediately rather
than storing and reusing them.

**The envelope never reaches `completed`**
Usually means the signer has no tabs attached. This sample avoids that by
attaching one placeholder text tab; see
[architecture.md](architecture.md#a-placeholder-tab-is-required).
