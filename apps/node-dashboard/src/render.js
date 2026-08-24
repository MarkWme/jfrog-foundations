'use strict';

// Server-rendered dashboard page.
//
// No bundler, no frontend framework, no build step. The chart library is served
// straight out of node_modules by app.js. Keeping the front end this dull is a
// deliberate choice: nobody attending this workshop should have to debug the
// sample application, only its dependencies.

const STATUS_COLORS = {
    healthy: '#2f9e44',
    degraded: '#e8a33d',
    unhealthy: '#d1453b'
};

// Minimal HTML entity escaping. Everything rendered here is generated
// server-side from a fixed inventory, but escaping on the way out is the habit
// worth keeping.
function escapeHtml(value) {
    return String(value)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;');
}

function statusBadge(status) {
    const color = STATUS_COLORS[status] || '#868e96';
    return `<span class="badge" style="background:${color}">${escapeHtml(status)}</span>`;
}

function serviceRow(service) {
    return `
        <tr>
          <td><strong>${escapeHtml(service.name)}</strong><br><span class="muted">${escapeHtml(service.id)}</span></td>
          <td>${escapeHtml(service.tier)}</td>
          <td>${escapeHtml(service.region)}</td>
          <td class="num">${service.uptime.toFixed(2)}%</td>
          <td class="num">${service.averageUptime.toFixed(2)}%</td>
          <td>${statusBadge(service.status)}</td>
        </tr>`;
}

function page(data) {
    const categories = data.services.length ? data.services[0].history.map((point) => point.label) : [];
    const series = data.services.map((service) => ({
        name: service.name,
        data: service.history.map((point) => point.uptime)
    }));

    const chartConfig = {
        chart: { type: 'line', height: 360 },
        title: { text: 'Uptime, last 24 hours' },
        xAxis: { categories, tickInterval: 3 },
        yAxis: { title: { text: 'Uptime %' }, min: 96, max: 100 },
        tooltip: { valueSuffix: '%', valueDecimals: 2 },
        credits: { enabled: false },
        series
    };

    return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Service Status</title>
  <style>
    :root { color-scheme: light dark; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      margin: 0; padding: 2rem; line-height: 1.5;
      background: #f8f9fa; color: #212529;
    }
    .wrap { max-width: 1080px; margin: 0 auto; }
    h1 { margin: 0 0 .25rem; font-size: 1.5rem; }
    .muted { color: #868e96; font-size: .85rem; }
    .cards { display: flex; flex-wrap: wrap; gap: 1rem; margin: 1.5rem 0; }
    .card {
      background: #fff; border: 1px solid #dee2e6; border-radius: 8px;
      padding: 1rem 1.25rem; min-width: 150px; flex: 1;
    }
    .card .value { font-size: 1.75rem; font-weight: 600; }
    table { width: 100%; border-collapse: collapse; background: #fff;
            border: 1px solid #dee2e6; border-radius: 8px; overflow: hidden; }
    th, td { padding: .6rem .75rem; text-align: left; border-bottom: 1px solid #f1f3f5; }
    th { background: #f1f3f5; font-size: .8rem; text-transform: uppercase; letter-spacing: .04em; }
    td.num, th.num { text-align: right; font-variant-numeric: tabular-nums; }
    .badge { color: #fff; padding: .1rem .5rem; border-radius: 999px; font-size: .75rem; }
    #chart { background: #fff; border: 1px solid #dee2e6; border-radius: 8px; padding: 1rem; margin-bottom: 1.5rem; }
    footer { margin-top: 2rem; }
    code { background: #e9ecef; padding: .1rem .3rem; border-radius: 3px; font-size: .85rem; }
  </style>
</head>
<body>
  <div class="wrap">
    <h1>Service Status</h1>
    <p class="muted">Generated ${escapeHtml(data.generatedAtLabel)}</p>

    <div class="cards">
      <div class="card"><div class="muted">Overall uptime</div><div class="value">${data.overallUptime.toFixed(2)}%</div></div>
      <div class="card"><div class="muted">Healthy</div><div class="value">${data.counts.healthy || 0}</div></div>
      <div class="card"><div class="muted">Degraded</div><div class="value">${data.counts.degraded || 0}</div></div>
      <div class="card"><div class="muted">Unhealthy</div><div class="value">${data.counts.unhealthy || 0}</div></div>
    </div>

    <div id="chart"></div>

    <table>
      <thead>
        <tr>
          <th>Service</th><th>Tier</th><th>Region</th>
          <th class="num">Now</th><th class="num">24h average</th><th>Status</th>
        </tr>
      </thead>
      <tbody>${data.services.map(serviceRow).join('')}
      </tbody>
    </table>

    <footer class="muted">
      <p>
        API: <code>/api/status</code> &middot; <code>/api/upstream</code> &middot;
        <code>/api/token</code> &middot; <code>/api/admin</code> &middot;
        <code>/api/diagnostics</code> &middot; <code>/healthz</code>
      </p>
      <p>
        JFrog Foundations workshop sample application. Ships deliberately
        vulnerable dependencies on purpose. See <code>README.md</code>.
      </p>
    </footer>
  </div>

  <script src="/vendor/highcharts/highcharts.js"></script>
  <script>
    // Highcharts is served from node_modules rather than a CDN, so the page
    // works in a Codespace behind a restrictive proxy.
    (function () {
      var config = ${JSON.stringify(chartConfig)};
      if (window.Highcharts) {
        Highcharts.chart('chart', config);
      } else {
        document.getElementById('chart').textContent =
          'Chart library did not load. Is highcharts installed in node_modules?';
      }
    }());
  </script>
</body>
</html>
`;
}

module.exports = { page, escapeHtml };
