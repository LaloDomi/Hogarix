const express = require('express');
const router = express.Router();
const { listarBloqueos, bloquearUsuario, desbloquearUsuario } = require('../controllers/moderacionController');
const { verificarToken } = require('../middlewares/authMiddleware');

router.use(verificarToken);

router.get('/', listarBloqueos);
router.post('/:id_usuario', bloquearUsuario);
router.delete('/:id_usuario', desbloquearUsuario);

module.exports = router;
