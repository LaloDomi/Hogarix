/// Minúsculas y sin acentos, para comparar búsquedas ("plomería" == "plomeria").
String normalizar(String texto) {
  const de = 'áàäâéèëêíìïîóòöôúùüûñ';
  const a = 'aaaaeeeeiiiioooouuuun';
  final buffer = StringBuffer();
  for (final ch in texto.toLowerCase().split('')) {
    final i = de.indexOf(ch);
    buffer.write(i == -1 ? ch : a[i]);
  }
  return buffer.toString().trim();
}
