#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/tic-tac-toe-classic-324324/database"
cd "$WORKSPACE"
# Create minimal scaffold if package.json missing
if [ ! -f package.json ]; then
  cat > package.json <<'JSON'
{ "name": "tic-tac-toe-static", "version": "1.0.0", "scripts": { "build": "cp -r public dist || true", "start": "node server.js" }, "devDependencies": { "jest": "^29.0.0" } }
JSON
fi
mkdir -p public dist
# minimal index
if [ ! -f public/index.html ]; then
  cat > public/index.html <<'HTML'
<!doctype html><html><head><meta charset="utf-8"><title>tic-tac-toe</title></head><body><h1>tic-tac-toe</h1></body></html>
HTML
fi
# server.js to serve dist/
if [ ! -f server.js ]; then
  cat > server.js <<'NODE'
#!/usr/bin/env node
const http = require('http');
const fs = require('fs');
const path = require('path');
const PORT = process.env.PORT || 3000;
const dist = path.join(__dirname, 'dist');
const server = http.createServer((req,res)=>{
  let p = req.url === '/' ? '/index.html' : req.url;
  const fp = path.join(dist, decodeURI(p));
  fs.readFile(fp,(err,data)=>{
    if(err){ res.statusCode=404; res.end('Not Found'); } else { res.statusCode=200; res.end(data); }
  });
});
server.listen(PORT, '127.0.0.1', ()=>{
  // write pid to /tmp/db_server.pid for external control
  try{ require('fs').writeFileSync('/tmp/db_server.pid', String(process.pid)); }catch(e){}
  console.log('listening',PORT);
});
// cleanup on SIGTERM
process.on('SIGTERM', ()=>{ process.exit(0); });
NODE
  chmod +x server.js
fi
