const http = require('http'), fs = require('fs'), path = require('path');
const port = process.env.PORT || 3000;
const base = path.join(__dirname,'dist');
function send(res, p){fs.readFile(path.join(base,p),(e,d)=>{if(e){res.writeHead(404);res.end();}else{res.writeHead(200);res.end(d);}})}
const srv = http.createServer((req,res)=>{const p = req.url === '/' ? '/index.html' : req.url; send(res,p);});
if(require.main === module){srv.listen(port,()=>console.log('listening',port));}
module.exports = srv;
