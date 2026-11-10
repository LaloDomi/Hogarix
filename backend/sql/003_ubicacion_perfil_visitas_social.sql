-- =====================================================================
-- Migración 003 — Ubicación, perfil completo, inicio de sesión social y
-- visitas de trabajo en el calendario.
--
-- Cómo aplicarla (sobre la base existente servicios_app):
--   MySQL Workbench: File > Open SQL Script... > este archivo > ejecutar todo (rayo)
--   o en terminal:   mysql -u root -p servicios_app < sql/003_ubicacion_perfil_visitas_social.sql
--
-- Es re-ejecutable: las columnas e índices solo se agregan si faltan, la
-- tabla usa IF NOT EXISTS y los procedimientos se recrean.
--
-- Qué agrega:
--   usuarios: estado_mx, municipio, colonia (ubicación elegida a mano),
--             fecha_nacimiento, sexo, id_google, id_facebook
--   visitas:  citas de trabajo ligadas a una solicitud (las ven cliente y trabajador)
--   procedimientos de perfil, login social y visitas; y versiones nuevas de
--   sp_usuario_obtener_por_id, sp_servicios_buscar, sp_trabajador_obtener_perfil,
--   sp_conversaciones_listar y sp_solicitud_listar con los datos nuevos.
-- =====================================================================

USE `servicios_app`;

DELIMITER $$

-- ---------------------------------------------------------------------
-- 0. Ayudantes temporales para agregar columnas e índices solo si faltan
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS tmp_agregar_columna_003 $$
CREATE PROCEDURE tmp_agregar_columna_003(IN p_tabla VARCHAR(64), IN p_columna VARCHAR(64), IN p_definicion TEXT)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = p_tabla AND column_name = p_columna
    ) THEN
        SET @sql_003 = CONCAT('ALTER TABLE `', p_tabla, '` ADD COLUMN `', p_columna, '` ', p_definicion);
        PREPARE st_003 FROM @sql_003;
        EXECUTE st_003;
        DEALLOCATE PREPARE st_003;
    END IF;
END $$

DROP PROCEDURE IF EXISTS tmp_agregar_indice_003 $$
CREATE PROCEDURE tmp_agregar_indice_003(IN p_tabla VARCHAR(64), IN p_indice VARCHAR(64), IN p_definicion TEXT)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.statistics
        WHERE table_schema = DATABASE() AND table_name = p_tabla AND index_name = p_indice
    ) THEN
        SET @sql_003 = CONCAT('ALTER TABLE `', p_tabla, '` ADD ', p_definicion);
        PREPARE st_003 FROM @sql_003;
        EXECUTE st_003;
        DEALLOCATE PREPARE st_003;
    END IF;
END $$

DELIMITER ;

-- ---------------------------------------------------------------------
-- 1. Columnas nuevas en usuarios
-- ---------------------------------------------------------------------
CALL tmp_agregar_columna_003('usuarios', 'estado_mx', 'VARCHAR(60) NULL AFTER foto_perfil');
CALL tmp_agregar_columna_003('usuarios', 'municipio', 'VARCHAR(100) NULL AFTER estado_mx');
CALL tmp_agregar_columna_003('usuarios', 'colonia', 'VARCHAR(120) NULL AFTER municipio');
CALL tmp_agregar_columna_003('usuarios', 'fecha_nacimiento', 'DATE NULL AFTER colonia');
CALL tmp_agregar_columna_003('usuarios', 'sexo', 'VARCHAR(20) NULL AFTER fecha_nacimiento');
CALL tmp_agregar_columna_003('usuarios', 'id_google', 'VARCHAR(64) NULL');
CALL tmp_agregar_columna_003('usuarios', 'id_facebook', 'VARCHAR(64) NULL');

CALL tmp_agregar_indice_003('usuarios', 'uq_usuarios_id_google', 'UNIQUE KEY `uq_usuarios_id_google` (`id_google`)');
CALL tmp_agregar_indice_003('usuarios', 'uq_usuarios_id_facebook', 'UNIQUE KEY `uq_usuarios_id_facebook` (`id_facebook`)');
CALL tmp_agregar_indice_003('usuarios', 'idx_usuarios_ubicacion', 'KEY `idx_usuarios_ubicacion` (`estado_mx`, `municipio`)');

