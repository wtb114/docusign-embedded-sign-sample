# DocuSign 開発者アカウントのセットアップ

*[English](docusign-setup.md) | 日本語*

実際の DocuSign につなぐ場合の手順。無料の開発者アカウントで動作する。
モックモード（`DOCUSIGN_MOCK=true`）で動かすだけなら、この作業は不要。

## 1. 開発者アカウントを作る

https://developers.docusign.com/ から作成する。
サンドボックス環境（`demo.docusign.net`）が割り当てられる。

## 2. Integration Key を発行する

管理画面の **Settings → Apps and Keys** で「Add App and Integration Key」。

この画面で以下の3つが手に入る。

| 画面上の名前 | 環境変数 |
|---|---|
| Integration Key | `DOCUSIGN_INTEGRATION_KEY` |
| API Account ID | `DOCUSIGN_ACCOUNT_ID` |
| User ID（My Account Information 内） | `DOCUSIGN_USER_ID` |

## 3. RSA 鍵ペアを作る

同じ画面の「Generate RSA」を押すと秘密鍵が表示される。
**この画面を閉じると二度と表示されない**ので、必ず控える。

秘密鍵は改行を含むため、環境変数に入れる前に Base64 で1行にする。

```bash
base64 -w0 private.key
```

出力を `DOCUSIGN_PRIVATE_KEY_BASE64` に設定する。

## 4. Redirect URI を登録する

同じ画面の「Redirect URIs」に、次の手順で使う同意用の戻り先を追加する。
ローカルで確認するだけなら以下でよい。

```
http://localhost:3000/
```

## 5. impersonation の同意を与える

JWT Grant は「アプリが特定ユーザーになりすまして API を叩く」方式なので、
**対象ユーザーが一度だけブラウザで同意する**必要がある。
これをやらないと、トークン取得時に `consent_required` で失敗する。

同意 URL は次で生成できる。

```bash
docker compose run --rm web bin/rails runner \
  'puts Docusign::JwtClient.consent_url(redirect_uri: "http://localhost:3000/")'
```

出力された URL をブラウザで開き、ログインして許可する。
一度許可すれば、以降はサーバー単独でトークンを取得できる。

## 6. .env を設定する

```dotenv
DOCUSIGN_MOCK=false
DOCUSIGN_INTEGRATION_KEY=...
DOCUSIGN_ACCOUNT_ID=...
DOCUSIGN_USER_ID=...
DOCUSIGN_PRIVATE_KEY_BASE64=...
```

`DOCUSIGN_OAUTH_BASE_URL` と `DOCUSIGN_API_HOST` は、開発者アカウントなら
既定値（`account-d.docusign.com` / `https://demo.docusign.net`）のままでよい。
本番アカウントでは `account.docusign.com` / `https://www.docusign.net` に変える。

Compose は `.env` をコンテナ作成時に読むので、**再起動ではなく作り直し**が必要。

```bash
docker compose up -d --force-recreate
```

## つまずきやすい点

**`consent_required` が返る**
手順5の同意が済んでいない。同意 URL を開き直す。

**`USER_AUTHENTICATION_FAILED` が返る**
`DOCUSIGN_USER_ID` が違う可能性が高い。メールアドレスではなく、
GUID 形式の User ID（API Username）を指定する。

**署名画面URLを開くと「このリンクは無効です」**
RecipientView の URL は発行から数分で失効する。
リダイレクトを挟まず、発行したらすぐ遷移させること。

**Envelope が completed にならない**
署名者にタブが1つも紐づいていない可能性がある。
本サンプルはダミーの Text タブを1つ置いて回避している。
