-- =====================================================================
-- Migración 001 — Chat, archivos e notificaciones en MySQL
-- (reemplaza lo que antes se planeaba hacer con Firebase)
--
-- Cómo aplicarla (sobre la base existente, p. ej. servicios_app):
--   mysql -u root -p servicios_app < sql/001_chat_archivos_notificaciones.sql
-- o abrirla en MySQL Workbench y ejecutar todo el script.
--
-- Es re-ejecutable: las tablas usan IF NOT EXISTS y los procedimientos
-- se recrean con DROP ... IF EXISTS.
--
-- Depende de estas tablas existentes:
--   usuarios(id_usuario INT, nombre, apellido, activo)
--   bloqueos(id_usuario_bloquea, id_usuario_bloqueado)   <- ver fn_hay_bloqueo
-- El primer bloque verifica que existan con esas columnas y detiene el
-- script con un mensaje claro si no coinciden.
-- =====================================================================

DELIMITER $$

-- ---------------------------------------------------------------------
-- 0. Verificación del esquema existente
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS tmp_verificar_esquema_001 $$
CREATE PROCEDURE tmp_verificar_esquema_001()
BEGIN
    IF (SELECT COUNT(*) FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'usuarios'
          AND column_name IN ('id_usuario', 'nombre', 'apellido', 'activo')) < 4 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
            'Migración 001: la tabla usuarios no tiene las columnas id_usuario, nombre, apellido y activo.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'usuarios'
          AND column_name = 'id_usuario' AND data_type = 'int'
          AND column_type NOT LIKE '%unsigned%') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
            'Migración 001: usuarios.id_usuario no es INT (con signo). Ajusta el tipo de las columnas id_usuario/id_remitente de este script.';
    END IF;

    IF (SELECT COUNT(*) FROM information_schema.columns
        WHERE table_schema = DATABASE() AND table_name = 'bloqueos'
          AND column_name IN ('id_usuario_bloquea', 'id_usuario_bloqueado')) < 2 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT =
            'Migración 001: la tabla bloqueos no tiene las columnas id_usuario_bloquea e id_usuario_bloqueado. Ajusta fn_hay_bloqueo con los nombres reales.';
    END IF;
END $$

CALL tmp_verificar_esquema_001() $$
DROP PROCEDURE IF EXISTS tmp_verificar_esquema_001 $$

DELIMITER ;

-- ---------------------------------------------------------------------
-- 1. Tablas
-- ---------------------------------------------------------------------

