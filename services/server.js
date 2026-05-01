// Mock OIDC server with autologin to a single user.
// Compatible with IdentityServer-style clients (/connect/*) and generic OIDC clients.
// NOT FOR PRODUCTION.

import express from 'express';
import cors from 'cors';
import crypto from 'crypto';
import { SignJWT, exportJWK, generateKeyPair } from 'jose';

// ---------- Config ----------
// ISSUER  = internal URL used by server-side relying parties (outline backend),
//           also signed into JWT `iss` claim.
// PUBLIC  = browser-facing URL (host:published-port) used in redirect endpoints.
// PORT    = derived from ISSUER URL so a single var sets where we listen.
const ISSUER        = process.env.ISSUER        || 'http://localhost:8080';
const PUBLIC        = process.env.PUBLIC_URL    || ISSUER;
const PORT          = parseInt(new URL(ISSUER).port || '8080', 10);
const CLIENT_ID     = process.env.CLIENT_ID     || 'mock-client';
const CLIENT_SECRET = process.env.CLIENT_SECRET || 'mock-secret';
const TOKEN_TTL     = parseInt(process.env.TOKEN_TTL || '3600', 10);
const CODE_TTL      = parseInt(process.env.CODE_TTL  || '60',   10);

const USER = {
  sub:                process.env.USER_SUB      || 'user-1',
  email:              process.env.USER_EMAIL    || 'mail@example.com',
  email_verified:     true,
  name:               process.env.USER_NAME     || 'Outline',
  preferred_username: process.env.USER_USERNAME || 'outline',
  given_name:         process.env.USER_GIVEN    || 'Outline',
  family_name:        process.env.USER_FAMILY   || 'Wiki',
  roles:              (process.env.USER_ROLES   || 'admin,user').split(','),
  picture:            `${PUBLIC}/avatar.png`,
};

// ---------- Keys ----------
const { publicKey, privateKey } = await generateKeyPair('RS256');
const jwk = { ...(await exportJWK(publicKey)), kid: 'mock-key-1', alg: 'RS256', use: 'sig' };

// ---------- In-memory stores ----------
const codes = new Map();
const tokens = new Map();
const refreshTokens = new Map();

// ---------- Helpers ----------
const now = () => Math.floor(Date.now() / 1000);

const signJwt = (payload, audience, ttl = TOKEN_TTL) =>
  new SignJWT(payload)
    .setProtectedHeader({ alg: 'RS256', kid: jwk.kid, typ: 'JWT' })
    .setIssuer(ISSUER)
    .setSubject(USER.sub)
    .setAudience(audience)
    .setIssuedAt(now())
    .setExpirationTime(now() + ttl)
    .setJti(crypto.randomBytes(16).toString('hex'))
    .sign(privateKey);

const extractClientCreds = (req) => {
  const auth = req.headers.authorization;
  if (auth?.startsWith('Basic ')) {
    const decoded = Buffer.from(auth.slice(6), 'base64').toString();
    const idx = decoded.indexOf(':');
    return {
      clientId: decodeURIComponent(decoded.slice(0, idx)),
      clientSecret: decodeURIComponent(decoded.slice(idx + 1)),
    };
  }
  return { clientId: req.body.client_id, clientSecret: req.body.client_secret };
};

const pkceMatches = (verifier, challenge, method) => {
  if (!verifier) return false;
  if (method === 'S256') return crypto.createHash('sha256').update(verifier).digest('base64url') === challenge;
  return verifier === challenge;
};

// ---------- App ----------
const app = express();
app.use(cors({ origin: true, credentials: true }));
app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use((req, _res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
  next();
});

// ---------- Discovery + JWKS ----------
app.get('/.well-known/openid-configuration', (_req, res) => res.json({
  issuer: ISSUER,
  authorization_endpoint: `${PUBLIC}/connect/authorize`,
  token_endpoint:         `${ISSUER}/connect/token`,
  userinfo_endpoint:      `${ISSUER}/connect/userinfo`,
  end_session_endpoint:   `${PUBLIC}/connect/endsession`,
  jwks_uri:               `${ISSUER}/.well-known/jwks`,
  response_types_supported: ['code'],
  response_modes_supported: ['query', 'fragment'],
  subject_types_supported:  ['public'],
  id_token_signing_alg_values_supported: ['RS256'],
  scopes_supported: ['openid', 'profile', 'email', 'offline_access'],
  token_endpoint_auth_methods_supported: ['client_secret_post', 'client_secret_basic', 'none'],
  claims_supported: ['sub', 'email', 'email_verified', 'name', 'preferred_username', 'given_name', 'family_name', 'roles'],
  code_challenge_methods_supported: ['S256', 'plain'],
  grant_types_supported: ['authorization_code', 'refresh_token'],
}));

app.get(['/.well-known/jwks', '/.well-known/openid-configuration/jwks', '/jwks'],
  (_req, res) => res.json({ keys: [jwk] }));