-- ---------------------------------------------------------------------
-- 2. Visitas de trabajo (calendario compartido cliente <-> trabajador)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `visitas` (
  `id_visita` int NOT NULL AUTO_INCREMENT,
  `id_solicitud` int NOT NULL,
  `id_creador` int NOT NULL,
  `fecha_inicio` datetime NOT NULL,
  `fecha_fin` datetime NOT NULL,
  `direccion` varchar(255) DEFAULT NULL,
  `notas` text,
  `estado` enum('Propuesta','Confirmada','Cancelada','Realizada') NOT NULL DEFAULT 'Propuesta',
  `fecha_creacion` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_visita`),
  KEY `idx_visitas_solicitud` (`id_solicitud`),
  KEY `idx_visitas_rango` (`fecha_inicio`, `fecha_fin`),
  CONSTRAINT `visitas_ibfk_solicitud` FOREIGN KEY (`id_solicitud`) REFERENCES `solicitudes_trabajo` (`id_solicitud`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `visitas_ibfk_creador` FOREIGN KEY (`id_creador`) REFERENCES `usuarios` (`id_usuario`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chk_visita_fechas` CHECK ((`fecha_fin` > `fecha_inicio`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DROP PROCEDURE IF EXISTS tmp_agregar_columna_003;
DROP PROCEDURE IF EXISTS tmp_agregar_indice_003;

DELIMITER $$

-- ---------------------------------------------------------------------
-- 3. Perfil del usuario
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_usuario_obtener_por_id $$
CREATE PROCEDURE sp_usuario_obtener_por_id(
    IN p_id_usuario INT
)
BEGIN
    SELECT u.id_usuario, u.id_rol, u.nombre, u.apellido, u.correo, u.telefono, u.foto_perfil,
           u.estado_mx, u.municipio, u.colonia, u.fecha_nacimiento, u.sexo,
           IF(u.fecha_nacimiento IS NULL, NULL, TIMESTAMPDIFF(YEAR, u.fecha_nacimiento, CURDATE())) AS edad,
           u.fecha_registro, r.nombre_rol
    FROM usuarios u
    JOIN roles r ON u.id_rol = r.id_rol
    WHERE u.id_usuario = p_id_usuario;
END $$

-- Los parámetros NULL no cambian el valor actual. Para borrar un dato
-- opcional se manda texto vacío ('') y se guarda como NULL.
DROP PROCEDURE IF EXISTS sp_usuario_actualizar_perfil $$
CREATE PROCEDURE sp_usuario_actualizar_perfil(
    IN p_id_usuario INT,
    IN p_nombre VARCHAR(100),
    IN p_apellido VARCHAR(100),
    IN p_telefono VARCHAR(20),
    IN p_foto_perfil VARCHAR(255),
    IN p_estado_mx VARCHAR(60),
    IN p_municipio VARCHAR(100),
    IN p_colonia VARCHAR(120),
    IN p_fecha_nacimiento DATE,
    IN p_sexo VARCHAR(20)
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id_usuario = p_id_usuario AND activo = TRUE) THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Usuario no encontrado.';
    END IF;
    IF p_fecha_nacimiento IS NOT NULL AND p_fecha_nacimiento > DATE_SUB(CURDATE(), INTERVAL 16 YEAR) THEN
        SIGNAL SQLSTATE '45400' SET MESSAGE_TEXT = 'Debes tener al menos 16 años.';
    END IF;

    UPDATE usuarios
    SET nombre      = COALESCE(NULLIF(p_nombre, ''), nombre),
        apellido    = COALESCE(NULLIF(p_apellido, ''), apellido),
        telefono    = IF(p_telefono IS NULL, telefono, NULLIF(p_telefono, '')),
        foto_perfil = IF(p_foto_perfil IS NULL, foto_perfil, NULLIF(p_foto_perfil, '')),
        estado_mx   = IF(p_estado_mx IS NULL, estado_mx, NULLIF(p_estado_mx, '')),
        municipio   = IF(p_municipio IS NULL, municipio, NULLIF(p_municipio, '')),
        colonia     = IF(p_colonia IS NULL, colonia, NULLIF(p_colonia, '')),
        fecha_nacimiento = COALESCE(p_fecha_nacimiento, fecha_nacimiento),
        sexo        = IF(p_sexo IS NULL, sexo, NULLIF(p_sexo, ''))
    WHERE id_usuario = p_id_usuario;

    CALL sp_usuario_obtener_por_id(p_id_usuario);
END $$

-- ---------------------------------------------------------------------
-- 4. Inicio de sesión con Google / Facebook
-- ---------------------------------------------------------------------
-- Busca por el id del proveedor; si no existe, por correo (y entonces lo
-- vincula para la próxima vez). Devuelve las mismas columnas que el login.
DROP PROCEDURE IF EXISTS sp_usuario_buscar_social $$
CREATE PROCEDURE sp_usuario_buscar_social(
    IN p_proveedor VARCHAR(20),
    IN p_id_externo VARCHAR(64),
    IN p_correo VARCHAR(150)
)
BEGIN
    DECLARE v_id INT DEFAULT NULL;

    IF p_proveedor = 'google' THEN
        SELECT id_usuario INTO v_id FROM usuarios WHERE id_google = p_id_externo LIMIT 1;
    ELSEIF p_proveedor = 'facebook' THEN
        SELECT id_usuario INTO v_id FROM usuarios WHERE id_facebook = p_id_externo LIMIT 1;
    ELSE
        SIGNAL SQLSTATE '45400' SET MESSAGE_TEXT = 'Proveedor no válido.';
    END IF;

    IF v_id IS NULL AND p_correo IS NOT NULL AND p_correo <> '' THEN
        SELECT id_usuario INTO v_id FROM usuarios WHERE correo = p_correo LIMIT 1;
        IF v_id IS NOT NULL THEN
            CALL sp_usuario_vincular_social(v_id, p_proveedor, p_id_externo);
        END IF;
    END IF;

    SELECT u.id_usuario, u.id_rol, u.nombre, u.apellido, u.correo, u.activo, r.nombre_rol
    FROM usuarios u
    JOIN roles r ON u.id_rol = r.id_rol
    WHERE u.id_usuario = v_id;
END $$

DROP PROCEDURE IF EXISTS sp_usuario_vincular_social $$
CREATE PROCEDURE sp_usuario_vincular_social(
    IN p_id_usuario INT,
    IN p_proveedor VARCHAR(20),
    IN p_id_externo VARCHAR(64)
)
BEGIN
    IF p_proveedor = 'google' THEN
        UPDATE usuarios SET id_google = p_id_externo WHERE id_usuario = p_id_usuario;
    ELSEIF p_proveedor = 'facebook' THEN
        UPDATE usuarios SET id_facebook = p_id_externo WHERE id_usuario = p_id_usuario;
    ELSE
        SIGNAL SQLSTATE '45400' SET MESSAGE_TEXT = 'Proveedor no válido.';
    END IF;
END $$

-- ---------------------------------------------------------------------
-- 5. Búsqueda y perfil público con ubicación
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_servicios_buscar $$
CREATE PROCEDURE sp_servicios_buscar(
    IN p_id_categoria INT,
    IN p_tipo_pago VARCHAR(20)
)
BEGIN
    SELECT st.id_servicio, st.id_categoria, st.tipo_pago, st.precio_base, st.descripcion_servicio,
           c.nombre_categoria,
           u.id_usuario, u.nombre, u.apellido, u.foto_perfil, u.estado_mx, u.municipio,
           pt.disponible,
           (SELECT ROUND(AVG(r.calificacion), 2)
              FROM resenas r WHERE r.id_calificado = u.id_usuario) AS calificacion_promedio,
           (SELECT COUNT(*)
              FROM resenas r2 WHERE r2.id_calificado = u.id_usuario) AS total_resenas
    FROM servicios_trabajador st
    JOIN categorias c ON st.id_categoria = c.id_categoria
    JOIN perfiles_trabajador pt ON st.id_perfil = pt.id_perfil
    JOIN usuarios u ON pt.id_usuario = u.id_usuario
    WHERE st.id_categoria = p_id_categoria
      AND u.activo = TRUE
      AND (p_tipo_pago IS NULL OR st.tipo_pago = p_tipo_pago)
    ORDER BY pt.disponible DESC, calificacion_promedio DESC, u.nombre ASC, st.id_servicio ASC;
END $$

DROP PROCEDURE IF EXISTS sp_trabajador_obtener_perfil $$
CREATE PROCEDURE sp_trabajador_obtener_perfil(IN p_id_usuario INT)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM perfiles_trabajador pt
        JOIN usuarios u ON u.id_usuario = pt.id_usuario
        WHERE pt.id_usuario = p_id_usuario AND u.activo = TRUE
    ) THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Trabajador no encontrado.';
    END IF;

    SELECT u.id_usuario, u.nombre, u.apellido, u.foto_perfil, u.fecha_registro,
           u.estado_mx, u.municipio, u.sexo,
           IF(u.fecha_nacimiento IS NULL, NULL, TIMESTAMPDIFF(YEAR, u.fecha_nacimiento, CURDATE())) AS edad,
           pt.biografia, pt.disponible,
           (SELECT ROUND(AVG(r.calificacion), 2) FROM resenas r WHERE r.id_calificado = u.id_usuario) AS calificacion_promedio,
           (SELECT COUNT(*) FROM resenas r2 WHERE r2.id_calificado = u.id_usuario) AS total_resenas
    FROM usuarios u
    JOIN perfiles_trabajador pt ON pt.id_usuario = u.id_usuario
    WHERE u.id_usuario = p_id_usuario;

    SELECT st.id_servicio, st.id_categoria, c.nombre_categoria, st.tipo_pago, st.precio_base, st.descripcion_servicio
    FROM servicios_trabajador st
    JOIN categorias c ON c.id_categoria = st.id_categoria
    JOIN perfiles_trabajador pt ON pt.id_perfil = st.id_perfil
    WHERE pt.id_usuario = p_id_usuario
    ORDER BY c.nombre_categoria;
END $$

-- Bandeja de chat: ahora incluye la foto del otro usuario.
DROP PROCEDURE IF EXISTS sp_conversaciones_listar $$
CREATE PROCEDURE sp_conversaciones_listar(
    IN p_id_usuario INT,
    IN p_limite INT,
    IN p_offset INT
)
BEGIN
    SELECT
        c.id_conversacion,
        u.id_usuario  AS id_otro_usuario,
        u.nombre      AS nombre_otro_usuario,
        u.apellido    AS apellido_otro_usuario,
        u.foto_perfil AS foto_otro_usuario,
        m.id_mensaje  AS id_ultimo_mensaje,
        m.contenido   AS ultimo_mensaje,
        m.url_imagen  AS ultima_imagen,
        (m.id_remitente = p_id_usuario) AS ultimo_es_mio,
        c.fecha_ultimo_mensaje,
        (SELECT COUNT(*) FROM mensajes mm
          WHERE mm.id_conversacion = c.id_conversacion
            AND mm.id_remitente <> p_id_usuario
            AND mm.id_mensaje > IF(c.id_usuario_1 = p_id_usuario, c.ultimo_leido_1, c.ultimo_leido_2)
        ) AS no_leidos
    FROM conversaciones c
    JOIN usuarios u
      ON u.id_usuario = IF(c.id_usuario_1 = p_id_usuario, c.id_usuario_2, c.id_usuario_1)
    JOIN mensajes m
      ON m.id_mensaje = (SELECT MAX(x.id_mensaje) FROM mensajes x WHERE x.id_conversacion = c.id_conversacion)
    WHERE (c.id_usuario_1 = p_id_usuario OR c.id_usuario_2 = p_id_usuario)
      AND u.activo = TRUE
      AND NOT fn_hay_bloqueo(p_id_usuario, u.id_usuario)
    ORDER BY c.fecha_ultimo_mensaje DESC, c.id_conversacion DESC
    LIMIT p_limite OFFSET p_offset;
END $$

-- Solicitudes: ahora incluyen la ubicación del cliente y la próxima visita.
DROP PROCEDURE IF EXISTS sp_solicitud_listar $$
CREATE PROCEDURE sp_solicitud_listar(
    IN p_id_usuario INT,
    IN p_id_solicitud INT,
    IN p_estado VARCHAR(20),
    IN p_limite INT,
    IN p_offset INT
)
BEGIN
    SELECT s.id_solicitud, s.estado, s.tipo_pago_acordado, s.monto_estimado, s.fecha_solicitud,
           s.id_categoria, c.nombre_categoria,
           s.id_cliente, uc.nombre AS nombre_cliente, uc.apellido AS apellido_cliente, uc.foto_perfil AS foto_cliente,
           uc.estado_mx AS estado_cliente, uc.municipio AS municipio_cliente, uc.colonia AS colonia_cliente,
           s.id_trabajador, ut.nombre AS nombre_trabajador, ut.apellido AS apellido_trabajador, ut.foto_perfil AS foto_trabajador,
           EXISTS (
               SELECT 1 FROM resenas r WHERE r.id_solicitud = s.id_solicitud AND r.id_autor = p_id_usuario
           ) AS ya_califique,
           (SELECT DATE_FORMAT(MIN(v.fecha_inicio), '%Y-%m-%d %H:%i:%s') FROM visitas v
             WHERE v.id_solicitud = s.id_solicitud
               AND v.estado IN ('Propuesta', 'Confirmada')
               AND v.fecha_fin >= NOW()
           ) AS proxima_visita
    FROM solicitudes_trabajo s
    JOIN categorias c ON c.id_categoria = s.id_categoria
    JOIN usuarios uc ON uc.id_usuario = s.id_cliente
    JOIN usuarios ut ON ut.id_usuario = s.id_trabajador
    WHERE (s.id_cliente = p_id_usuario OR s.id_trabajador = p_id_usuario)
      AND (p_id_solicitud IS NULL OR s.id_solicitud = p_id_solicitud)
      AND (p_estado IS NULL OR s.estado = p_estado)
    ORDER BY s.fecha_solicitud DESC, s.id_solicitud DESC
    LIMIT p_limite OFFSET p_offset;
END $$

-- ---------------------------------------------------------------------
-- 6. Visitas
-- ---------------------------------------------------------------------
-- Error 45409 si el trabajador ya tiene algo en ese horario: otra visita
-- activa o un bloque de su agenda personal. p_excluir = visita que se está
-- reprogramando (no choca consigo misma).
DROP PROCEDURE IF EXISTS sp_visita_verificar_horario $$
CREATE PROCEDURE sp_visita_verificar_horario(
    IN p_id_trabajador INT,
    IN p_inicio DATETIME,
    IN p_fin DATETIME,
    IN p_excluir INT
)
BEGIN
    IF p_fin <= p_inicio THEN
        SIGNAL SQLSTATE '45400' SET MESSAGE_TEXT = 'La hora de fin debe ser posterior a la de inicio.';
    END IF;
    IF p_inicio < NOW() THEN
        SIGNAL SQLSTATE '45400' SET MESSAGE_TEXT = 'No puedes agendar una visita en el pasado.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM visitas v
        JOIN solicitudes_trabajo s ON s.id_solicitud = v.id_solicitud
        WHERE s.id_trabajador = p_id_trabajador
          AND v.estado IN ('Propuesta', 'Confirmada')
          AND (p_excluir IS NULL OR v.id_visita <> p_excluir)
          AND v.fecha_inicio < p_fin AND v.fecha_fin > p_inicio
    ) THEN
        SIGNAL SQLSTATE '45409' SET MESSAGE_TEXT = 'El trabajador ya tiene una visita en ese horario.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM eventos_agenda e
        WHERE e.id_usuario = p_id_trabajador
          AND e.fecha_inicio < p_fin AND e.fecha_fin > p_inicio
    ) THEN
        SIGNAL SQLSTATE '45409' SET MESSAGE_TEXT = 'El trabajador tiene ese horario ocupado en su agenda.';
    END IF;
