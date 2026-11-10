-- =====================================================================
-- Migración 005 — Cambiar la contraseña desde el perfil.
-- Aplícala después de la 004, igual que las anteriores (doble clic en tu
-- base para dejarla en negritas > File > Open SQL Script... > rayo).
-- Es re-ejecutable.
-- =====================================================================

DELIMITER $$

-- Hash de la contraseña de un usuario (solo lo usa el backend para comparar).
DROP PROCEDURE IF EXISTS sp_usuario_obtener_contrasena $$
CREATE PROCEDURE sp_usuario_obtener_contrasena(
    IN p_id_usuario INT
)
BEGIN
    SELECT id_usuario, contrasena FROM usuarios WHERE id_usuario = p_id_usuario;
END $$

DELIMITER ;
