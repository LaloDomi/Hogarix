const CategoriaModel = require('../models/categoriaModel');
const ResenaModel = require('../models/resenaModel');
const { ROLES } = require('../config/constantes');
const { texto, entero } = require('../utils/helpers');
const { completar, leerJson, ErrorIA } = require('../utils/ia');

const MAX_MENSAJES = 12;
const MAX_CARACTERES = 1000;

// Las categorías casi no cambian: se guardan 10 minutos en memoria.
let cacheCategorias = { datos: null, hasta: 0 };
const categorias = async () => {
    if (cacheCategorias.datos && Date.now() < cacheCategorias.hasta) return cacheCategorias.datos;
    const datos = await CategoriaModel.listar();
    cacheCategorias = { datos, hasta: Date.now() + 10 * 60 * 1000 };
    return datos;
};

const REGLAS_COMUNES = `
Hablas español de México, con tono cálido, claro y respetuoso. Tus respuestas son breves
(máximo 120 palabras); usa pasos numerados cortos solo cuando ayuden.
Si hay un riesgo (gas, electricidad, agua cerca de la electricidad, estructuras dañadas),
primero di la medida de seguridad (cerrar la llave del gas, bajar el interruptor, salir del lugar)
y en una emergencia indica llamar al 911.
No inventes precios exactos: si te preguntan, da una idea general de qué influye en el costo y
aclara que el precio final se acuerda con el trabajador dentro de la app.
Si te preguntan algo que no tiene que ver con el hogar, los oficios o el uso de la app,
responde con amabilidad que solo puedes ayudar con eso.
Nunca pidas contraseñas, datos bancarios ni documentos personales.`;

const sistemaCliente = (lista) => `Eres el asistente de OficioLink (Hogarix), una app mexicana que conecta
a clientes con trabajadores de oficios (plomería, electricidad, carpintería, herrería, etc.).
Ayudas a la persona a entender su problema en casa, le das recomendaciones básicas y le dices
qué tipo de profesional necesita para que lo contrate en la app.
${REGLAS_COMUNES}

Categorías de la app (id: nombre):
${lista}

Responde SIEMPRE solo con un objeto JSON con exactamente estas claves:
{"respuesta": "texto para la persona", "id_categoria": id de la lista que mejor encaje o null si aún no está claro o no aplica}`;

const sistemaTrabajador = () => `Eres el asistente de OficioLink (Hogarix), una app mexicana donde
trabajadores de oficios ofrecen sus servicios. Ayudas al trabajador a: describir sus servicios y
trabajos, armar una cotización (materiales, mano de obra, tiempo, traslado), redactar mensajes
amables y claros para sus clientes, conseguir buenas reseñas y trabajar con seguridad.
${REGLAS_COMUNES}

Responde SIEMPRE solo con un objeto JSON con exactamente estas claves:
{"respuesta": "texto para la persona", "id_categoria": null}`;

const responderError = (res, error, contexto) => {
    if (error instanceof ErrorIA) {
        return res.status(error.codigo).json({ ok: false, mensaje: error.message });
    }
    console.error(`Error en ${contexto}:`, error);
    return res.status(500).json({ ok: false, mensaje: 'Error interno del servidor.' });
};

// POST /api/ia/asistente
// { mensajes: [{ rol: 'usuario' | 'asistente', texto }] }  (el último es de la persona)
// -> { data: { respuesta, categoria: { id_categoria, nombre_categoria } | null } }
const asistente = async (req, res) => {
    try {
        const entrada = Array.isArray(req.body?.mensajes) ? req.body.mensajes : null;
        if (!entrada || !entrada.length) {
            return res.status(400).json({ ok: false, mensaje: 'Escribe tu pregunta.' });
        }

        const mensajes = entrada.slice(-MAX_MENSAJES).map((m) => ({
            role: m?.rol === 'asistente' ? 'assistant' : 'user',
            content: texto(m?.texto).slice(0, MAX_CARACTERES)
        })).filter((m) => m.content);

        if (!mensajes.length || mensajes[mensajes.length - 1].role !== 'user') {
            return res.status(400).json({ ok: false, mensaje: 'Escribe tu pregunta.' });
        }

        const esTrabajador = Number(req.usuario.id_rol) === ROLES.TRABAJADOR;
        let lista = [];
        if (!esTrabajador) {
            try { lista = await categorias(); } catch (_) { lista = []; }
        }
        const sistema = esTrabajador
            ? sistemaTrabajador()
            : sistemaCliente(lista.map((c) => `${c.id_categoria}: ${c.nombre_categoria}`).join('\n') || '(sin categorías)');

        const crudo = await completar({ sistema, mensajes, json: true });
        const r = leerJson(crudo);

        const respuesta = typeof r?.respuesta === 'string' && r.respuesta.trim()
            ? r.respuesta.trim()
            : crudo;
        const idSugerido = Number(r?.id_categoria);
        const cat = lista.find((c) => Number(c.id_categoria) === idSugerido);

        return res.status(200).json({
            ok: true,
            data: {
                respuesta,
                categoria: cat ? { id_categoria: Number(cat.id_categoria), nombre_categoria: cat.nombre_categoria } : null
            }
        });
    } catch (error) {
        return responderError(res, error, 'asistente IA');
    }
};