END $$

DROP PROCEDURE IF EXISTS sp_visita_crear $$
CREATE PROCEDURE sp_visita_crear(
    IN p_id_usuario INT,
    IN p_id_solicitud INT,
    IN p_inicio DATETIME,
    IN p_fin DATETIME,
    IN p_direccion VARCHAR(255),
    IN p_notas TEXT
)
BEGIN
    DECLARE v_cliente INT;
    DECLARE v_trabajador INT;
    DECLARE v_estado VARCHAR(20);

    SELECT id_cliente, id_trabajador, estado INTO v_cliente, v_trabajador, v_estado
    FROM solicitudes_trabajo WHERE id_solicitud = p_id_solicitud;

    IF v_cliente IS NULL THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Solicitud no encontrada.';
    END IF;
    IF p_id_usuario NOT IN (v_cliente, v_trabajador) THEN
        SIGNAL SQLSTATE '45403' SET MESSAGE_TEXT = 'No participas en esta solicitud.';
    END IF;
    IF v_estado NOT IN ('Pendiente', 'Aceptado') THEN
        SIGNAL SQLSTATE '45400' SET MESSAGE_TEXT = 'Solo se pueden agendar visitas de solicitudes pendientes o aceptadas.';
    END IF;

    CALL sp_visita_verificar_horario(v_trabajador, p_inicio, p_fin, NULL);

    INSERT INTO visitas (id_solicitud, id_creador, fecha_inicio, fecha_fin, direccion, notas)
    VALUES (p_id_solicitud, p_id_usuario, p_inicio, p_fin, NULLIF(p_direccion, ''), NULLIF(p_notas, ''));

    SELECT LAST_INSERT_ID() AS id_visita,
           IF(p_id_usuario = v_cliente, v_trabajador, v_cliente) AS id_otro;