-- Archivos subidos al servidor (fotos de perfil, publicaciones, chat...).
-- Solo se guarda la ruta; el archivo vive en la carpeta UPLOADS_DIR.
CREATE TABLE IF NOT EXISTS archivos (
    id_archivo      INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario      INT          NOT NULL,
    ruta            VARCHAR(255) NOT NULL,
    tipo_mime       VARCHAR(50)  NOT NULL,
    tamano_bytes    INT UNSIGNED NOT NULL,
    fecha_subida    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_archivos_ruta UNIQUE (ruta),
    CONSTRAINT fk_archivos_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- Una conversación por cada par de usuarios. Se guarda siempre con
-- id_usuario_1 < id_usuario_2 para que el par sea único.
-- ultimo_leido_N = id del último mensaje que el usuario N ya vio.
CREATE TABLE IF NOT EXISTS conversaciones (
    id_conversacion      INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario_1         INT      NOT NULL,
    id_usuario_2         INT      NOT NULL,
    ultimo_leido_1       BIGINT   NOT NULL DEFAULT 0,
    ultimo_leido_2       BIGINT   NOT NULL DEFAULT 0,
    fecha_creacion       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_ultimo_mensaje DATETIME NULL,
    CONSTRAINT uq_conversaciones_par UNIQUE (id_usuario_1, id_usuario_2),
    CONSTRAINT ck_conversaciones_orden CHECK (id_usuario_1 < id_usuario_2),
    CONSTRAINT fk_conversaciones_u1 FOREIGN KEY (id_usuario_1) REFERENCES usuarios (id_usuario),
    CONSTRAINT fk_conversaciones_u2 FOREIGN KEY (id_usuario_2) REFERENCES usuarios (id_usuario),
    INDEX ix_conversaciones_u2 (id_usuario_2),
    INDEX ix_conversaciones_fecha (fecha_ultimo_mensaje)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

CREATE TABLE IF NOT EXISTS mensajes (
    id_mensaje      BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_conversacion INT           NOT NULL,
    id_remitente    INT           NOT NULL,
    contenido       VARCHAR(2000) NULL,
    url_imagen      VARCHAR(255)  NULL,
    fecha_envio     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_mensajes_contenido CHECK (contenido IS NOT NULL OR url_imagen IS NOT NULL),
    CONSTRAINT fk_mensajes_conversacion FOREIGN KEY (id_conversacion) REFERENCES conversaciones (id_conversacion),
    CONSTRAINT fk_mensajes_remitente FOREIGN KEY (id_remitente) REFERENCES usuarios (id_usuario),
    INDEX ix_mensajes_conversacion (id_conversacion, id_mensaje)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

-- Notificaciones dentro de la app (la campanita). Sin push por ahora.
CREATE TABLE IF NOT EXISTS notificaciones (
    id_notificacion BIGINT AUTO_INCREMENT PRIMARY KEY,
    id_usuario      INT          NOT NULL,
    tipo            VARCHAR(30)  NOT NULL,
    titulo          VARCHAR(120) NOT NULL,
    cuerpo          VARCHAR(255) NULL,
    id_referencia   INT          NULL,
    leida           TINYINT(1)   NOT NULL DEFAULT 0,
    fecha_creacion  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notificaciones_usuario FOREIGN KEY (id_usuario) REFERENCES usuarios (id_usuario),
    INDEX ix_notificaciones_usuario (id_usuario, leida, id_notificacion)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4;

DELIMITER $$

-- ---------------------------------------------------------------------
-- 2. Función auxiliar de bloqueos
--    ÚNICO lugar que depende de los nombres de columna de `bloqueos`.
-- ---------------------------------------------------------------------
DROP FUNCTION IF EXISTS fn_hay_bloqueo $$
CREATE FUNCTION fn_hay_bloqueo(p_usuario_a INT, p_usuario_b INT)
RETURNS TINYINT
READS SQL DATA
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM bloqueos
        WHERE (id_usuario_bloquea = p_usuario_a AND id_usuario_bloqueado = p_usuario_b)
           OR (id_usuario_bloquea = p_usuario_b AND id_usuario_bloqueado = p_usuario_a)
    );
END $$

-- ---------------------------------------------------------------------
-- 3. Archivos
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_archivo_registrar $$
CREATE PROCEDURE sp_archivo_registrar(
    IN p_id_usuario INT,
    IN p_ruta VARCHAR(255),
    IN p_tipo_mime VARCHAR(50),
    IN p_tamano_bytes INT UNSIGNED
)
BEGIN
    INSERT INTO archivos (id_usuario, ruta, tipo_mime, tamano_bytes)
    VALUES (p_id_usuario, p_ruta, p_tipo_mime, p_tamano_bytes);

    SELECT LAST_INSERT_ID() AS id_archivo;
END $$

-- ---------------------------------------------------------------------
-- 4. Chat
-- ---------------------------------------------------------------------

-- Verifica que el usuario participa en la conversación y que no hay
-- bloqueo entre ambos. Devuelve en p_lado 1 o 2 (qué columna le toca).
DROP PROCEDURE IF EXISTS sp_conversacion_verificar_acceso $$
CREATE PROCEDURE sp_conversacion_verificar_acceso(
    IN p_id_usuario INT,
    IN p_id_conversacion INT,
    OUT p_lado TINYINT,
    OUT p_id_otro INT
)
BEGIN
    DECLARE v_u1 INT;
    DECLARE v_u2 INT;

    SELECT id_usuario_1, id_usuario_2 INTO v_u1, v_u2
    FROM conversaciones
    WHERE id_conversacion = p_id_conversacion;

    IF v_u1 IS NULL OR (v_u1 <> p_id_usuario AND v_u2 <> p_id_usuario) THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Conversación no encontrada.';
    END IF;

    SET p_lado = IF(v_u1 = p_id_usuario, 1, 2);
    SET p_id_otro = IF(v_u1 = p_id_usuario, v_u2, v_u1);

    IF fn_hay_bloqueo(p_id_usuario, p_id_otro) THEN
        SIGNAL SQLSTATE '45403' SET MESSAGE_TEXT = 'Esta conversación no está disponible.';
    END IF;
END $$

-- Devuelve la conversación con otro usuario; la crea si no existe.
DROP PROCEDURE IF EXISTS sp_conversacion_obtener_o_crear $$
CREATE PROCEDURE sp_conversacion_obtener_o_crear(
    IN p_id_usuario INT,
    IN p_id_otro INT
)
BEGIN
    DECLARE v_id INT;

    IF p_id_usuario = p_id_otro THEN
        SIGNAL SQLSTATE '45400' SET MESSAGE_TEXT = 'No puedes iniciar una conversación contigo mismo.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id_usuario = p_id_otro AND activo = TRUE) THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'El usuario no existe.';
    END IF;

    IF fn_hay_bloqueo(p_id_usuario, p_id_otro) THEN
        SIGNAL SQLSTATE '45403' SET MESSAGE_TEXT = 'No puedes enviar mensajes a este usuario.';
    END IF;

    SELECT id_conversacion INTO v_id
    FROM conversaciones
    WHERE id_usuario_1 = LEAST(p_id_usuario, p_id_otro)
      AND id_usuario_2 = GREATEST(p_id_usuario, p_id_otro);

    IF v_id IS NULL THEN
        -- ON DUPLICATE KEY cubre el caso de dos peticiones simultáneas.
        INSERT INTO conversaciones (id_usuario_1, id_usuario_2)
        VALUES (LEAST(p_id_usuario, p_id_otro), GREATEST(p_id_usuario, p_id_otro))
        ON DUPLICATE KEY UPDATE id_conversacion = LAST_INSERT_ID(id_conversacion);
        SET v_id = LAST_INSERT_ID();
    END IF;

    SELECT v_id AS id_conversacion;
END $$

-- Bandeja de entrada: conversaciones con al menos un mensaje, la más
-- reciente primero. Oculta las conversaciones con usuarios bloqueados.
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

-- Mensajes de una conversación, siempre en orden cronológico.
--   p_despues_de: solo mensajes nuevos (para consultar cada pocos segundos).
--   p_antes_de:   página anterior del historial.
--   ninguno:      los últimos p_limite mensajes.
-- `leido` indica si el OTRO usuario ya vio el mensaje (palomitas).
DROP PROCEDURE IF EXISTS sp_mensajes_listar $$
CREATE PROCEDURE sp_mensajes_listar(
    IN p_id_usuario INT,
    IN p_id_conversacion INT,
    IN p_despues_de BIGINT,
    IN p_antes_de BIGINT,
    IN p_limite INT
)
BEGIN
    DECLARE v_lado TINYINT;
    DECLARE v_id_otro INT;
    DECLARE v_leido_otro BIGINT;

    CALL sp_conversacion_verificar_acceso(p_id_usuario, p_id_conversacion, v_lado, v_id_otro);

    SELECT IF(v_lado = 1, ultimo_leido_2, ultimo_leido_1) INTO v_leido_otro
    FROM conversaciones WHERE id_conversacion = p_id_conversacion;

    IF p_despues_de IS NOT NULL THEN
        SELECT id_mensaje, id_remitente, (id_remitente = p_id_usuario) AS es_mio,
               contenido, url_imagen, fecha_envio, (id_mensaje <= v_leido_otro) AS leido
        FROM mensajes
        WHERE id_conversacion = p_id_conversacion AND id_mensaje > p_despues_de
        ORDER BY id_mensaje ASC
        LIMIT p_limite;
    ELSE
        SELECT * FROM (
            SELECT id_mensaje, id_remitente, (id_remitente = p_id_usuario) AS es_mio,
                   contenido, url_imagen, fecha_envio, (id_mensaje <= v_leido_otro) AS leido
            FROM mensajes
            WHERE id_conversacion = p_id_conversacion
              AND (p_antes_de IS NULL OR id_mensaje < p_antes_de)
            ORDER BY id_mensaje DESC
            LIMIT p_limite
        ) AS pagina
        ORDER BY id_mensaje ASC;
    END IF;
END $$

DROP PROCEDURE IF EXISTS sp_mensaje_enviar $$
CREATE PROCEDURE sp_mensaje_enviar(
    IN p_id_usuario INT,
    IN p_id_conversacion INT,
    IN p_contenido VARCHAR(2000),
    IN p_url_imagen VARCHAR(255)
)
BEGIN
    DECLARE v_lado TINYINT;
    DECLARE v_id_otro INT;
    DECLARE v_id_mensaje BIGINT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_contenido IS NULL AND p_url_imagen IS NULL THEN
        SIGNAL SQLSTATE '45400' SET MESSAGE_TEXT = 'El mensaje no puede estar vacío.';
    END IF;

    CALL sp_conversacion_verificar_acceso(p_id_usuario, p_id_conversacion, v_lado, v_id_otro);

    IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id_usuario = v_id_otro AND activo = TRUE) THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'El usuario ya no está disponible.';
    END IF;

    START TRANSACTION;

    INSERT INTO mensajes (id_conversacion, id_remitente, contenido, url_imagen)
    VALUES (p_id_conversacion, p_id_usuario, p_contenido, p_url_imagen);
    SET v_id_mensaje = LAST_INSERT_ID();

    -- Los mensajes propios cuentan como leídos para quien los envía.
    UPDATE conversaciones
    SET fecha_ultimo_mensaje = NOW(),
        ultimo_leido_1 = IF(v_lado = 1, v_id_mensaje, ultimo_leido_1),
        ultimo_leido_2 = IF(v_lado = 2, v_id_mensaje, ultimo_leido_2)
    WHERE id_conversacion = p_id_conversacion;

    COMMIT;

    SELECT id_mensaje, id_remitente, TRUE AS es_mio, contenido, url_imagen, fecha_envio, FALSE AS leido
    FROM mensajes WHERE id_mensaje = v_id_mensaje;
END $$

DROP PROCEDURE IF EXISTS sp_conversacion_marcar_leida $$
CREATE PROCEDURE sp_conversacion_marcar_leida(
    IN p_id_usuario INT,
    IN p_id_conversacion INT
)
BEGIN
    DECLARE v_lado TINYINT;
    DECLARE v_id_otro INT;
    DECLARE v_ultimo BIGINT;

    CALL sp_conversacion_verificar_acceso(p_id_usuario, p_id_conversacion, v_lado, v_id_otro);

    SELECT COALESCE(MAX(id_mensaje), 0) INTO v_ultimo
    FROM mensajes WHERE id_conversacion = p_id_conversacion;

    UPDATE conversaciones
    SET ultimo_leido_1 = IF(v_lado = 1, GREATEST(ultimo_leido_1, v_ultimo), ultimo_leido_1),
        ultimo_leido_2 = IF(v_lado = 2, GREATEST(ultimo_leido_2, v_ultimo), ultimo_leido_2)
    WHERE id_conversacion = p_id_conversacion;
END $$

-- Total de mensajes sin leer (para el globito de la pestaña Mensajes).
DROP PROCEDURE IF EXISTS sp_mensajes_contar_no_leidos $$
CREATE PROCEDURE sp_mensajes_contar_no_leidos(IN p_id_usuario INT)
BEGIN
    SELECT COUNT(*) AS total
    FROM conversaciones c
    JOIN mensajes m ON m.id_conversacion = c.id_conversacion
    WHERE (c.id_usuario_1 = p_id_usuario OR c.id_usuario_2 = p_id_usuario)
      AND m.id_remitente <> p_id_usuario
      AND m.id_mensaje > IF(c.id_usuario_1 = p_id_usuario, c.ultimo_leido_1, c.ultimo_leido_2)
      AND NOT fn_hay_bloqueo(c.id_usuario_1, c.id_usuario_2);
END $$

-- ---------------------------------------------------------------------
-- 5. Notificaciones
-- ---------------------------------------------------------------------
DROP PROCEDURE IF EXISTS sp_notificacion_crear $$
CREATE PROCEDURE sp_notificacion_crear(
    IN p_id_usuario INT,
    IN p_tipo VARCHAR(30),
    IN p_titulo VARCHAR(120),
    IN p_cuerpo VARCHAR(255),
    IN p_id_referencia INT
)
BEGIN
    INSERT INTO notificaciones (id_usuario, tipo, titulo, cuerpo, id_referencia)
    VALUES (p_id_usuario, p_tipo, p_titulo, p_cuerpo, p_id_referencia);

    SELECT LAST_INSERT_ID() AS id_notificacion;
END $$

DROP PROCEDURE IF EXISTS sp_notificaciones_listar $$
CREATE PROCEDURE sp_notificaciones_listar(
    IN p_id_usuario INT,
    IN p_solo_no_leidas TINYINT,
    IN p_limite INT,
    IN p_offset INT
)
BEGIN
    SELECT id_notificacion, tipo, titulo, cuerpo, id_referencia, leida, fecha_creacion
    FROM notificaciones
    WHERE id_usuario = p_id_usuario
      AND (p_solo_no_leidas = FALSE OR leida = FALSE)
    ORDER BY id_notificacion DESC
    LIMIT p_limite OFFSET p_offset;
END $$

DROP PROCEDURE IF EXISTS sp_notificaciones_contar_no_leidas $$
CREATE PROCEDURE sp_notificaciones_contar_no_leidas(IN p_id_usuario INT)
BEGIN
    SELECT COUNT(*) AS total
    FROM notificaciones
    WHERE id_usuario = p_id_usuario AND leida = FALSE;
END $$

DROP PROCEDURE IF EXISTS sp_notificacion_marcar_leida $$
CREATE PROCEDURE sp_notificacion_marcar_leida(
    IN p_id_usuario INT,
    IN p_id_notificacion BIGINT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM notificaciones
                   WHERE id_notificacion = p_id_notificacion AND id_usuario = p_id_usuario) THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Notificación no encontrada.';
    END IF;

    UPDATE notificaciones SET leida = TRUE
    WHERE id_notificacion = p_id_notificacion;
END $$

DROP PROCEDURE IF EXISTS sp_notificaciones_marcar_todas_leidas $$
CREATE PROCEDURE sp_notificaciones_marcar_todas_leidas(IN p_id_usuario INT)
BEGIN
    UPDATE notificaciones SET leida = TRUE
    WHERE id_usuario = p_id_usuario AND leida = FALSE;

    SELECT ROW_COUNT() AS actualizadas;
END $$

DELIMITER ;
