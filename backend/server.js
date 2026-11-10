require('dotenv').config();
const app = require('./app');
const db = require('./config/db');

const PORT = process.env.PORT || 3001;

if (!process.env.JWT_SECRET) {
    console.error('\n Falta JWT_SECRET en el archivo .env (copia .env.example a .env y llénalo).\n');
    process.exit(1);
}

const servidor = app.listen(PORT, async () => {
    console.log(`\n Servidor corriendo en http://localhost:${PORT}`);
    console.log(` Revisión rápida: http://localhost:${PORT}/api/salud\n`);

    // Avisa de inmediato si MySQL no responde, en vez de fallar en cada petición.
    try {
        await db.query('SELECT 1');
        const [[{ visitas }]] = await db.query(
            "SELECT COUNT(*) AS visitas FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'visitas'"
        );
        console.log(` Conectado a MySQL (base "${process.env.DB_NAME}").`);
        if (!Number(visitas)) {
            console.log(' Aviso: falta aplicar sql/003_ubicacion_perfil_visitas_social.sql (ubicación, login social y visitas).');
        }
    } catch (error) {
        console.error(` No se pudo conectar a MySQL: ${error.message}`);
        console.error(' Revisa que MySQL esté encendido y que DB_USER, DB_PASSWORD y DB_NAME del .env sean correctos.\n');
    }
});

servidor.on('error', (error) => {
    if (error.code === 'EADDRINUSE') {
        console.error(`\n El puerto ${PORT} ya está en uso. ¿Ya hay otro backend abierto? Ciérralo o cambia PORT en .env.\n`);
    } else {
        console.error(error);
    }
    process.exit(1);
});
