const fs = require("fs");
const path = require("path");
//
const centralJS     = "E:\\Mega\\praticomai\\praticom-shared-library\\resources\\_js";
const apiBase       = "E:\\Mega\\praticomai\\api";
const backupDir     = "E:\\Mega\\praticomai\\Backups\\shared_js";
const logFile       = "E:\\Mega\\praticomai\\Logs\\sync_log.txt";
//
function logWrite(msg) {
    //
    const timestamp   = new Date().toISOString();
    const linha       = `[${timestamp}] ${msg}\n`;
    //
    fs.appendFileSync(logFile, linha);
    //
    console.log(linha.trim());
}
//
function createFileIfNotExists(dir) {
    //
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
}
//
function microsArray(baseDir) {
    //
    const dirs   = fs.readdirSync(baseDir, { withFileTypes: true });
    const micros = [];
    //
    dirs.forEach(d => {
        //
        if (d.isDirectory()) {
            //
            const jsDir = path.join(baseDir, d.name, "_js");
            //
            createFileIfNotExists(jsDir);
            //
            micros.push(jsDir);
        }
    });
    //
    return micros;
}
//
function copyIfUpdate(from,to) {
    //
    let copy = true;
    //
    if (fs.existsSync(to)) {
        const origStat = fs.statSync(from);
        const destStat = fs.statSync(to);
        //
        if (origStat.size === destStat.size &&
            origStat.mtimeMs <= destStat.mtimeMs) {
            copy = false;
        }
    }
    //
    if (copy) {
        fs.copyFileSync(from, to);
        logWrite(`Arquivo ${path.basename(from)} copiado para ${to}`);
    }
}
//
function syncJS() {
    //
    createFileIfNotExists(backupDir);
    //
    const micros = microsArray(apiBase);
    const files  = fs.readdirSync(centralJS).filter(f => f.endsWith(".js"));
    //
    files.forEach(file => {
        const origemPath = path.join(centralJS, file);
        const backupPath = path.join(backupDir, file);
        //
        copyIfUpdate(origemPath, backupPath);
        //
        micros.forEach(ms => {
            const pathTo = path.join(ms, file);
            copyIfUpdate(origemPath, pathTo);
        });
    });
    //
    logWrite("Sincronização concluída!");
}
//
syncJS();
//
fs.watch(centralJS, (eventType, filename) => {
    //
    if (filename && filename.endsWith(".js")) {
        logWrite(`Alteração detectada em ${filename}, iniciando sincronização...`);
        syncJS();
    }
});