'use strict';

// Express application for the status dashboard.
//
// Every route here exists to justify a dependency that the workshop needs to be
// present and vulnerable. That is stated plainly rather than disguised: see the
// dependency table in README.md for which route uses what and why.

const path = require('path');
const express = require('express');
const axios = require('axios');
const fetch = require('node-fetch');
const jwt = require('jsonwebtoken');
const tar = require('tar');
const _ = require('lodash');

const services = require('./services');
const render = require('./render');

const ROOT = path.join(__dirname, '..');

// NOT A REAL CREDENTIAL. A placeholder so the JWT routes work out of the box in
// a workshop, and a realistic finding for the secrets scanning in labs 05 and
// 07 to have something to say about. Do not copy this pattern into anything you
// actually ship: read the signing key from configuration and fail closed if it
// is absent.
const JWT_SECRET = process.env.JWT_SECRET || 'development-only-not-a-real-secret';

// Deliberately a domain that is reserved for documentation, so a Codespace with
// no outbound access degrades gracefully instead of hanging.
const UPSTREAM_URL = process.env.UPSTREAM_URL || 'https://example.com/';
const UPSTREAM_TIMEOUT_MS = Number(process.env.UPSTREAM_TIMEOUT_MS) || 1500;

// Probes the configured upstream with axios. Never throws: an unreachable
// upstream is normal in a workshop and must not take the dashboard down.
async function probeUpstream() {
    const startedAt = Date.now();
    try {
        const response = await axios.get(UPSTREAM_URL, {
            timeout: UPSTREAM_TIMEOUT_MS,
            validateStatus: null
        });
        return {
            url: UPSTREAM_URL,
            reachable: true,
            statusCode: response.status,
            elapsedMs: Date.now() - startedAt
        };
    } catch (error) {
        return {
            url: UPSTREAM_URL,
            reachable: false,
            error: error.code || error.message,
            elapsedMs: Date.now() - startedAt
        };
    }
}

function requireToken(request, response, next) {
    const header = request.get('authorization') || '';
    const match = /^Bearer\s+(.+)$/i.exec(header.trim());

    if (!match) {
        return response.status(401).json({
            error: 'missing bearer token',
            hint: 'GET /api/token, then send it as: Authorization: Bearer <token>'
        });
    }

    try {
        request.claims = jwt.verify(match[1], JWT_SECRET);
        return next();
    } catch (error) {
        return response.status(401).json({ error: 'invalid token', reason: error.message });
    }
}

function createApp() {
    const app = express();

    app.disable('x-powered-by');

    // Serve the chart library out of node_modules. No CDN, so the dashboard
    // renders inside a Codespace behind a restrictive proxy.
    app.use('/vendor/highcharts', express.static(path.join(ROOT, 'node_modules', 'highcharts')));

    // Dashboard.
    app.get('/', (request, response) => {
        response.type('html').send(render.page(services.snapshot()));
    });

    // Liveness. Intentionally does no work, so it stays fast and dependency free.
    app.get('/healthz', (request, response) => {
        response.json({ status: 'ok', uptimeSeconds: Math.round(process.uptime()) });
    });

    // Aggregated status, including an upstream probe.
    app.get('/api/status', async (request, response) => {
        const snapshot = services.snapshot();
        const upstream = await probeUpstream();
        response.json({
            generatedAt: snapshot.generatedAt,
            overallUptime: snapshot.overallUptime,
            counts: snapshot.counts,
            byRegion: snapshot.byRegion,
            worst: snapshot.worst,
            upstream,
            services: snapshot.services.map((service) =>
                _.omit(service, ['history', 'lastCheckedLabel'])
            )
        });
    });

    // Legacy upstream poller. Uses node-fetch rather than axios because it was
    // written before the codebase standardized on one HTTP client, which is a
    // situation most real repositories are in.
    app.get('/api/upstream', async (request, response) => {
        try {
            const upstreamResponse = await fetch(UPSTREAM_URL, { timeout: UPSTREAM_TIMEOUT_MS });
            const body = await upstreamResponse.text();
            response.json({
                url: UPSTREAM_URL,
                statusCode: upstreamResponse.status,
                contentType: upstreamResponse.headers.get('content-type'),
                bytes: Buffer.byteLength(body)
            });
        } catch (error) {
            response.status(502).json({
                url: UPSTREAM_URL,
                error: error.code || error.message
            });
        }
    });

    // Mints a short-lived token, so the admin route can be exercised without
    // any external identity provider. Not how you would issue tokens in
    // production, and lab 07 discusses why.
    app.get('/api/token', (request, response) => {
        const token = jwt.sign(
            { sub: 'workshop-operator', scope: ['status:read', 'admin:read'] },
            JWT_SECRET,
            { expiresIn: '15m' }
        );
        response.json({ token, tokenType: 'Bearer', expiresIn: 900 });
    });

    // Token-protected detail view.
    app.get('/api/admin', requireToken, (request, response) => {
        const snapshot = services.snapshot();
        response.json({
            caller: request.claims.sub,
            scope: request.claims.scope,
            serviceCount: snapshot.services.length,
            byRegion: snapshot.byRegion,
            configuration: {
                upstreamUrl: UPSTREAM_URL,
                upstreamTimeoutMs: UPSTREAM_TIMEOUT_MS,
                nodeVersion: process.version
            }
        });
    });

    // Support bundle. Streams a gzipped tar of the application's own manifest
    // and source, which is the sort of "send us your diagnostics" endpoint that
    // turns up in real services.
    app.get('/api/diagnostics', (request, response) => {
        response.type('application/gzip');
        response.setHeader('Content-Disposition', 'attachment; filename="diagnostics.tar.gz"');

        const archive = tar.c({ gzip: true, cwd: ROOT }, ['package.json', 'src']);

        archive.on('error', (error) => {
            if (!response.headersSent) {
                response.status(500).json({ error: 'could not build diagnostics bundle', reason: error.message });
            } else {
                response.destroy(error);
            }
        });

        archive.pipe(response);
    });

    app.use((request, response) => {
        response.status(404).json({ error: 'not found', path: request.path });
    });

    return app;
}

module.exports = { createApp, probeUpstream, requireToken };
