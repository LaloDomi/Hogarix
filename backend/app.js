const express = require('express');
const cors = require('cors');
require('dotenv').config();
const { UPLOADS_DIR, RUTA_PUBLICA } = require('./config/almacenamiento');

const app = express();

app.use(cors());
// Render y otros hostings ponen un proxy delante: así req.protocol e IP son correctos.
app.set('trust proxy', 1);
app.use(express.json({ limit: '100kb' }));

// Imágenes subidas con POST /api/archivos
app.use(RUTA_PUBLICA, express.static(UPLOADS_DIR, {
    index: false,
    dotfiles: 'deny',
    maxAge: '7d',
    setHeaders: (res) => res.set('X-Content-Type-Options', 'nosniff')
}));

// Para revisar rápido que el servidor y la base de datos responden:
// abre http://localhost:3001/api/salud en el navegador.
app.get('/api/salud', async (req, res) => {
    try {
        await require('./config/db').query('SELECT 1');
        return res.status(200).json({ ok: true, mensaje: 'Servidor y base de datos funcionando.' });
    } catch (error) {
        return res.status(503).json({ ok: false, mensaje: `El servidor funciona pero MySQL no responde: ${error.message}` });
    }
});

app.use('/api/servicios', require('./routes/servicioRoutes'));
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/categorias', require('./routes/categoriaRoutes'));
app.use('/api/trabajadores', require('./routes/trabajadorRoutes'));
app.use('/api/publicaciones', require('./routes/publicacionRoutes'));
app.use('/api/solicitudes', require('./routes/solicitudRoutes'));
app.use('/api/resenas', require('./routes/resenaRoutes'));
app.use('/api/favoritos', require('./routes/favoritoRoutes'));
app.use('/api/reportes', require('./routes/reporteRoutes'));
app.use('/api/bloqueos', require('./routes/bloqueoRoutes'));
app.use('/api/dispositivos', require('./routes/dispositivoRoutes'));
app.use('/api/agenda', require('./routes/agendaRoutes'));
app.use('/api/archivos', require('./routes/archivoRoutes'));
app.use('/api/conversaciones', require('./routes/conversacionRoutes'));
app.use('/api/notificaciones', require('./routes/notificacionRoutes'));
app.use('/api/visitas', require('./routes/visitaRoutes'));
app.use('/api/ia', require('./routes/iaRoutes'));

// Rutas inexistentes y errores no controlados también responden { ok, mensaje }
app.use('/api', (req, res) => {
    res.status(404).json({ ok: false, mensaje: 'Ruta no encontrada.' });
});

app.use((err, req, res, next) => {
    if (err.type === 'entity.parse.failed') {
        return res.status(400).json({ ok: false, mensaje: 'El cuerpo de la petición no es JSON válido.' });
    }
    console.error('Error no controlado:', err);
    return res.status(500).json({ ok: false, mensaje: 'Error interno del servidor.' });
});

module.exports = app;
