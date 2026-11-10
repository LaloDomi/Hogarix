-- =====================================================================
-- servicios_app — esquema completo (estructura + procedimientos)
-- Generado: 2026-10-11 con mysqldump 8.0.42 sobre MySQL 8.0.42
--
-- Contiene:
--   * CREATE DATABASE / USE servicios_app
--   * Las 21 tablas con sus llaves, índices y restricciones
--   * 50 procedimientos almacenados y la función fn_hay_bloqueo
--   * Datos de catálogo: roles (Cliente, Trabajador) y categorías
--
-- NO contiene datos de usuarios, publicaciones, mensajes ni ningún otro
-- dato de la aplicación.
--
-- Cómo aplicarlo en una base nueva:
--   mysql --comments -u root -p < sql/schema_completo.sql
-- o abrirlo en MySQL Workbench y ejecutar todo el script.
-- (--comments conserva los comentarios dentro de los procedimientos; sin él
-- el cliente mysql los descarta, sin afectar el funcionamiento.)
--
-- Está pensado para una base VACÍA: no borra tablas existentes.
-- En una base que ya tiene las tablas fallará con "table already exists";
-- para una base existente usa las migraciones numeradas de esta carpeta.
--
-- Se quitó el DEFINER de los procedimientos para que se puedan restaurar
-- con cualquier usuario, y los contadores AUTO_INCREMENT para que los ids
-- empiecen desde 1.
-- =====================================================================

-- MySQL dump 10.13  Distrib 8.0.42, for Win64 (x86_64)
--
-- Host: localhost    Database: servicios_app
-- ------------------------------------------------------
-- Server version	8.0.42

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `servicios_app`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `servicios_app` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `servicios_app`;

