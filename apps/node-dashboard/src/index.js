'use strict';

const { createApp } = require('./app');

const PORT = Number(process.env.PORT) || 3000;
const HOST = process.env.HOST || '0.0.0.0';

const server = createApp().listen(PORT, HOST, () => {
    console.log(`Service Status dashboard listening on http://localhost:${PORT}`);
    console.log('In a Codespace, open the forwarded port from the Ports panel.');
});

// Shut down cleanly so "docker stop" and Ctrl-C do not leave the port held.
['SIGINT', 'SIGTERM'].forEach((signal) => {
    process.on(signal, () => {
        console.log(`\nReceived ${signal}, shutting down.`);
        server.close(() => process.exit(0));
    });
});
