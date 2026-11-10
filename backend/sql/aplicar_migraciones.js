// Aplica los scripts SQL a la base del .env (la de Aiven) sin usar Workbench.
//
// Uso (desde la carpeta backend):
//   node sql/aplicar_migraciones.js                 -> aplica 004 y 005
//   node sql/aplicar_migraciones.js 003_xxx.sql     -> aplica solo ese archivo
//
// Los scripts son re-ejecutables: correrlo dos veces no daña nada.
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const db = require('../config/db');

const POR_DEFECTO = ['004_telefono_codigos.sql', '005_cambiar_contrasena.sql'];

// Separa el script en sentencias respetando "DELIMITER $$" (como Workbench).
const separar = (texto) => {
    const sentencias = [];
    let delimitador = ';';
    let actual = [];
    for (const linea of texto.split(/\r?\n/)) {
        const limpia = linea.trim();
        const cambio = limpia.match(/^DELIMITER\s+(\S+)$/i);
        if (cambio) {
            delimitador = cambio[1];
            continue;
        }
        if (!actual.length && (limpia === '' || limpia.startsWith('--'))) continue;
        actual.push(linea);
        if (limpia.endsWith(delimitador)) {
            const sql = actual.join('\n').trim();
            sentencias.push(sql.slice(0, sql.length - delimitador.length).trim());
            actual = [];
        }
    }
    const resto = actual.join('\n').trim();
    if (resto) sentencias.push(resto);
    return sentencias.filter((s) => s && !/^USE\s/i.test(s));
};

const main = async () => {
    const archivos = process.argv.slice(2).length ? process.argv.slice(2) : POR_DEFECTO;
    console.log(`\nBase: "${process.env.DB_NAME}" en ${process.env.DB_HOST}\n`);

    for (const nombre of archivos) {
        const ruta = path.join(__dirname, path.basename(nombre));
        if (!fs.existsSync(ruta)) {
            console.error(`No existe ${ruta}`);
            process.exitCode = 1;
            continue;
        }
        const sentencias = separar(fs.readFileSync(ruta, 'utf8'));
        process.stdout.write(`${path.basename(ruta)} (${sentencias.length} sentencias)... `);
        try {
            for (const sql of sentencias) await db.query(sql);
            console.log('listo');
        } catch (error) {
            console.log('ERROR');
            console.error(`  ${error.message}\n  En:\n${error.sql ? error.sql.slice(0, 300) : ''}\n`);
            process.exitCode = 1;
            break;
        }
    }
    await db.end();
    if (!process.exitCode) console.log('\nMigraciones aplicadas. Ya puedes correr: npm run dev\n');
};

if (require.main === module) {
    main().catch((error) => {
        console.error('No se pudo aplicar:', error.message);
        process.exit(1);
    });
}

module.exports = { separar };
