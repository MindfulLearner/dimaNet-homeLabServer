const http = require('http');
const fs   = require('fs');

const LOG_FILE = '/root/.pm2/logs/mr-edgar-out.log';
const PORT     = 3001;

http.createServer((req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Content-Type', 'application/json');
    try {
        const content = fs.readFileSync(LOG_FILE, 'utf8');
        const lines   = content.split('\n').filter(l => l.trim()).slice(-100);
        res.end(JSON.stringify({ lines }));
    } catch {
        res.end(JSON.stringify({ lines: ['log file not found'] }));
    }
}).listen(PORT);
