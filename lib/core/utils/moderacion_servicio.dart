import 'package:flutter/foundation.dart';

/// Servicio maestro de Moderación Léxica y Filtro de Toxicidad.
/// Implementa des-ofuscación de Leetspeak, Grawlix y detección de Algospeak.
class ModeracionServicio {
  /// Diccionario masivo de palabras prohibidas, clasificado por severidad y categoría.
  static final List<String> _diccionarioProhibido = [
    // Categoría 1: Vulgaridades y Escatología
    'mierda',
    'puta',
    'puto',
    'culo',
    'cabron',
    'joder',
    'coño',
    'verga',
    'polla',
    'pendejo',
    'chingar',
    'coger',
    'orto',
    'boludo',
    'pelotudo',
    'concha',
    'carajo',
    'pinche', 'mamon', 'caca', 'pipi', 'pedu', 'mear',

    // Categoría 2: Insultos Despectivos
    'estupido',
    'idiota',
    'imbecil',
    'bobo',
    'tonto',
    'torpe',
    'inutil',
    'zorra',
    'perra',
    'cerdo',
    'gallina',
    'rata',
    'capullo',
    'fulastre',
    'bastardo',
    'maldito',
    'sapo', 'chivato', 'soplon', 'forro', 'gonorrea', 'carechimba', 'fufurufo',
    'mafufo', 'farol', 'gañan', 'fantoche', 'gaznapiro', 'gilipuertas',

    // Categoría 3: Odio, Etnofaulismos y LGBTI Slurs
    'sudaca',
    'moraco',
    'frijolero',
    'negrata',
    'gabacho',
    'chiriguillo',
    'argentuzo',
    'brazuca',
    'gringo',
    'yanqui',
    'gallegos',
    'maricon',
    'marica',
    'joto',
    'tortillera',
    'machorra', 'trailera', 'camionera', 'bixa', 'trabuco', 'transformer',

    // Categoría 3.3: Capacitismo y Sanismo
    'subnormal', 'mongolico', 'retrasado', 'deficiente', 'manco', 'minusvalido',
    'tullido', 'teleton', 'esquizo', 'demente',

    // Categoría 4: Anglicismos
    'fuck',
    'shit',
    'bitch',
    'asshole',
    'nigger',
    'nigga',
    'faggot',
    'kike',
    'cunt',
    'whore', 'dick', 'bastard', 'dork', 'scumbag',

    // Algospeak
    'desvivir', 'automoricion', 'resetearse', 'ab0rt0', 'v1olac1on', 'n0p0r',
    'jugo rojo', 'salsa de tomate', 'liquido vital',
  ];

  /// Diccionario especial de reemplazo para caracteres de Leetspeak y Homoglifos.
  /// Mapea símbolos a su equivalente en el alfabeto latino (A-Z).
  static final Map<String, String> _matrizLeetspeak = {
    // A
    '@': 'a',
    '4': 'a',
    '/': 'a',
    '^': 'a',
    '∆': 'a',
    'α': 'a',
    'á': 'a',
    'ä': 'a',
    'ã': 'a',
    'â': 'a',
    'ª': 'a',
    // B
    '8': 'b', '13': 'b', 'ß': 'b', '฿': 'b',
    // C
    '(': 'c', '<': 'c', '[': 'c', 'đ': 'c', '©': 'c',
    // E
    '3': 'e',
    '€': 'e',
    '&': 'e',
    '£': 'e',
    'ε': 'e',
    'ë': 'e',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    // F
    'ƒ': 'f', 'ph': 'f',
    // G
    '6': 'g', '9': 'g',
    // H
    '#': 'h', '}{': 'h',
    // I
    '1': 'i', '!': 'i', '|': 'i', 'ï': 'i', 'í': 'i', 'ì': 'i', 'î': 'i',
    // J
    'j': 'j', 'ʝ': 'j',
    // K
    'x': 'k',
    // L
    // M
    'nn': 'm',
    // N
    '2': 'n', 'ñ': 'n',
    // O
    '0': 'o',
    '*': 'o',
    '°': 'o',
    'ø': 'o',
    'ö': 'o',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    // P
    'p': 'p',
    // S
    '5': 's', '\$': 's', 'z': 's',
    // T
    '7': 't', '+': 't', '†': 't',
    // U
    'v': 'u', 'µ': 'u', 'ü': 'u', 'ú': 'u', 'ù': 'u', 'û': 'u',
    // V
    '\\/': 'v',
    // W
    'vv': 'w',
  };

  /// Preprocesa el texto: Remueve espacios múltiples, puntuación trampa (Grawlix),
  /// condensa caracteres repetidos (puuutto -> puto) y des-ofusca Leetspeak.
  static String normalizarTexto(String textoCrudo) {
    String texto = textoCrudo.toLowerCase();

    // 1. Remover Grawlix común y signos de puntuación engañosos
    texto = texto.replaceAll(RegExp(r'[_\-\.,;:"*~·]'), '');

    // 2. Reemplazo de matriz Leetspeak (Homoglifos a Letras simples)
    _matrizLeetspeak.forEach((simbolo, letra) {
      texto = texto.replaceAll(simbolo, letra);
    });

    // 3. Condensación de iteraciones repetitivas (ej: puuuttoooo -> puto)
    // RegExp para encontrar una letra que se repite 2 o más veces consecutivas y dejar solo 1.
    texto = texto.replaceAllMapped(RegExp(r'(.)\1+'), (Match match) {
      return match.group(1)!; // Devuelve el carácter original sin repetir
    });

    return texto;
  }

  /// Evalúa una cadena de texto. Si encuentra alguna coincidencia con el
  /// diccionario de palabras prohibidas, retorna TRUE (texto tóxico).
  static bool contieneLenguajeToxico(String textoIngresado) {
    if (textoIngresado.isEmpty) return false;

    // Normalizar la entrada para romper la ofuscación
    final textoNormalizado = normalizarTexto(textoIngresado);

    if (kDebugMode) {
      print('--- MODERADOR LEXICO ---');
      print('Texto Original: \$textoIngresado');
      print('Texto Normalizado: \$textoNormalizado');
    }

    // Comprobar contra el diccionario maestro
    for (String palabraProhibida in _diccionarioProhibido) {
      // Usamos contains para atrapar palabras incrustadas en cadenas más grandes
      if (textoNormalizado.contains(palabraProhibida)) {
        if (kDebugMode) {
          print(
            'ALERTA: Se detectó ofuscación o toxicidad: "\$palabraProhibida"',
          );
        }
        return true;
      }
    }

    // Detección directa de emojis problemáticos (Algospeak)
    if (textoIngresado.contains('🍉')) {
      if (kDebugMode) print('ALERTA: Se detectó Algospeak con Emojis.');
      return true;
    }

    return false;
  }
}