END $$

DROP PROCEDURE IF EXISTS sp_visitas_listar $$
CREATE PROCEDURE sp_visitas_listar(
    IN p_id_usuario INT,
    IN p_desde DATETIME,
    IN p_hasta DATETIME
)
BEGIN
    SELECT v.id_visita, v.id_solicitud, v.fecha_inicio, v.fecha_fin, v.direccion, v.notas, v.estado,
           v.id_creador, (v.id_creador = p_id_usuario) AS propuesta_por_mi,
           s.id_categoria, c.nombre_categoria, s.estado AS estado_solicitud,
           s.id_cliente, uc.nombre AS nombre_cliente, uc.apellido AS apellido_cliente, uc.foto_perfil AS foto_cliente,
           s.id_trabajador, ut.nombre AS nombre_trabajador, ut.apellido AS apellido_trabajador, ut.foto_perfil AS foto_trabajador
    FROM visitas v
    JOIN solicitudes_trabajo s ON s.id_solicitud = v.id_solicitud
    JOIN categorias c ON c.id_categoria = s.id_categoria
    JOIN usuarios uc ON uc.id_usuario = s.id_cliente
    JOIN usuarios ut ON ut.id_usuario = s.id_trabajador
    WHERE (s.id_cliente = p_id_usuario OR s.id_trabajador = p_id_usuario)
      AND v.estado <> 'Cancelada'
      AND v.fecha_inicio < p_hasta
      AND v.fecha_fin > p_desde
    ORDER BY v.fecha_inicio ASC, v.id_visita ASC;