--
-- Table structure for table `archivos`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `archivos` (
  `id_archivo` int NOT NULL AUTO_INCREMENT,
  `id_usuario` int NOT NULL,
  `ruta` varchar(255) NOT NULL,
  `tipo_mime` varchar(50) NOT NULL,
  `tamano_bytes` int unsigned NOT NULL,
  `fecha_subida` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_archivo`),
  UNIQUE KEY `uq_archivos_ruta` (`ruta`),
  KEY `fk_archivos_usuario` (`id_usuario`),
  CONSTRAINT `fk_archivos_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `bloqueos`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `bloqueos` (
  `id_usuario_bloquea` int NOT NULL,
  `id_usuario_bloqueado` int NOT NULL,
  `fecha_creacion` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_usuario_bloquea`,`id_usuario_bloqueado`),
  KEY `id_usuario_bloqueado` (`id_usuario_bloqueado`),
  CONSTRAINT `bloqueos_ibfk_1` FOREIGN KEY (`id_usuario_bloquea`) REFERENCES `usuarios` (`id_usuario`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `bloqueos_ibfk_2` FOREIGN KEY (`id_usuario_bloqueado`) REFERENCES `usuarios` (`id_usuario`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `categorias`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `categorias` (
  `id_categoria` int NOT NULL AUTO_INCREMENT,
  `nombre_categoria` varchar(100) NOT NULL,
  `descripcion` text,
  PRIMARY KEY (`id_categoria`),
  UNIQUE KEY `nombre_categoria` (`nombre_categoria`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `comentarios`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `comentarios` (
  `id_comentario` int NOT NULL AUTO_INCREMENT,
  `id_publicacion` int NOT NULL,
  `id_usuario` int NOT NULL,
  `contenido` text NOT NULL,
  `fecha_creacion` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_comentario`),
  KEY `id_publicacion` (`id_publicacion`),
  KEY `id_usuario` (`id_usuario`),
  CONSTRAINT `comentarios_ibfk_1` FOREIGN KEY (`id_publicacion`) REFERENCES `publicaciones` (`id_publicacion`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `comentarios_ibfk_2` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `conversaciones`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `conversaciones` (
  `id_conversacion` int NOT NULL AUTO_INCREMENT,
  `id_usuario_1` int NOT NULL,
  `id_usuario_2` int NOT NULL,
  `ultimo_leido_1` bigint NOT NULL DEFAULT '0',
  `ultimo_leido_2` bigint NOT NULL DEFAULT '0',
  `fecha_creacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `fecha_ultimo_mensaje` datetime DEFAULT NULL,
  PRIMARY KEY (`id_conversacion`),
  UNIQUE KEY `uq_conversaciones_par` (`id_usuario_1`,`id_usuario_2`),
  KEY `ix_conversaciones_u2` (`id_usuario_2`),
  KEY `ix_conversaciones_fecha` (`fecha_ultimo_mensaje`),
  CONSTRAINT `fk_conversaciones_u1` FOREIGN KEY (`id_usuario_1`) REFERENCES `usuarios` (`id_usuario`),
  CONSTRAINT `fk_conversaciones_u2` FOREIGN KEY (`id_usuario_2`) REFERENCES `usuarios` (`id_usuario`),
  CONSTRAINT `ck_conversaciones_orden` CHECK ((`id_usuario_1` < `id_usuario_2`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `dispositivos_notificacion`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dispositivos_notificacion` (
  `id_dispositivo` int NOT NULL AUTO_INCREMENT,
  `id_usuario` int NOT NULL,
  `token_fcm` varchar(255) NOT NULL,
  `plataforma` enum('Android','iOS') NOT NULL,
  `fecha_registro` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_dispositivo`),
  UNIQUE KEY `uq_token` (`token_fcm`),
  KEY `id_usuario` (`id_usuario`),
  CONSTRAINT `dispositivos_notificacion_ibfk_1` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `eventos_agenda`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `eventos_agenda` (
  `id_evento` int NOT NULL AUTO_INCREMENT,
  `id_usuario` int NOT NULL,
  `titulo` varchar(150) NOT NULL,
  `descripcion` text,
  `fecha_inicio` datetime NOT NULL,
  `fecha_fin` datetime NOT NULL,
  `fecha_creacion` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_evento`),
  KEY `idx_eventos_agenda_usuario_rango` (`id_usuario`,`fecha_inicio`,`fecha_fin`),
  CONSTRAINT `eventos_agenda_ibfk_1` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chk_evento_fechas` CHECK ((`fecha_fin` > `fecha_inicio`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `favoritos`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `favoritos` (
  `id_cliente` int NOT NULL,
  `id_trabajador` int NOT NULL,
  `fecha_creacion` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_cliente`,`id_trabajador`),
  KEY `id_trabajador` (`id_trabajador`),
  CONSTRAINT `favoritos_ibfk_1` FOREIGN KEY (`id_cliente`) REFERENCES `usuarios` (`id_usuario`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `favoritos_ibfk_2` FOREIGN KEY (`id_trabajador`) REFERENCES `usuarios` (`id_usuario`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `imagenes_portafolio`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `imagenes_portafolio` (
  `id_imagen` int NOT NULL AUTO_INCREMENT,
  `id_perfil` int NOT NULL,
  `url_imagen` varchar(255) NOT NULL,
  `descripcion` varchar(255) DEFAULT NULL,
  `fecha_creacion` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_imagen`),
  KEY `id_perfil` (`id_perfil`),
  CONSTRAINT `imagenes_portafolio_ibfk_1` FOREIGN KEY (`id_perfil`) REFERENCES `perfiles_trabajador` (`id_perfil`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `imagenes_publicacion`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `imagenes_publicacion` (
  `id_imagen` int NOT NULL AUTO_INCREMENT,
  `id_publicacion` int NOT NULL,
  `url_imagen` varchar(255) NOT NULL,
  PRIMARY KEY (`id_imagen`),
  KEY `id_publicacion` (`id_publicacion`),
  CONSTRAINT `imagenes_publicacion_ibfk_1` FOREIGN KEY (`id_publicacion`) REFERENCES `publicaciones` (`id_publicacion`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `likes_publicacion`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `likes_publicacion` (
  `id_publicacion` int NOT NULL,
  `id_usuario` int NOT NULL,
  `fecha_creacion` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_publicacion`,`id_usuario`),
  KEY `id_usuario` (`id_usuario`),
  CONSTRAINT `likes_publicacion_ibfk_1` FOREIGN KEY (`id_publicacion`) REFERENCES `publicaciones` (`id_publicacion`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `likes_publicacion_ibfk_2` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `mensajes`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `mensajes` (
  `id_mensaje` bigint NOT NULL AUTO_INCREMENT,
  `id_conversacion` int NOT NULL,
  `id_remitente` int NOT NULL,
  `contenido` varchar(2000) DEFAULT NULL,
  `url_imagen` varchar(255) DEFAULT NULL,
  `fecha_envio` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_mensaje`),
  KEY `fk_mensajes_remitente` (`id_remitente`),
  KEY `ix_mensajes_conversacion` (`id_conversacion`,`id_mensaje`),
  CONSTRAINT `fk_mensajes_conversacion` FOREIGN KEY (`id_conversacion`) REFERENCES `conversaciones` (`id_conversacion`),
  CONSTRAINT `fk_mensajes_remitente` FOREIGN KEY (`id_remitente`) REFERENCES `usuarios` (`id_usuario`),
  CONSTRAINT `ck_mensajes_contenido` CHECK (((`contenido` is not null) or (`url_imagen` is not null)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `notificaciones`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notificaciones` (
  `id_notificacion` bigint NOT NULL AUTO_INCREMENT,
  `id_usuario` int NOT NULL,
  `tipo` varchar(30) NOT NULL,
  `titulo` varchar(120) NOT NULL,
  `cuerpo` varchar(255) DEFAULT NULL,
  `id_referencia` int DEFAULT NULL,
  `leida` tinyint(1) NOT NULL DEFAULT '0',
  `fecha_creacion` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_notificacion`),
  KEY `ix_notificaciones_usuario` (`id_usuario`,`leida`,`id_notificacion`),
  CONSTRAINT `fk_notificaciones_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `perfiles_trabajador`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `perfiles_trabajador` (
  `id_perfil` int NOT NULL AUTO_INCREMENT,
  `id_usuario` int NOT NULL,
  `biografia` text,
  `disponible` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id_perfil`),
  UNIQUE KEY `id_usuario` (`id_usuario`),
  CONSTRAINT `perfiles_trabajador_ibfk_1` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `publicaciones`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `publicaciones` (
  `id_publicacion` int NOT NULL AUTO_INCREMENT,
  `id_usuario` int NOT NULL,
  `titulo` varchar(150) NOT NULL,
  `contenido` text NOT NULL,
  `fecha_creacion` datetime DEFAULT CURRENT_TIMESTAMP,
  `activo` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id_publicacion`),
  KEY `id_usuario` (`id_usuario`),
  CONSTRAINT `publicaciones_ibfk_1` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `reportes`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `reportes` (
  `id_reporte` int NOT NULL AUTO_INCREMENT,
  `id_usuario_reporta` int NOT NULL,
  `id_usuario_reportado` int DEFAULT NULL,
  `id_publicacion` int DEFAULT NULL,
  `motivo` varchar(255) NOT NULL,
  `detalle` text,
  `estado` enum('Pendiente','Revisado','Descartado') DEFAULT 'Pendiente',
  `fecha_creacion` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_reporte`),
  KEY `id_usuario_reporta` (`id_usuario_reporta`),
  KEY `id_usuario_reportado` (`id_usuario_reportado`),
  KEY `id_publicacion` (`id_publicacion`),
  CONSTRAINT `reportes_ibfk_1` FOREIGN KEY (`id_usuario_reporta`) REFERENCES `usuarios` (`id_usuario`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `reportes_ibfk_2` FOREIGN KEY (`id_usuario_reportado`) REFERENCES `usuarios` (`id_usuario`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `reportes_ibfk_3` FOREIGN KEY (`id_publicacion`) REFERENCES `publicaciones` (`id_publicacion`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `resenas`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `resenas` (
  `id_resena` int NOT NULL AUTO_INCREMENT,
  `id_solicitud` int NOT NULL,
  `id_autor` int NOT NULL,
  `id_calificado` int NOT NULL,
  `calificacion` tinyint NOT NULL,
  `comentario` text,
  `fecha_creacion` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_resena`),
  UNIQUE KEY `uq_resena_por_solicitud` (`id_solicitud`,`id_autor`),
  KEY `id_autor` (`id_autor`),
  KEY `id_calificado` (`id_calificado`),
  CONSTRAINT `resenas_ibfk_1` FOREIGN KEY (`id_solicitud`) REFERENCES `solicitudes_trabajo` (`id_solicitud`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `resenas_ibfk_2` FOREIGN KEY (`id_autor`) REFERENCES `usuarios` (`id_usuario`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `resenas_ibfk_3` FOREIGN KEY (`id_calificado`) REFERENCES `usuarios` (`id_usuario`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chk_calificacion` CHECK ((`calificacion` between 1 and 5))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `roles`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `roles` (
  `id_rol` int NOT NULL AUTO_INCREMENT,
  `nombre_rol` varchar(50) NOT NULL,
  PRIMARY KEY (`id_rol`),
  UNIQUE KEY `nombre_rol` (`nombre_rol`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `servicios_trabajador`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `servicios_trabajador` (
  `id_servicio` int NOT NULL AUTO_INCREMENT,
  `id_perfil` int NOT NULL,
  `id_categoria` int NOT NULL,
  `tipo_pago` enum('Día','Destajo','Por trabajo','Por hora') NOT NULL,
  `precio_base` decimal(10,2) DEFAULT NULL,
  `descripcion_servicio` text,
  PRIMARY KEY (`id_servicio`),
  KEY `id_perfil` (`id_perfil`),
  KEY `id_categoria` (`id_categoria`),
  CONSTRAINT `servicios_trabajador_ibfk_1` FOREIGN KEY (`id_perfil`) REFERENCES `perfiles_trabajador` (`id_perfil`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `servicios_trabajador_ibfk_2` FOREIGN KEY (`id_categoria`) REFERENCES `categorias` (`id_categoria`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `solicitudes_trabajo`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `solicitudes_trabajo` (
  `id_solicitud` int NOT NULL AUTO_INCREMENT,
  `id_cliente` int NOT NULL,
  `id_trabajador` int NOT NULL,
  `id_categoria` int NOT NULL,
  `tipo_pago_acordado` enum('Día','Destajo','Por trabajo','Por hora') NOT NULL,
  `monto_estimado` decimal(10,2) DEFAULT NULL,
  `estado` enum('Pendiente','Aceptado','Rechazado','Completado','Cancelado') DEFAULT 'Pendiente',
  `fecha_solicitud` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_solicitud`),
  KEY `id_cliente` (`id_cliente`),
  KEY `id_trabajador` (`id_trabajador`),
  KEY `id_categoria` (`id_categoria`),
  CONSTRAINT `solicitudes_trabajo_ibfk_1` FOREIGN KEY (`id_cliente`) REFERENCES `usuarios` (`id_usuario`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `solicitudes_trabajo_ibfk_2` FOREIGN KEY (`id_trabajador`) REFERENCES `usuarios` (`id_usuario`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `solicitudes_trabajo_ibfk_3` FOREIGN KEY (`id_categoria`) REFERENCES `categorias` (`id_categoria`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `usuarios`
--

/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `usuarios` (
  `id_usuario` int NOT NULL AUTO_INCREMENT,
  `id_rol` int NOT NULL,
  `nombre` varchar(100) NOT NULL,
  `apellido` varchar(100) NOT NULL,
  `correo` varchar(150) NOT NULL,
  `contrasena` varchar(255) NOT NULL,
  `telefono` varchar(20) DEFAULT NULL,
  `foto_perfil` varchar(255) DEFAULT NULL,
  `fecha_registro` datetime DEFAULT CURRENT_TIMESTAMP,
  `activo` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`id_usuario`),
  UNIQUE KEY `correo` (`correo`),
  KEY `id_rol` (`id_rol`),
  CONSTRAINT `usuarios_ibfk_1` FOREIGN KEY (`id_rol`) REFERENCES `roles` (`id_rol`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping events for database 'servicios_app'
--

--
-- Dumping routines for database 'servicios_app'
--
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE FUNCTION `fn_hay_bloqueo`(p_usuario_a INT, p_usuario_b INT) RETURNS tinyint
    READS SQL DATA
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM bloqueos
        WHERE (id_usuario_bloquea = p_usuario_a AND id_usuario_bloqueado = p_usuario_b)
           OR (id_usuario_bloquea = p_usuario_b AND id_usuario_bloqueado = p_usuario_a)
    );
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_archivo_registrar`(
    IN p_id_usuario INT,
    IN p_ruta VARCHAR(255),
    IN p_tipo_mime VARCHAR(50),
    IN p_tamano_bytes INT UNSIGNED
)
BEGIN
    INSERT INTO archivos (id_usuario, ruta, tipo_mime, tamano_bytes)
    VALUES (p_id_usuario, p_ruta, p_tipo_mime, p_tamano_bytes);

    SELECT LAST_INSERT_ID() AS id_archivo;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_bloqueos_listar`(IN p_id_usuario INT)
BEGIN
    SELECT u.id_usuario, u.nombre, u.apellido, u.foto_perfil, b.fecha_creacion
    FROM bloqueos b
    JOIN usuarios u ON u.id_usuario = b.id_usuario_bloqueado
    WHERE b.id_usuario_bloquea = p_id_usuario
    ORDER BY b.fecha_creacion DESC;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_bloqueo_agregar`(
    IN p_id_usuario INT,
    IN p_id_bloqueado INT
)
BEGIN
    IF p_id_usuario = p_id_bloqueado THEN
        SIGNAL SQLSTATE '45400' SET MESSAGE_TEXT = 'No puedes bloquearte a ti mismo.';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM usuarios WHERE id_usuario = p_id_bloqueado) THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Usuario no encontrado.';
    END IF;

    INSERT IGNORE INTO bloqueos (id_usuario_bloquea, id_usuario_bloqueado) VALUES (p_id_usuario, p_id_bloqueado);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_bloqueo_quitar`(
    IN p_id_usuario INT,
    IN p_id_bloqueado INT
)
BEGIN
    DELETE FROM bloqueos WHERE id_usuario_bloquea = p_id_usuario AND id_usuario_bloqueado = p_id_bloqueado;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_categorias_listar`()
BEGIN
    SELECT id_categoria, nombre_categoria, descripcion
    FROM categorias
    ORDER BY nombre_categoria;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_comentarios_listar`(
    IN p_id_publicacion INT,
    IN p_id_usuario_actual INT,
    IN p_limite INT,
    IN p_offset INT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM publicaciones WHERE id_publicacion = p_id_publicacion AND activo = TRUE) THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Publicación no encontrada.';
    END IF;

    SELECT c.id_comentario, c.contenido, c.fecha_creacion,
           u.id_usuario, u.nombre, u.apellido, u.foto_perfil
    FROM comentarios c
    JOIN usuarios u ON u.id_usuario = c.id_usuario
    WHERE c.id_publicacion = p_id_publicacion
      AND u.activo = TRUE
      AND NOT EXISTS (
          SELECT 1 FROM bloqueos b
          WHERE (b.id_usuario_bloquea = p_id_usuario_actual AND b.id_usuario_bloqueado = c.id_usuario)
             OR (b.id_usuario_bloquea = c.id_usuario AND b.id_usuario_bloqueado = p_id_usuario_actual)
      )
    ORDER BY c.fecha_creacion ASC, c.id_comentario ASC
    LIMIT p_limite OFFSET p_offset;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_comentario_crear`(
    IN p_id_usuario INT,
    IN p_id_publicacion INT,
    IN p_contenido TEXT
)
BEGIN
    DECLARE v_autor INT;

    SELECT id_usuario INTO v_autor FROM publicaciones WHERE id_publicacion = p_id_publicacion AND activo = TRUE;
    IF v_autor IS NULL THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Publicación no encontrada.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM bloqueos
        WHERE (id_usuario_bloquea = p_id_usuario AND id_usuario_bloqueado = v_autor)
           OR (id_usuario_bloquea = v_autor AND id_usuario_bloqueado = p_id_usuario)
    ) THEN
        SIGNAL SQLSTATE '45403' SET MESSAGE_TEXT = 'No puedes interactuar con este usuario.';
    END IF;

    INSERT INTO comentarios (id_publicacion, id_usuario, contenido)
    VALUES (p_id_publicacion, p_id_usuario, p_contenido);

    SELECT LAST_INSERT_ID() AS id_comentario;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_comentario_eliminar`(
    IN p_id_usuario INT,
    IN p_id_publicacion INT,
    IN p_id_comentario INT
)
BEGIN
    DECLARE v_autor_comentario INT;
    DECLARE v_autor_publicacion INT;

    SELECT c.id_usuario, p.id_usuario INTO v_autor_comentario, v_autor_publicacion
    FROM comentarios c
    JOIN publicaciones p ON p.id_publicacion = c.id_publicacion
    WHERE c.id_comentario = p_id_comentario AND c.id_publicacion = p_id_publicacion;

    IF v_autor_comentario IS NULL THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Comentario no encontrado.';
    END IF;
    IF p_id_usuario NOT IN (v_autor_comentario, v_autor_publicacion) THEN
        SIGNAL SQLSTATE '45403' SET MESSAGE_TEXT = 'No puedes eliminar este comentario.';
    END IF;

    DELETE FROM comentarios WHERE id_comentario = p_id_comentario;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_conversaciones_listar`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_conversacion_marcar_leida`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_conversacion_obtener_o_crear`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_conversacion_verificar_acceso`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_dispositivo_eliminar`(
    IN p_id_usuario INT,
    IN p_token_fcm VARCHAR(255)
)
BEGIN
    DELETE FROM dispositivos_notificacion WHERE id_usuario = p_id_usuario AND token_fcm = p_token_fcm;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_dispositivo_registrar`(
    IN p_id_usuario INT,
    IN p_token_fcm VARCHAR(255),
    IN p_plataforma VARCHAR(10)
)
BEGIN
    INSERT INTO dispositivos_notificacion (id_usuario, token_fcm, plataforma)
    VALUES (p_id_usuario, p_token_fcm, p_plataforma)
    ON DUPLICATE KEY UPDATE id_usuario = p_id_usuario, plataforma = p_plataforma;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_evento_actualizar`(
    IN p_id_usuario INT,
    IN p_id_evento INT,
    IN p_titulo VARCHAR(150),
    IN p_descripcion TEXT,
    IN p_fecha_inicio DATETIME,
    IN p_fecha_fin DATETIME
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM eventos_agenda WHERE id_evento = p_id_evento AND id_usuario = p_id_usuario) THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Evento no encontrado.';
    END IF;
    IF p_fecha_fin <= p_fecha_inicio THEN
        SIGNAL SQLSTATE '45400' SET MESSAGE_TEXT = 'fecha_fin debe ser posterior a fecha_inicio.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM eventos_agenda
        WHERE id_usuario = p_id_usuario
          AND id_evento <> p_id_evento
          AND fecha_inicio < p_fecha_fin
          AND fecha_fin > p_fecha_inicio
    ) THEN
        SIGNAL SQLSTATE '45409' SET MESSAGE_TEXT = 'Ya tienes un evento que se traslapa en ese horario.';
    END IF;

    UPDATE eventos_agenda
    SET titulo = p_titulo, descripcion = p_descripcion, fecha_inicio = p_fecha_inicio, fecha_fin = p_fecha_fin
    WHERE id_evento = p_id_evento;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_evento_crear`(
    IN p_id_usuario INT,
    IN p_titulo VARCHAR(150),
    IN p_descripcion TEXT,
    IN p_fecha_inicio DATETIME,
    IN p_fecha_fin DATETIME
)
BEGIN
    IF p_fecha_fin <= p_fecha_inicio THEN
        SIGNAL SQLSTATE '45400' SET MESSAGE_TEXT = 'fecha_fin debe ser posterior a fecha_inicio.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM eventos_agenda
        WHERE id_usuario = p_id_usuario
          AND fecha_inicio < p_fecha_fin
          AND fecha_fin > p_fecha_inicio
    ) THEN
        SIGNAL SQLSTATE '45409' SET MESSAGE_TEXT = 'Ya tienes un evento que se traslapa en ese horario.';
    END IF;

    INSERT INTO eventos_agenda (id_usuario, titulo, descripcion, fecha_inicio, fecha_fin)
    VALUES (p_id_usuario, p_titulo, p_descripcion, p_fecha_inicio, p_fecha_fin);

    SELECT LAST_INSERT_ID() AS id_evento;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_evento_eliminar`(
    IN p_id_usuario INT,
    IN p_id_evento INT
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM eventos_agenda WHERE id_evento = p_id_evento AND id_usuario = p_id_usuario) THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Evento no encontrado.';
    END IF;

    DELETE FROM eventos_agenda WHERE id_evento = p_id_evento;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_evento_listar`(
    IN p_id_usuario INT,
    IN p_desde DATETIME,
    IN p_hasta DATETIME
)
BEGIN
    SELECT id_evento, titulo, descripcion, fecha_inicio, fecha_fin, fecha_creacion
    FROM eventos_agenda
    WHERE id_usuario = p_id_usuario
      AND fecha_inicio < p_hasta
      AND fecha_fin > p_desde
    ORDER BY fecha_inicio ASC;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_favoritos_listar`(IN p_id_cliente INT)
BEGIN
    SELECT u.id_usuario, u.nombre, u.apellido, u.foto_perfil,
           pt.biografia, pt.disponible,
           (SELECT ROUND(AVG(r.calificacion), 2) FROM resenas r WHERE r.id_calificado = u.id_usuario) AS calificacion_promedio,
           f.fecha_creacion AS fecha_favorito
    FROM favoritos f
    JOIN usuarios u ON u.id_usuario = f.id_trabajador
    JOIN perfiles_trabajador pt ON pt.id_usuario = u.id_usuario
    WHERE f.id_cliente = p_id_cliente AND u.activo = TRUE
    ORDER BY f.fecha_creacion DESC;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_favorito_agregar`(
    IN p_id_cliente INT,
    IN p_id_trabajador INT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM perfiles_trabajador pt
        JOIN usuarios u ON u.id_usuario = pt.id_usuario
        WHERE pt.id_usuario = p_id_trabajador AND u.activo = TRUE
    ) THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Trabajador no encontrado.';
    END IF;

    INSERT IGNORE INTO favoritos (id_cliente, id_trabajador) VALUES (p_id_cliente, p_id_trabajador);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_favorito_quitar`(
    IN p_id_cliente INT,
    IN p_id_trabajador INT
)
BEGIN
    DELETE FROM favoritos WHERE id_cliente = p_id_cliente AND id_trabajador = p_id_trabajador;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_like_agregar`(
    IN p_id_usuario INT,
    IN p_id_publicacion INT
)
BEGIN
    DECLARE v_autor INT;

    SELECT id_usuario INTO v_autor FROM publicaciones WHERE id_publicacion = p_id_publicacion AND activo = TRUE;
    IF v_autor IS NULL THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Publicación no encontrada.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM bloqueos
        WHERE (id_usuario_bloquea = p_id_usuario AND id_usuario_bloqueado = v_autor)
           OR (id_usuario_bloquea = v_autor AND id_usuario_bloqueado = p_id_usuario)
    ) THEN
        SIGNAL SQLSTATE '45403' SET MESSAGE_TEXT = 'No puedes interactuar con este usuario.';
    END IF;

    INSERT IGNORE INTO likes_publicacion (id_publicacion, id_usuario)
    VALUES (p_id_publicacion, p_id_usuario);

    SELECT COUNT(*) AS total_likes FROM likes_publicacion WHERE id_publicacion = p_id_publicacion;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_like_quitar`(
    IN p_id_usuario INT,
    IN p_id_publicacion INT
)
BEGIN
    DELETE FROM likes_publicacion WHERE id_publicacion = p_id_publicacion AND id_usuario = p_id_usuario;

    SELECT COUNT(*) AS total_likes FROM likes_publicacion WHERE id_publicacion = p_id_publicacion;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_mensajes_contar_no_leidos`(IN p_id_usuario INT)
BEGIN
    SELECT COUNT(*) AS total
    FROM conversaciones c
    JOIN mensajes m ON m.id_conversacion = c.id_conversacion
    WHERE (c.id_usuario_1 = p_id_usuario OR c.id_usuario_2 = p_id_usuario)
      AND m.id_remitente <> p_id_usuario
      AND m.id_mensaje > IF(c.id_usuario_1 = p_id_usuario, c.ultimo_leido_1, c.ultimo_leido_2)
      AND NOT fn_hay_bloqueo(c.id_usuario_1, c.id_usuario_2);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_mensajes_listar`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_mensaje_enviar`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_notificaciones_contar_no_leidas`(IN p_id_usuario INT)
BEGIN
    SELECT COUNT(*) AS total
    FROM notificaciones
    WHERE id_usuario = p_id_usuario AND leida = FALSE;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_notificaciones_listar`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_notificaciones_marcar_todas_leidas`(IN p_id_usuario INT)
BEGIN
    UPDATE notificaciones SET leida = TRUE
    WHERE id_usuario = p_id_usuario AND leida = FALSE;

    SELECT ROW_COUNT() AS actualizadas;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_notificacion_crear`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_notificacion_marcar_leida`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_publicaciones_listar`(
    IN p_id_usuario_actual INT,
    IN p_id_autor INT,
    IN p_id_publicacion INT,
    IN p_limite INT,
    IN p_offset INT
)
BEGIN
    SELECT p.id_publicacion, p.titulo, p.contenido, p.fecha_creacion,
           u.id_usuario AS id_autor, u.nombre, u.apellido, u.foto_perfil, ro.nombre_rol AS rol_autor,
           (SELECT COUNT(*) FROM likes_publicacion l WHERE l.id_publicacion = p.id_publicacion) AS total_likes,
           (SELECT COUNT(*) FROM comentarios c WHERE c.id_publicacion = p.id_publicacion) AS total_comentarios,
           EXISTS (
               SELECT 1 FROM likes_publicacion l2
               WHERE l2.id_publicacion = p.id_publicacion AND l2.id_usuario = p_id_usuario_actual
           ) AS me_gusta,
           COALESCE(
               (SELECT JSON_ARRAYAGG(ip.url_imagen) FROM imagenes_publicacion ip WHERE ip.id_publicacion = p.id_publicacion),
               JSON_ARRAY()
           ) AS imagenes
    FROM publicaciones p
    JOIN usuarios u ON u.id_usuario = p.id_usuario
    JOIN roles ro ON ro.id_rol = u.id_rol
    WHERE p.activo = TRUE
      AND u.activo = TRUE
      AND (p_id_autor IS NULL OR p.id_usuario = p_id_autor)
      AND (p_id_publicacion IS NULL OR p.id_publicacion = p_id_publicacion)
      AND NOT EXISTS (
          SELECT 1 FROM bloqueos b
          WHERE (b.id_usuario_bloquea = p_id_usuario_actual AND b.id_usuario_bloqueado = p.id_usuario)
             OR (b.id_usuario_bloquea = p.id_usuario AND b.id_usuario_bloqueado = p_id_usuario_actual)
      )
    ORDER BY p.fecha_creacion DESC, p.id_publicacion DESC
    LIMIT p_limite OFFSET p_offset;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_publicacion_agregar_imagen`(
    IN p_id_publicacion INT,
    IN p_url_imagen VARCHAR(255)
)
BEGIN
    INSERT INTO imagenes_publicacion (id_publicacion, url_imagen)
    VALUES (p_id_publicacion, p_url_imagen);
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_publicacion_crear`(
    IN p_id_usuario INT,
    IN p_titulo VARCHAR(150),
    IN p_contenido TEXT
)
BEGIN
    INSERT INTO publicaciones (id_usuario, titulo, contenido)
    VALUES (p_id_usuario, p_titulo, p_contenido);

    SELECT LAST_INSERT_ID() AS id_publicacion;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_publicacion_eliminar`(
    IN p_id_usuario INT,
    IN p_id_publicacion INT
)
BEGIN
    DECLARE v_autor INT;

    SELECT id_usuario INTO v_autor FROM publicaciones WHERE id_publicacion = p_id_publicacion AND activo = TRUE;
    IF v_autor IS NULL THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Publicación no encontrada.';
    END IF;
    IF v_autor <> p_id_usuario THEN
        SIGNAL SQLSTATE '45403' SET MESSAGE_TEXT = 'Solo puedes eliminar tus propias publicaciones.';
    END IF;

    UPDATE publicaciones SET activo = FALSE WHERE id_publicacion = p_id_publicacion;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_reporte_crear`(
    IN p_id_usuario_reporta INT,
    IN p_id_usuario_reportado INT,
    IN p_id_publicacion INT,
    IN p_motivo VARCHAR(255),
    IN p_detalle TEXT
)
BEGIN
    IF p_id_usuario_reportado IS NULL AND p_id_publicacion IS NULL THEN
        SIGNAL SQLSTATE '45400' SET MESSAGE_TEXT = 'Indica un usuario o una publicación a reportar.';
    END IF;
    IF p_id_usuario_reportado = p_id_usuario_reporta THEN
        SIGNAL SQLSTATE '45400' SET MESSAGE_TEXT = 'No puedes reportarte a ti mismo.';
    END IF;
    IF p_id_usuario_reportado IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM usuarios WHERE id_usuario = p_id_usuario_reportado) THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Usuario no encontrado.';
    END IF;
    IF p_id_publicacion IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM publicaciones WHERE id_publicacion = p_id_publicacion) THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Publicación no encontrada.';
    END IF;

    INSERT INTO reportes (id_usuario_reporta, id_usuario_reportado, id_publicacion, motivo, detalle)
    VALUES (p_id_usuario_reporta, p_id_usuario_reportado, p_id_publicacion, p_motivo, p_detalle);

    SELECT LAST_INSERT_ID() AS id_reporte;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_resenas_listar_usuario`(
    IN p_id_usuario INT,
    IN p_limite INT,
    IN p_offset INT
)
BEGIN
    SELECT r.id_resena, r.calificacion, r.comentario, r.fecha_creacion,
           u.id_usuario AS id_autor, u.nombre, u.apellido, u.foto_perfil
    FROM resenas r
    JOIN usuarios u ON u.id_usuario = r.id_autor
    WHERE r.id_calificado = p_id_usuario
    ORDER BY r.fecha_creacion DESC, r.id_resena DESC
    LIMIT p_limite OFFSET p_offset;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_resena_crear`(
    IN p_id_autor INT,
    IN p_id_solicitud INT,
    IN p_calificacion INT,
    IN p_comentario TEXT
)
BEGIN
    DECLARE v_cliente INT;
    DECLARE v_trabajador INT;
    DECLARE v_estado VARCHAR(20);
    DECLARE v_calificado INT;

    IF p_calificacion IS NULL OR p_calificacion < 1 OR p_calificacion > 5 THEN
        SIGNAL SQLSTATE '45400' SET MESSAGE_TEXT = 'La calificación debe estar entre 1 y 5.';
    END IF;

    SELECT id_cliente, id_trabajador, estado INTO v_cliente, v_trabajador, v_estado
    FROM solicitudes_trabajo
    WHERE id_solicitud = p_id_solicitud;

    IF v_cliente IS NULL THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Solicitud no encontrada.';
    END IF;
    IF p_id_autor NOT IN (v_cliente, v_trabajador) THEN
        SIGNAL SQLSTATE '45403' SET MESSAGE_TEXT = 'No participas en esta solicitud.';
    END IF;
    IF v_estado <> 'Completado' THEN
        SIGNAL SQLSTATE '45400' SET MESSAGE_TEXT = 'Solo puedes calificar solicitudes completadas.';
    END IF;
    IF EXISTS (SELECT 1 FROM resenas WHERE id_solicitud = p_id_solicitud AND id_autor = p_id_autor) THEN
        SIGNAL SQLSTATE '45409' SET MESSAGE_TEXT = 'Ya calificaste esta solicitud.';
    END IF;

    SET v_calificado = IF(p_id_autor = v_cliente, v_trabajador, v_cliente);

    INSERT INTO resenas (id_solicitud, id_autor, id_calificado, calificacion, comentario)
    VALUES (p_id_solicitud, p_id_autor, v_calificado, p_calificacion, p_comentario);

    SELECT LAST_INSERT_ID() AS id_resena;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_unicode_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'IGNORE_SPACE,ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_servicios_buscar`(
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_servicio_actualizar`(
    IN p_id_usuario INT,
    IN p_id_servicio INT,
    IN p_id_categoria INT,
    IN p_tipo_pago VARCHAR(20),
    IN p_precio_base DECIMAL(10,2),
    IN p_descripcion_servicio TEXT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM servicios_trabajador st
        JOIN perfiles_trabajador pt ON pt.id_perfil = st.id_perfil
        WHERE st.id_servicio = p_id_servicio AND pt.id_usuario = p_id_usuario
    ) THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Servicio no encontrado.';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM categorias WHERE id_categoria = p_id_categoria) THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Categoría no encontrada.';
    END IF;

    UPDATE servicios_trabajador
    SET id_categoria = p_id_categoria,
        tipo_pago = p_tipo_pago,
        precio_base = p_precio_base,
        descripcion_servicio = p_descripcion_servicio
    WHERE id_servicio = p_id_servicio;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_servicio_crear`(
    IN p_id_usuario INT,
    IN p_id_categoria INT,
    IN p_tipo_pago VARCHAR(20),
    IN p_precio_base DECIMAL(10,2),
    IN p_descripcion_servicio TEXT
)
BEGIN
    DECLARE v_id_perfil INT;

    SELECT id_perfil INTO v_id_perfil FROM perfiles_trabajador WHERE id_usuario = p_id_usuario;
    IF v_id_perfil IS NULL THEN
        SIGNAL SQLSTATE '45403' SET MESSAGE_TEXT = 'Solo los trabajadores pueden ofrecer servicios.';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM categorias WHERE id_categoria = p_id_categoria) THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Categoría no encontrada.';
    END IF;

    INSERT INTO servicios_trabajador (id_perfil, id_categoria, tipo_pago, precio_base, descripcion_servicio)
    VALUES (v_id_perfil, p_id_categoria, p_tipo_pago, p_precio_base, p_descripcion_servicio);

    SELECT LAST_INSERT_ID() AS id_servicio;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_servicio_eliminar`(
    IN p_id_usuario INT,
    IN p_id_servicio INT
)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM servicios_trabajador st
        JOIN perfiles_trabajador pt ON pt.id_perfil = st.id_perfil
        WHERE st.id_servicio = p_id_servicio AND pt.id_usuario = p_id_usuario
    ) THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Servicio no encontrado.';
    END IF;

    DELETE FROM servicios_trabajador WHERE id_servicio = p_id_servicio;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_solicitud_cambiar_estado`(
    IN p_id_usuario INT,
    IN p_id_solicitud INT,
    IN p_nuevo_estado VARCHAR(20)
)
BEGIN
    DECLARE v_cliente INT;
    DECLARE v_trabajador INT;
    DECLARE v_estado VARCHAR(20);

    SELECT id_cliente, id_trabajador, estado INTO v_cliente, v_trabajador, v_estado
    FROM solicitudes_trabajo
    WHERE id_solicitud = p_id_solicitud;

    IF v_cliente IS NULL THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Solicitud no encontrada.';
    END IF;
    IF p_id_usuario NOT IN (v_cliente, v_trabajador) THEN
        SIGNAL SQLSTATE '45403' SET MESSAGE_TEXT = 'No participas en esta solicitud.';
    END IF;

    IF p_nuevo_estado IN ('Aceptado', 'Rechazado') THEN
        IF p_id_usuario <> v_trabajador THEN
            SIGNAL SQLSTATE '45403' SET MESSAGE_TEXT = 'Solo el trabajador puede aceptar o rechazar la solicitud.';
        END IF;
        IF v_estado <> 'Pendiente' THEN
            SIGNAL SQLSTATE '45400' SET MESSAGE_TEXT = 'Solo se pueden aceptar o rechazar solicitudes pendientes.';
        END IF;
    ELSEIF p_nuevo_estado = 'Cancelado' THEN
        IF v_estado NOT IN ('Pendiente', 'Aceptado') THEN
            SIGNAL SQLSTATE '45400' SET MESSAGE_TEXT = 'Solo se pueden cancelar solicitudes pendientes o aceptadas.';
        END IF;
    ELSEIF p_nuevo_estado = 'Completado' THEN
        IF v_estado <> 'Aceptado' THEN
            SIGNAL SQLSTATE '45400' SET MESSAGE_TEXT = 'Solo se pueden completar solicitudes aceptadas.';
        END IF;
    ELSE
        SIGNAL SQLSTATE '45400' SET MESSAGE_TEXT = 'Estado no permitido.';
    END IF;

    UPDATE solicitudes_trabajo SET estado = p_nuevo_estado WHERE id_solicitud = p_id_solicitud;

    SELECT p_id_solicitud AS id_solicitud, p_nuevo_estado AS estado;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_solicitud_crear`(
    IN p_id_cliente INT,
    IN p_id_trabajador INT,
    IN p_id_categoria INT,
    IN p_tipo_pago VARCHAR(20),
    IN p_monto_estimado DECIMAL(10,2)
)
BEGIN
    IF p_id_cliente = p_id_trabajador THEN
        SIGNAL SQLSTATE '45400' SET MESSAGE_TEXT = 'No puedes enviarte una solicitud a ti mismo.';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM perfiles_trabajador pt
        JOIN usuarios u ON u.id_usuario = pt.id_usuario
        WHERE pt.id_usuario = p_id_trabajador AND u.activo = TRUE
    ) THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Trabajador no encontrado.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM bloqueos
        WHERE (id_usuario_bloquea = p_id_cliente AND id_usuario_bloqueado = p_id_trabajador)
           OR (id_usuario_bloquea = p_id_trabajador AND id_usuario_bloqueado = p_id_cliente)
    ) THEN
        SIGNAL SQLSTATE '45403' SET MESSAGE_TEXT = 'No puedes interactuar con este usuario.';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM servicios_trabajador st
        JOIN perfiles_trabajador pt ON pt.id_perfil = st.id_perfil
        WHERE pt.id_usuario = p_id_trabajador AND st.id_categoria = p_id_categoria
    ) THEN
        SIGNAL SQLSTATE '45400' SET MESSAGE_TEXT = 'El trabajador no ofrece servicios en esa categoría.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM solicitudes_trabajo
        WHERE id_cliente = p_id_cliente AND id_trabajador = p_id_trabajador
          AND id_categoria = p_id_categoria AND estado = 'Pendiente'
    ) THEN
        SIGNAL SQLSTATE '45409' SET MESSAGE_TEXT = 'Ya tienes una solicitud pendiente con este trabajador para esa categoría.';
    END IF;

    INSERT INTO solicitudes_trabajo (id_cliente, id_trabajador, id_categoria, tipo_pago_acordado, monto_estimado)
    VALUES (p_id_cliente, p_id_trabajador, p_id_categoria, p_tipo_pago, p_monto_estimado);

    SELECT LAST_INSERT_ID() AS id_solicitud;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_solicitud_listar`(
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
           s.id_trabajador, ut.nombre AS nombre_trabajador, ut.apellido AS apellido_trabajador, ut.foto_perfil AS foto_trabajador,
           EXISTS (
               SELECT 1 FROM resenas r WHERE r.id_solicitud = s.id_solicitud AND r.id_autor = p_id_usuario
           ) AS ya_califique
    FROM solicitudes_trabajo s
    JOIN categorias c ON c.id_categoria = s.id_categoria
    JOIN usuarios uc ON uc.id_usuario = s.id_cliente
    JOIN usuarios ut ON ut.id_usuario = s.id_trabajador
    WHERE (s.id_cliente = p_id_usuario OR s.id_trabajador = p_id_usuario)
      AND (p_id_solicitud IS NULL OR s.id_solicitud = p_id_solicitud)
      AND (p_estado IS NULL OR s.estado = p_estado)
    ORDER BY s.fecha_solicitud DESC, s.id_solicitud DESC
    LIMIT p_limite OFFSET p_offset;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_trabajador_actualizar_perfil`(
    IN p_id_usuario INT,
    IN p_biografia TEXT,
    IN p_disponible BOOLEAN
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM perfiles_trabajador WHERE id_usuario = p_id_usuario) THEN
        SIGNAL SQLSTATE '45403' SET MESSAGE_TEXT = 'Solo los trabajadores tienen perfil de trabajador.';
    END IF;

    UPDATE perfiles_trabajador
    SET biografia = COALESCE(p_biografia, biografia),
        disponible = COALESCE(p_disponible, disponible)
    WHERE id_usuario = p_id_usuario;

    SELECT biografia, disponible FROM perfiles_trabajador WHERE id_usuario = p_id_usuario;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_trabajador_obtener_perfil`(IN p_id_usuario INT)
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM perfiles_trabajador pt
        JOIN usuarios u ON u.id_usuario = pt.id_usuario
        WHERE pt.id_usuario = p_id_usuario AND u.activo = TRUE
    ) THEN
        SIGNAL SQLSTATE '45404' SET MESSAGE_TEXT = 'Trabajador no encontrado.';
    END IF;

    SELECT u.id_usuario, u.nombre, u.apellido, u.foto_perfil, u.fecha_registro,
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
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_usuario_buscar_por_correo`(
    IN p_correo VARCHAR(150)
)
BEGIN
    SELECT u.id_usuario, u.id_rol, u.nombre, u.apellido, u.correo, u.contrasena, r.nombre_rol
    FROM usuarios u
    JOIN roles r ON u.id_rol = r.id_rol
    WHERE u.correo = p_correo;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_usuario_crear`(
    IN p_id_rol INT,
    IN p_nombre VARCHAR(100),
    IN p_apellido VARCHAR(100),
    IN p_correo VARCHAR(150),
    IN p_contrasena VARCHAR(255),
    IN p_telefono VARCHAR(20),
    OUT p_id_usuario INT
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    INSERT INTO usuarios (id_rol, nombre, apellido, correo, contrasena, telefono)
    VALUES (p_id_rol, p_nombre, p_apellido, p_correo, p_contrasena, p_telefono);

    SET p_id_usuario = LAST_INSERT_ID();

    IF p_id_rol = 2 THEN
        INSERT INTO perfiles_trabajador (id_usuario, biografia)
        VALUES (p_id_usuario, '');
    END IF;

    COMMIT;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE PROCEDURE `sp_usuario_obtener_por_id`(
    IN p_id_usuario INT
)
BEGIN
    SELECT u.id_usuario, u.nombre, u.apellido, u.correo, u.telefono, u.foto_perfil, u.fecha_registro, r.nombre_rol
    FROM usuarios u
    JOIN roles r ON u.id_rol = r.id_rol
    WHERE u.id_usuario = p_id_usuario;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-11 11:55:04

-- ---------------------------------------------------------------------
-- Datos de catálogo (INSERT IGNORE: se puede re-ejecutar sin duplicar)
-- ---------------------------------------------------------------------
USE `servicios_app`;

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT  IGNORE INTO `roles` (`id_rol`, `nombre_rol`) VALUES (1,'Cliente');
INSERT  IGNORE INTO `roles` (`id_rol`, `nombre_rol`) VALUES (2,'Trabajador');
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;

LOCK TABLES `categorias` WRITE;
/*!40000 ALTER TABLE `categorias` DISABLE KEYS */;
INSERT  IGNORE INTO `categorias` (`id_categoria`, `nombre_categoria`, `descripcion`) VALUES (1,'Carpintería','Muebles, puertas y trabajos en madera');
INSERT  IGNORE INTO `categorias` (`id_categoria`, `nombre_categoria`, `descripcion`) VALUES (2,'Herrería','Portones, rejas y estructuras metálicas');
INSERT  IGNORE INTO `categorias` (`id_categoria`, `nombre_categoria`, `descripcion`) VALUES (3,'Plomería','Instalación y reparación de tuberías');
INSERT  IGNORE INTO `categorias` (`id_categoria`, `nombre_categoria`, `descripcion`) VALUES (4,'Electricidad','Instalaciones y reparaciones eléctricas');
INSERT  IGNORE INTO `categorias` (`id_categoria`, `nombre_categoria`, `descripcion`) VALUES (5,'Albañilería','Construcción y remodelación');
INSERT  IGNORE INTO `categorias` (`id_categoria`, `nombre_categoria`, `descripcion`) VALUES (6,'Pintura','Pintura de interiores y exteriores');
/*!40000 ALTER TABLE `categorias` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

