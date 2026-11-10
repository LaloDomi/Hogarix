/// Estados de México y algunas de sus ciudades/municipios principales para
/// sugerir mientras se escribe. El municipio se puede escribir libremente.
/// (Los nombres de los estados coinciden con los que acepta el backend.)
const ubicacionesMx = <String, List<String>>{
  'Aguascalientes': ['Aguascalientes', 'Jesús María', 'Calvillo', 'Rincón de Romos'],
  'Baja California': ['Tijuana', 'Mexicali', 'Ensenada', 'Rosarito', 'Tecate'],
  'Baja California Sur': ['La Paz', 'Los Cabos', 'Comondú', 'Loreto', 'Mulegé'],
  'Campeche': ['Campeche', 'Ciudad del Carmen', 'Champotón', 'Escárcega'],
  'Chiapas': ['Tuxtla Gutiérrez', 'Tapachula', 'San Cristóbal de las Casas', 'Comitán', 'Palenque'],
  'Chihuahua': ['Chihuahua', 'Ciudad Juárez', 'Delicias', 'Cuauhtémoc', 'Parral'],
  'Ciudad de México': [
    'Álvaro Obregón', 'Azcapotzalco', 'Benito Juárez', 'Coyoacán', 'Cuajimalpa',
    'Cuauhtémoc', 'Gustavo A. Madero', 'Iztacalco', 'Iztapalapa', 'Magdalena Contreras',
    'Miguel Hidalgo', 'Milpa Alta', 'Tláhuac', 'Tlalpan', 'Venustiano Carranza', 'Xochimilco',
  ],
  'Coahuila': ['Saltillo', 'Torreón', 'Monclova', 'Piedras Negras', 'Ramos Arizpe'],
  'Colima': ['Colima', 'Manzanillo', 'Villa de Álvarez', 'Tecomán'],
  'Durango': ['Durango', 'Gómez Palacio', 'Lerdo', 'Santiago Papasquiaro'],
  'Estado de México': [
    'Toluca', 'Ecatepec', 'Naucalpan', 'Nezahualcóyotl', 'Tlalnepantla', 'Chimalhuacán',
    'Cuautitlán Izcalli', 'Atizapán de Zaragoza', 'Metepec', 'Texcoco', 'Huixquilucan',
  ],
  'Guanajuato': ['León', 'Irapuato', 'Celaya', 'Salamanca', 'Guanajuato', 'San Miguel de Allende'],
  'Guerrero': ['Acapulco', 'Chilpancingo', 'Iguala', 'Zihuatanejo', 'Taxco'],
  'Hidalgo': ['Pachuca', 'Tulancingo', 'Mineral de la Reforma', 'Tula', 'Tizayuca'],
  'Jalisco': ['Guadalajara', 'Zapopan', 'Tlaquepaque', 'Tonalá', 'Tlajomulco', 'Puerto Vallarta'],
  'Michoacán': ['Morelia', 'Uruapan', 'Zamora', 'Lázaro Cárdenas', 'Pátzcuaro'],
  'Morelos': ['Cuernavaca', 'Jiutepec', 'Cuautla', 'Temixco', 'Yautepec'],
  'Nayarit': ['Tepic', 'Bahía de Banderas', 'Santiago Ixcuintla', 'Compostela'],
  'Nuevo León': ['Monterrey', 'Guadalupe', 'Apodaca', 'San Nicolás de los Garza', 'San Pedro Garza García', 'Santa Catarina', 'Escobedo'],
  'Oaxaca': ['Oaxaca de Juárez', 'Salina Cruz', 'Juchitán', 'Tuxtepec', 'Huatulco'],
  'Puebla': [
    'Puebla', 'San Andrés Cholula', 'San Pedro Cholula', 'Cuautlancingo', 'Atlixco',
    'Tehuacán', 'San Martín Texmelucan', 'Amozoc', 'Teziutlán', 'Huauchinango',
  ],
  'Querétaro': ['Querétaro', 'Corregidora', 'El Marqués', 'San Juan del Río'],
  'Quintana Roo': ['Cancún (Benito Juárez)', 'Playa del Carmen (Solidaridad)', 'Chetumal (Othón P. Blanco)', 'Cozumel', 'Tulum'],
  'San Luis Potosí': ['San Luis Potosí', 'Soledad de Graciano Sánchez', 'Ciudad Valles', 'Matehuala'],
  'Sinaloa': ['Culiacán', 'Mazatlán', 'Los Mochis (Ahome)', 'Guasave'],
  'Sonora': ['Hermosillo', 'Ciudad Obregón (Cajeme)', 'Nogales', 'San Luis Río Colorado', 'Guaymas'],
  'Tabasco': ['Villahermosa (Centro)', 'Cárdenas', 'Comalcalco', 'Paraíso'],
  'Tamaulipas': ['Reynosa', 'Matamoros', 'Nuevo Laredo', 'Tampico', 'Ciudad Victoria', 'Madero'],
  'Tlaxcala': ['Tlaxcala', 'Apizaco', 'Huamantla', 'Chiautempan', 'Zacatelco'],
  'Veracruz': ['Veracruz', 'Xalapa', 'Coatzacoalcos', 'Córdoba', 'Orizaba', 'Boca del Río', 'Poza Rica'],
  'Yucatán': ['Mérida', 'Valladolid', 'Progreso', 'Tizimín', 'Kanasín'],
  'Zacatecas': ['Zacatecas', 'Guadalupe', 'Fresnillo', 'Jerez'],
};

/// Abreviaturas comunes para mostrar la ubicación en poco espacio.
const abreviaturasEstado = <String, String>{
  'Aguascalientes': 'Ags.', 'Baja California': 'B.C.', 'Baja California Sur': 'B.C.S.',
  'Campeche': 'Camp.', 'Chiapas': 'Chis.', 'Chihuahua': 'Chih.', 'Ciudad de México': 'CDMX',
  'Coahuila': 'Coah.', 'Colima': 'Col.', 'Durango': 'Dgo.', 'Estado de México': 'Edo. Méx.',
  'Guanajuato': 'Gto.', 'Guerrero': 'Gro.', 'Hidalgo': 'Hgo.', 'Jalisco': 'Jal.',
  'Michoacán': 'Mich.', 'Morelos': 'Mor.', 'Nayarit': 'Nay.', 'Nuevo León': 'N.L.',
  'Oaxaca': 'Oax.', 'Puebla': 'Pue.', 'Querétaro': 'Qro.', 'Quintana Roo': 'Q. Roo',
  'San Luis Potosí': 'S.L.P.', 'Sinaloa': 'Sin.', 'Sonora': 'Son.', 'Tabasco': 'Tab.',
  'Tamaulipas': 'Tamps.', 'Tlaxcala': 'Tlax.', 'Veracruz': 'Ver.', 'Yucatán': 'Yuc.',
  'Zacatecas': 'Zac.',
};

/// "Puebla, Pue." / "Coyoacán, CDMX" / "Jalisco" / null
String? ubicacionCorta(String? municipio, String? estado) {
  final m = (municipio ?? '').trim();
  final e = (estado ?? '').trim();
  if (m.isEmpty && e.isEmpty) return null;
  if (m.isEmpty) return e;
  if (e.isEmpty) return m;
  return '$m, ${abreviaturasEstado[e] ?? e}';
}