END $$

-- Confirmada: solo quien NO la propuso, desde Propuesta.
-- Cancelada:  cualquiera de los dos, desde Propuesta o Confirmada.
-- Realizada:  solo el trabajador, desde Confirmada.
DROP PROCEDURE IF EXISTS sp_visita_cambiar_estado $$
CREATE PROCEDURE sp_visita_cambiar_estado(
    IN p_id_usuario INT,
    IN p_id_visita INT,
    IN p_estado VARCHAR(20)
)
BEGIN
    DECLARE v_estado VARCHAR(20);
    DECLARE v_creador INT;
    DECLARE v_cliente INT;
    DECLARE v_trabajador INT;

    SELECT v.estado, v.id_creador, s.id_cliente, s.id_trabajador
      INTO v_estado, v_creador, v_cliente, v_trabajador
    FROM visitas v
    JOIN solicitudes_trabajo s ON s.id_solicitud = v.id_solicitud
    WHERE v.id_visita = p_id_visita;

    IF v_estado IS NULL THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Visita no encontrada.';
    END IF;
    IF p_id_usuario NOT IN (v_cliente, v_trabajador) THEN
        SIGNAL SQLSTATE '45403' SET MESSAGE_TEXT = 'No participas en esta visita.';
    END IF;

    IF p_estado = 'Confirmada' THEN
        IF v_estado <> 'Propuesta' THEN
            SIGNAL SQLSTATE '45400' SET MESSAGE_TEXT = 'Solo se pueden confirmar visitas propuestas.';
        END IF;
        IF p_id_usuario = v_creador THEN
            SIGNAL SQLSTATE '45403' SET MESSAGE_TEXT = 'La otra persona es quien debe confirmar la visita.';
        END IF;
    ELSEIF p_estado = 'Cancelada' THEN
        IF v_estado NOT IN ('Propuesta', 'Confirmada') THEN
            SIGNAL SQLSTATE '45400' SET MESSAGE_TEXT = 'Esta visita ya no se puede cancelar.';
        END IF;
    ELSEIF p_estado = 'Realizada' THEN
        IF p_id_usuario <> v_trabajador THEN
            SIGNAL SQLSTATE '45403' SET MESSAGE_TEXT = 'Solo el trabajador puede marcar la visita como realizada.';
        END IF;
        IF v_estado <> 'Confirmada' THEN
            SIGNAL SQLSTATE '45400' SET MESSAGE_TEXT = 'Solo se pueden marcar como realizadas las visitas confirmadas.';
        END IF;
    ELSE
        SIGNAL SQLSTATE '45400' SET MESSAGE_TEXT = 'Estado no permitido.';
    END IF;

    UPDATE visitas SET estado = p_estado WHERE id_visita = p_id_visita;

    SELECT p_id_visita AS id_visita, p_estado AS estado,
           IF(p_id_usuario = v_cliente, v_trabajador, v_cliente) AS id_otro;
