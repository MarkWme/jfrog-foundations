'use strict';

// Service inventory and uptime history for the dashboard.
//
// The data is synthetic but deterministic: the same service and hour always
// produce the same number. That is deliberate. A dashboard that reshuffles on
// every reload makes screenshots inconsistent and makes it harder to tell a
// real change from noise while working through a lab.

const _ = require('lodash');
const moment = require('moment');

const SERVICES = [
    { id: 'checkout', name: 'Checkout API', tier: 'critical', region: 'eu-west-1' },
    { id: 'catalog', name: 'Catalog Service', tier: 'critical', region: 'eu-west-1' },
    { id: 'search', name: 'Search Indexer', tier: 'standard', region: 'us-east-1' },
    { id: 'billing', name: 'Billing Worker', tier: 'critical', region: 'us-east-1' },
    { id: 'notify', name: 'Notification Relay', tier: 'standard', region: 'eu-west-1' },
    { id: 'reports', name: 'Reporting Batch', tier: 'batch', region: 'us-east-1' }
];

const HISTORY_HOURS = 24;

// FNV-1a. Small, dependency-free, and good enough to spread values evenly.
function hash(input) {
    let h = 2166136261;
    for (let i = 0; i < input.length; i += 1) {
        h ^= input.charCodeAt(i);
        h = Math.imul(h, 16777619);
    }
    return h >>> 0;
}

// Uptime percentage for one service in one hour slot, in the range 98.00 to
// 100.00, biased so that batch tiers look slightly worse than critical ones.
function uptimeFor(serviceId, hourIndex, tier) {
    const spread = hash(`${serviceId}:${hourIndex}`) % 1000;
    const floor = tier === 'batch' ? 97.0 : 98.5;
    const ceiling = 100.0;
    const value = floor + (spread / 1000) * (ceiling - floor);
    return Math.round(value * 100) / 100;
}

function statusFor(uptime) {
    if (uptime >= 99.5) return 'healthy';
    if (uptime >= 98.5) return 'degraded';
    return 'unhealthy';
}

// One service's hourly history, oldest first.
function historyFor(service) {
    return _.range(HISTORY_HOURS).map((offset) => {
        const hourIndex = HISTORY_HOURS - 1 - offset;
        const at = moment().subtract(hourIndex, 'hours').startOf('hour');
        return {
            at: at.toISOString(),
            label: at.format('HH:mm'),
            uptime: uptimeFor(service.id, hourIndex, service.tier)
        };
    });
}

// Current snapshot for every service, plus the rollups the dashboard shows.
function snapshot() {
    const services = SERVICES.map((service) => {
        const history = historyFor(service);
        const current = _.last(history);
        const average = Math.round(_.meanBy(history, 'uptime') * 100) / 100;
        return {
            id: service.id,
            name: service.name,
            tier: service.tier,
            region: service.region,
            uptime: current.uptime,
            averageUptime: average,
            status: statusFor(current.uptime),
            lastChecked: current.at,
            lastCheckedLabel: moment(current.at).format('D MMM YYYY, HH:mm'),
            history
        };
    });

    const ordered = _.orderBy(services, ['uptime', 'name'], ['asc', 'asc']);

    return {
        generatedAt: moment().toISOString(),
        generatedAtLabel: moment().format('D MMM YYYY, HH:mm:ss'),
        overallUptime: Math.round(_.meanBy(services, 'uptime') * 100) / 100,
        counts: _.countBy(services, 'status'),
        byRegion: _.mapValues(
            _.groupBy(services, 'region'),
            (group) => Math.round(_.meanBy(group, 'uptime') * 100) / 100
        ),
        worst: _.take(ordered, 3).map((service) => _.pick(service, ['id', 'name', 'uptime', 'status'])),
        services
    };
}

module.exports = { SERVICES, HISTORY_HOURS, snapshot, statusFor };