const TIPOS_TEXTO = {
    publicacion: {
        que: 'la descripción de un trabajo que un trabajador de oficios ya terminó y publica en su portafolio',
        palabras: 80
    },
    servicio: {
        que: 'la descripción de un servicio que ofrece un trabajador de oficios (qué incluye y cómo trabaja)',
        palabras: 60
    },
    biografia: {
        que: 'la presentación personal de un trabajador de oficios en su perfil',
        palabras: 70
    },
    solicitud: {
        que: 'el mensaje de un cliente que describe a un trabajador el problema o trabajo que necesita',
        palabras: 80
    }
};

// POST /api/ia/mejorar-texto  { texto, tipo, titulo?, categoria? } -> { data: { texto } }
const mejorarTexto = async (req, res) => {
    try {
        const b = req.body ?? {};
        const tipo = TIPOS_TEXTO[texto(b.tipo)];
        if (!tipo) {
            return res.status(400).json({ ok: false, mensaje: `tipo debe ser: ${Object.keys(TIPOS_TEXTO).join(', ')}.` });
        }
        const original = texto(b.texto).slice(0, 1500);
        const titulo = texto(b.titulo).slice(0, 150);
        const categoria = texto(b.categoria).slice(0, 100);
        if (original.length < 3 && !titulo) {
            return res.status(400).json({ ok: false, mensaje: 'Escribe primero unas palabras para que la IA las mejore.' });
        }

        const sistema = `Eres un redactor para OficioLink, una app mexicana de oficios. Mejoras ${tipo.que}.
Reglas: español de México, tono profesional y cercano, ortografía correcta, máximo ${tipo.palabras} palabras.
Conserva todo lo que dijo la persona y NO inventes datos que no estén (precios, años de experiencia,
garantías, materiales, horarios, nombres). Sin hashtags y sin emojis.
Devuelve solo el texto final, sin comillas, sin títulos y sin explicaciones.`;

        const partes = [];
        if (categoria) partes.push(`Oficio: ${categoria}`);
        if (titulo) partes.push(`Título: ${titulo}`);
        partes.push(`Texto: ${original || '(vacío: escribe una descripción breve a partir del título)'}`);

        const resultado = await completar({
            sistema,
            mensajes: [{ role: 'user', content: partes.join('\n') }],
            maxTokens: 400,
            temperatura: 0.4
        });

        const limpio = resultado.replace(/^["“«]+|["”»]+$/g, '').trim();
        return res.status(200).json({ ok: true, data: { texto: limpio } });
    } catch (error) {
        return responderError(res, error, 'mejorar texto IA');
    }
};

// Resúmenes en memoria por trabajador. Se rehacen cuando llega una reseña
// nueva o pasan 12 horas, para no gastar la cuota del proveedor.
const MIN_RESENAS_RESUMEN = 3;
const cacheResumenes = new Map();

// GET /api/ia/resumen-resenas/:id_usuario
// -> { data: { resumen: string | null, total, motivo? } }
const resumenResenas = async (req, res) => {
    try {
        const id_usuario = entero(req.params.id_usuario);
        if (!id_usuario) return res.status(400).json({ ok: false, mensaje: 'id_usuario no es válido.' });

        const resenas = await ResenaModel.listarPorUsuario(id_usuario, 50, 0);
        const conTexto = resenas.filter((r) => texto(r.comentario).length >= 3);
        if (conTexto.length < MIN_RESENAS_RESUMEN) {
            return res.status(200).json({
                ok: true,
                data: {
                    resumen: null,
                    total: conTexto.length,
                    motivo: `El resumen aparece cuando hay al menos ${MIN_RESENAS_RESUMEN} reseñas con comentario.`
                }
            });
        }

        const clave = `${resenas.length}:${resenas.map((r) => r.id_resena).join(',')}`;
        const guardado = cacheResumenes.get(id_usuario);
        if (guardado && guardado.clave === clave && Date.now() < guardado.hasta) {
            return res.status(200).json({ ok: true, data: { resumen: guardado.resumen, total: conTexto.length } });
        }

        const lista = conTexto.slice(0, 40)
            .map((r) => `- (${Number(r.calificacion)} de 5) ${texto(r.comentario).slice(0, 300)}`)
            .join('\n');

        const resumen = await completar({
            sistema: `Resumes las reseñas que los clientes dejaron a un trabajador de oficios en OficioLink.
Escribe en español de México, en tercera persona y en un solo párrafo de máximo 60 palabras:
qué destacan los clientes y, solo si varias reseñas lo mencionan, en qué podría mejorar.
No inventes nada que no esté en las reseñas, no menciones nombres y no uses emojis.
Devuelve solo el párrafo, sin comillas ni títulos.`,
            mensajes: [{ role: 'user', content: `Reseñas:\n${lista}` }],
            maxTokens: 250,
            temperatura: 0.3
        });
        const limpio = resumen.replace(/^["“«]+|["”»]+$/g, '').trim();

        if (cacheResumenes.size > 500) cacheResumenes.clear();
        cacheResumenes.set(id_usuario, { clave, resumen: limpio, hasta: Date.now() + 12 * 60 * 60 * 1000 });

        return res.status(200).json({ ok: true, data: { resumen: limpio, total: conTexto.length } });
    } catch (error) {
        return responderError(res, error, 'resumen de reseñas IA');
    }
};

module.exports = { asistente, mejorarTexto, resumenResenas };