END $$

-- Cambia fecha/hora (y opcionalmente dirección y notas). Vuelve a quedar como
-- "Propuesta" y ahora la otra persona debe confirmarla.
DROP PROCEDURE IF EXISTS sp_visita_reprogramar $$
CREATE PROCEDURE sp_visita_reprogramar(
    IN p_id_usuario INT,
    IN p_id_visita INT,
    IN p_inicio DATETIME,
    IN p_fin DATETIME,
    IN p_direccion VARCHAR(255),
    IN p_notas TEXT
)
BEGIN
    DECLARE v_estado VARCHAR(20);
    DECLARE v_cliente INT;
    DECLARE v_trabajador INT;

    SELECT v.estado, s.id_cliente, s.id_trabajador
      INTO v_estado, v_cliente, v_trabajador
    FROM visitas v
    JOIN solicitudes_trabajo s ON s.id_solicitud = v.id_solicitud
    WHERE v.id_visita = p_id_visita;

    IF v_estado IS NULL THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Visita no encontrada.';
    END IF;
    IF p_id_usuario NOT IN (v_cliente, v_trabajador) THEN
        SIGNAL SQLSTATE '45403' SET MESSAGE_TEXT = 'No participas en esta visita.';
    END IF;
    IF v_estado NOT IN ('Propuesta', 'Confirmada') THEN
        SIGNAL SQLSTATE '45400' SET MESSAGE_TEXT = 'Esta visita ya no se puede reprogramar.';
    END IF;

    CALL sp_visita_verificar_horario(v_trabajador, p_inicio, p_fin, p_id_visita);

    UPDATE visitas
    SET fecha_inicio = p_inicio,
        fecha_fin = p_fin,
        direccion = IF(p_direccion IS NULL, direccion, NULLIF(p_direccion, '')),
        notas = IF(p_notas IS NULL, notas, NULLIF(p_notas, '')),
        estado = 'Propuesta',
        id_creador = p_id_usuario
    WHERE id_visita = p_id_visita;

    SELECT p_id_visita AS id_visita,
           IF(p_id_usuario = v_cliente, v_trabajador, v_cliente) AS id_otro;
END $$

DELIMITER ;