// ---------- /authorize: AUTOLOGIN ----------
app.get(['/connect/authorize', '/authorize'], (req, res) => {
  const { redirect_uri, state, nonce, scope, response_type,
          client_id, code_challenge, code_challenge_method } = req.query;
  const fail = (status, error, description) =>
    res.status(status).json({ error, error_description: description });

  if (response_type !== 'code') return fail(400, 'unsupported_response_type', 'response_type must be "code"');
  if (!client_id)               return fail(400, 'invalid_request', 'client_id is required');
  if (!redirect_uri)            return fail(400, 'invalid_request', 'redirect_uri is required');

  const code = crypto.randomBytes(32).toString('hex');
  codes.set(code, {
    client_id, redirect_uri, nonce,
    scope: scope || 'openid',
    code_challenge, code_challenge_method,
    expires_at: Date.now() + CODE_TTL * 1000,
  });

  const url = new URL(redirect_uri);
  url.searchParams.set('code', code);
  if (state) url.searchParams.set('state', state);

  console.log(`  -> autologin: redirect to ${url.toString()}`);
  res.redirect(url.toString());
});

// ---------- /token ----------
app.post(['/connect/token', '/token'], async (req, res) => {
  const { grant_type } = req.body;

  if (grant_type === 'authorization_code') {
    const { code, redirect_uri, code_verifier } = req.body;
    const { clientId, clientSecret } = extractClientCreds(req);

    const ctx = codes.get(code);
    codes.delete(code);
    if (!ctx)                              return res.status(400).json({ error: 'invalid_grant', error_description: 'unknown code' });
    if (ctx.expires_at < Date.now())       return res.status(400).json({ error: 'invalid_grant', error_description: 'code expired' });
    if (ctx.redirect_uri !== redirect_uri) return res.status(400).json({ error: 'invalid_grant', error_description: 'redirect_uri mismatch' });

    if (ctx.code_challenge) {
      if (!pkceMatches(code_verifier, ctx.code_challenge, ctx.code_challenge_method))
        return res.status(400).json({ error: 'invalid_grant', error_description: 'PKCE verification failed' });
    } else if (clientId !== CLIENT_ID || clientSecret !== CLIENT_SECRET) {
      return res.status(401).json({ error: 'invalid_client' });
    }

    const aud = clientId || CLIENT_ID;
    const id_token     = await signJwt({ ...USER, nonce: ctx.nonce, auth_time: now() }, aud);
    const access_token = await signJwt({ scope: ctx.scope, client_id: aud, ...USER }, aud);
    tokens.set(access_token, USER);

    const response = { access_token, id_token, token_type: 'Bearer', expires_in: TOKEN_TTL, scope: ctx.scope };
    if (ctx.scope.split(' ').includes('offline_access')) {
      const refresh_token = crypto.randomBytes(32).toString('hex');
      refreshTokens.set(refresh_token, { client_id: aud, scope: ctx.scope });
      response.refresh_token = refresh_token;
    }
    return res.json(response);
  }

  if (grant_type === 'refresh_token') {
    const { refresh_token } = req.body;
    const ctx = refreshTokens.get(refresh_token);
    if (!ctx) return res.status(400).json({ error: 'invalid_grant' });

    const id_token     = await signJwt({ ...USER, auth_time: now() }, ctx.client_id);
    const access_token = await signJwt({ scope: ctx.scope, client_id: ctx.client_id, ...USER }, ctx.client_id);
    tokens.set(access_token, USER);

    return res.json({
      access_token, id_token, refresh_token,
      token_type: 'Bearer', expires_in: TOKEN_TTL, scope: ctx.scope,
    });
  }

  res.status(400).json({ error: 'unsupported_grant_type' });
});

// ---------- /userinfo ----------
app.all(['/connect/userinfo', '/userinfo'], (req, res) => {
  const auth = req.headers.authorization;
  const user = auth?.startsWith('Bearer ') ? tokens.get(auth.slice(7)) : null;
  if (!user) return res.status(401).json({ error: 'invalid_token' });
  res.json(user);
});

// ---------- /endsession ----------
app.get(['/connect/endsession', '/logout'], (req, res) => {
  const { post_logout_redirect_uri, state } = req.query;
  if (post_logout_redirect_uri) {
    const url = new URL(post_logout_redirect_uri);
    if (state) url.searchParams.set('state', state);
    return res.redirect(url.toString());
  }
  res.type('html').send('<h1>Logged out</h1>');
});

// ---------- Index + health + 404 ----------
app.get('/', (_req, res) => res.type('html').send(`<h1>OIDC Mock Server</h1>
<p>Autologin as <strong>${USER.email}</strong> (sub: <code>${USER.sub}</code>)</p>
<ul>
  <li><a href="/.well-known/openid-configuration">/.well-known/openid-configuration</a></li>
  <li><a href="/.well-known/jwks">/.well-known/jwks</a></li>
  <li><a href="/connect/authorize?response_type=code&client_id=${CLIENT_ID}&redirect_uri=http://localhost:3000/callback&scope=openid+profile+email&state=test">Simulate /authorize</a></li>
</ul>
<p>Client ID: <code>${CLIENT_ID}</code> &middot; Client Secret: <code>${CLIENT_SECRET}</code></p>`));

app.get('/avatar.png', (_req, res) => res.sendFile('avatar.png', { root: import.meta.dirname }));

app.get('/health', (_req, res) => res.json({ status: 'ok', issuer: ISSUER }));

app.use((req, res) => res.status(404).json({
  error: 'not_found', path: req.path,
  hint: 'See /.well-known/openid-configuration',
}));

// ---------- Start ----------
app.listen(PORT, () => {
  console.log(`Mock OIDC listening on :${PORT}  issuer=${ISSUER}  public=${PUBLIC}  client_id=${CLIENT_ID}  autologin=${USER.email} (sub=${USER.sub}, roles=${USER.roles.join(',')})`);
});
