const express = require('express');
const router = express.Router();
const {
    listarPublicaciones,
    obtenerPublicacion,
    crearPublicacion,
    eliminarPublicacion
} = require('../controllers/publicacionController');
const {
    listarComentarios,
    crearComentario,
    eliminarComentario,
    darLike,
    quitarLike
} = require('../controllers/interaccionController');
const { verificarToken } = require('../middlewares/authMiddleware');

// Todas las rutas requieren sesión (el feed depende del usuario: likes propios y bloqueos)
router.use(verificarToken);

router.get('/', listarPublicaciones);
router.post('/', crearPublicacion);
router.get('/:id_publicacion', obtenerPublicacion);
router.delete('/:id_publicacion', eliminarPublicacion);

router.get('/:id_publicacion/comentarios', listarComentarios);
router.post('/:id_publicacion/comentarios', crearComentario);
router.delete('/:id_publicacion/comentarios/:id_comentario', eliminarComentario);

router.post('/:id_publicacion/like', darLike);
router.delete('/:id_publicacion/like', quitarLike);

module.exports = router;
