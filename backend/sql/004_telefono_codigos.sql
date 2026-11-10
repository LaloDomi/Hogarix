-- =====================================================================
-- Migración 004 — Cuentas con teléfono, restablecer contraseña y entrar
-- con un código enviado al correo (Gmail u otro, sin Google Cloud).
--
-- Cómo aplicarla (sobre la base que ya usa la app):
--   MySQL Workbench: doble clic en tu base (servicios_app o defaultdb en Aiven)
--   para que quede en negritas > File > Open SQL Script... > este archivo > rayo.
--   Terminal: mysql -u USUARIO -p NOMBRE_BASE < sql/004_telefono_codigos.sql
--
-- Es re-ejecutable.
--
-- Qué cambia:
--   usuarios.correo pasa a ser opcional (una cuenta puede tener solo teléfono).
--   Tabla codigos_verificacion: códigos de 6 dígitos enviados por correo.
--   Procedimientos: buscar por teléfono, códigos, cambiar contraseña y correo.
-- =====================================================================

-- 1. El correo deja de ser obligatorio (sigue siendo único).
ALTER TABLE `usuarios` MODIFY `correo` VARCHAR(150) NULL;

-- 2. Códigos de verificación (solo se guarda un hash, nunca el código).
CREATE TABLE IF NOT EXISTS `codigos_verificacion` (
  `id_codigo` int NOT NULL AUTO_INCREMENT,
  `destino` varchar(150) NOT NULL,
  `proposito` enum('restablecer','acceso') NOT NULL,
  `codigo_hash` char(64) NOT NULL,
  `intentos` tinyint NOT NULL DEFAULT '0',
  `usado` tinyint(1) NOT NULL DEFAULT '0',
  `expira` datetime NOT NULL,
  `fecha_creacion` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_codigo`),
  KEY `idx_codigos_destino` (`destino`, `proposito`, `fecha_creacion`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

DELIMITER $$

-- ---------------------------------------------------------------------
-- 3. Login con teléfono
-- ---------------------------------------------------------------------
-- Compara los últimos 10 dígitos, así coincide aunque se haya guardado
-- con espacios, guiones o +52. Mismas columnas que sp_usuario_buscar_por_correo.
DROP PROCEDURE IF EXISTS sp_usuario_buscar_por_telefono $$
CREATE PROCEDURE sp_usuario_buscar_por_telefono(
    IN p_telefono VARCHAR(20)
)
BEGIN
    SELECT u.id_usuario, u.id_rol, u.nombre, u.apellido, u.correo, u.telefono,
           u.contrasena, u.activo, r.nombre_rol
    FROM usuarios u
    JOIN roles r ON u.id_rol = r.id_rol
    WHERE u.telefono IS NOT NULL
      AND RIGHT(REGEXP_REPLACE(u.telefono, '[^0-9]', ''), 10) = p_telefono
    ORDER BY u.id_usuario
    LIMIT 1;
END $$

DROP PROCEDURE IF EXISTS sp_usuario_cambiar_contrasena $$
CREATE PROCEDURE sp_usuario_cambiar_contrasena(
    IN p_id_usuario INT,
    IN p_contrasena VARCHAR(255)
)
BEGIN
    UPDATE usuarios SET contrasena = p_contrasena WHERE id_usuario = p_id_usuario;
    IF ROW_COUNT() = 0 THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Usuario no encontrado.';
    END IF;
END $$

-- Agrega o cambia el correo (ya verificado con un código).
DROP PROCEDURE IF EXISTS sp_usuario_cambiar_correo $$
CREATE PROCEDURE sp_usuario_cambiar_correo(
    IN p_id_usuario INT,
    IN p_correo VARCHAR(150)
)
BEGIN
    IF EXISTS (SELECT 1 FROM usuarios WHERE correo = p_correo AND id_usuario <> p_id_usuario) THEN
        SIGNAL SQLSTATE '45409' SET MESSAGE_TEXT = 'Ese correo ya está en uso en otra cuenta.';
    END IF;
    UPDATE usuarios SET correo = p_correo WHERE id_usuario = p_id_usuario;
    CALL sp_usuario_obtener_por_id(p_id_usuario);
END $$

-- ---------------------------------------------------------------------
-- 4. Códigos por correo
-- ---------------------------------------------------------------------
-- Crea un código nuevo e invalida los anteriores del mismo correo y propósito.
-- Límite: uno cada 45 segundos y 5 por cada 15 minutos.
DROP PROCEDURE IF EXISTS sp_codigo_crear $$
CREATE PROCEDURE sp_codigo_crear(
    IN p_destino VARCHAR(150),
    IN p_proposito VARCHAR(20),
    IN p_codigo_hash CHAR(64),
    IN p_minutos INT
)
BEGIN
    DECLARE v_recientes INT DEFAULT 0;
    DECLARE v_ultimo DATETIME DEFAULT NULL;

    SELECT COUNT(*), MAX(fecha_creacion) INTO v_recientes, v_ultimo
    FROM codigos_verificacion
    WHERE destino = p_destino AND proposito = p_proposito
      AND fecha_creacion > NOW() - INTERVAL 15 MINUTE;

    IF v_ultimo IS NOT NULL AND v_ultimo > NOW() - INTERVAL 45 SECOND THEN
        SIGNAL SQLSTATE '45429' SET MESSAGE_TEXT = 'Espera unos segundos antes de pedir otro código.';
    END IF;
    IF v_recientes >= 5 THEN
        SIGNAL SQLSTATE '45429' SET MESSAGE_TEXT = 'Pediste demasiados códigos. Intenta de nuevo en 15 minutos.';
    END IF;

    UPDATE codigos_verificacion SET usado = 1
    WHERE destino = p_destino AND proposito = p_proposito AND usado = 0;

    INSERT INTO codigos_verificacion (destino, proposito, codigo_hash, expira)
    VALUES (p_destino, p_proposito, p_codigo_hash, NOW() + INTERVAL p_minutos MINUTE);

    -- Limpieza de códigos viejos.
    DELETE FROM codigos_verificacion WHERE fecha_creacion < NOW() - INTERVAL 2 DAY;
END $$

-- Código vigente (sin usar y sin vencer) más reciente.
DROP PROCEDURE IF EXISTS sp_codigo_obtener_vigente $$
CREATE PROCEDURE sp_codigo_obtener_vigente(
    IN p_destino VARCHAR(150),
    IN p_proposito VARCHAR(20)
)
BEGIN
    SELECT id_codigo, codigo_hash, intentos
    FROM codigos_verificacion
    WHERE destino = p_destino AND proposito = p_proposito
      AND usado = 0 AND expira > NOW()
    ORDER BY id_codigo DESC
    LIMIT 1;
END $$

DROP PROCEDURE IF EXISTS sp_codigo_registrar_intento $$
CREATE PROCEDURE sp_codigo_registrar_intento(IN p_id_codigo INT)
BEGIN
    UPDATE codigos_verificacion SET intentos = intentos + 1 WHERE id_codigo = p_id_codigo;
END $$

DROP PROCEDURE IF EXISTS sp_codigo_marcar_usado $$
CREATE PROCEDURE sp_codigo_marcar_usado(IN p_id_codigo INT)
BEGIN
    UPDATE codigos_verificacion SET usado = 1 WHERE id_codigo = p_id_codigo;
END $$

DELIMITER ;
