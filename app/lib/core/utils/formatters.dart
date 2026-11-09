String normalizarBusca(String texto) {
  const comAcento = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const semAcento = 'aaaaaeeeeiiiiooooouuuucn';
  final buffer = StringBuffer();
  for (final char in texto.toLowerCase().trim().split('')) {
    final i = comAcento.indexOf(char);
    buffer.write(i >= 0 ? semAcento[i] : char);
  }
  return buffer.toString();
}

/// Ex.: 12.5 → "R$ 12,50".
String formatarMoeda(double valor) => 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';

/// Ex.: 14:05 (no fuso do aparelho). Vazio se [data] for nula.
String formatarHora(DateTime? data) {
  if (data == null) return '';
  final local = data.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
