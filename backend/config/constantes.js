module.exports = {
    ROLES: {
        CLIENTE: 1,
        TRABAJADOR: 2
    },
    TIPOS_PAGO: ['Día', 'Destajo', 'Por trabajo', 'Por hora'],
    ESTADOS_SOLICITUD: ['Pendiente', 'Aceptado', 'Rechazado', 'Completado', 'Cancelado'],
    PLATAFORMAS: ['Android', 'iOS'],

    // Tipos de notificación que genera el backend (columna notificaciones.tipo)
    TIPOS_NOTIFICACION: {
        SOLICITUD_NUEVA: 'solicitud_nueva',
        SOLICITUD_ESTADO: 'solicitud_estado',
        VISITA: 'visita'
    },

    CHAT: {
        MAX_CONTENIDO: 2000,
        MENSAJES_POR_PAGINA: 30,
        MENSAJES_POR_PAGINA_MAX: 100
    }
};
