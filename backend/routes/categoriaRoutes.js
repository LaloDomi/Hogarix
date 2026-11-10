const express = require('express');
const router = express.Router();
const { listarCategorias } = require('../controllers/categoriaController');

router.get('/', listarCategorias);

module.exports = router;
