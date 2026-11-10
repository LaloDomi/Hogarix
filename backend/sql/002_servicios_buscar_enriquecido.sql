-- =====================================================================
-- Migración 002 — Búsqueda de servicios enriquecida
--
-- Cómo aplicarla:
--   mysql -u root -p servicios_app < sql/002_servicios_buscar_enriquecido.sql
-- o abrirla en MySQL Workbench y ejecutar todo el script.
--
-- Es re-ejecutable (DROP PROCEDURE IF EXISTS).
--
-- Cambios respecto a la versión anterior de sp_servicios_buscar:
--   + calificacion_promedio y total_resenas del trabajador
--   + disponible (perfiles_trabajador.disponible)
--   + solo usuarios activos
--   + ordenado: disponibles primero, luego mejor calificados
--   - ya NO devuelve el teléfono (la ruta es pública)
-- =====================================================================

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_servicios_buscar $$
CREATE PROCEDURE sp_servicios_buscar(
    IN p_id_categoria INT,
    IN p_tipo_pago VARCHAR(20)
)
BEGIN
    SELECT st.id_servicio, st.tipo_pago, st.precio_base, st.descripcion_servicio,
           c.nombre_categoria,
           u.id_usuario, u.nombre, u.apellido, u.foto_perfil,
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

DELIMITER ;
