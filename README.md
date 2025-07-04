# Flutter WebView Print Page

Una aplicación Flutter que intercepta botones de impresión en páginas web y permite imprimir usando impresoras locales y de red.

## Características

- **Interceptación de botones de impresión**: Detecta automáticamente botones de imprimir en páginas web
- **Impresión nativa**: Permite imprimir documentos usando impresoras locales del sistema
- **Impresión de red**: Conecta directamente con impresoras de red (ESC/POS)
- **Compatibilidad multiplataforma**: Funciona en Android, iOS, macOS, Windows y Linux
- **Interfaz de usuario intuitiva**: Diálogos de confirmación y notificaciones de estado
- **Prueba de conexión**: Botón para verificar la conectividad con la impresora de red

## Funcionalidades Implementadas

### 1. Interceptación de Botones de Impresión
- Detecta botones con ID `printBtn`
- Fallback para otros selectores comunes de botones de imprimir
- Intercepta llamadas a `window.print()`

### 2. Canal de Comunicación JavaScript-Flutter
- `PrintInterceptor`: Para logging y debugging
- `NativePrinter`: Para enviar datos de impresión a Flutter

### 3. Impresión de Red (ESC/POS)
- Conexión directa a impresoras de red en IP `192.168.1.13:9100`
- Protocolo ESC/POS para impresoras térmicas y de punto
- Formateo automático del documento (título, fecha, contenido)
- Prueba de conectividad en tiempo real

### 4. Extracción Inteligente de Contenido
- Extrae automáticamente el texto del textarea de la página web
- Fallback al historial de impresiones si no hay textarea
- Procesamiento del contenido HTML para obtener texto limpio

## Configuración de Impresora

### Impresora de Red
La aplicación está configurada para conectarse a una impresora de red en:
- **IP**: `192.168.1.13`
- **Puerto**: `9100` (puerto estándar para impresoras ESC/POS)

### Cambiar Configuración
Para cambiar la IP o puerto de la impresora, modifica la clase `NetworkPrinter` en `lib/main.dart`:

```dart
class NetworkPrinter {
  static const String printerIP = 'TU_IP_AQUI';
  static const int printerPort = TU_PUERTO_AQUI;
  // ...
}
```

## Cómo Funciona

1. **Carga de la página web**: La aplicación carga `https://print-web.vercel.app/`
2. **Inyección de JavaScript**: Se inyecta código JavaScript para interceptar botones de impresión
3. **Interceptación**: Cuando se hace clic en un botón de imprimir, se captura el evento
4. **Comunicación**: Los datos de la página se envían a Flutter a través del canal `NativePrinter`
5. **Extracción de contenido**: Se extrae el texto del textarea o historial de impresiones
6. **Confirmación**: Se muestra un diálogo de confirmación al usuario
7. **Prueba de conexión**: Se verifica la conectividad con la impresora de red
8. **Impresión**: Se envía el documento formateado a la impresora ESC/POS

## Dependencias

```yaml
dependencies:
  flutter:
    sdk: flutter
  webview_flutter: ^4.0.0
  printing: ^5.11.1
  path_provider: ^2.1.1
  http: ^1.1.0
  socket_io_client: ^2.0.3+1
  printer_plus: ^1.0.0
```

## Uso

1. Ejecuta la aplicación: `flutter run`
2. La aplicación cargará automáticamente la página web
3. (Opcional) Haz clic en el icono de impresora en la AppBar para probar la conexión
4. Escribe texto en el textarea de la página web
5. Haz clic en el botón "Imprimir Texto"
6. Confirma la impresión en el diálogo de Flutter
7. El documento será enviado a la impresora de red

## Estructura del Código

### Archivos Principales
- `lib/main.dart`: Contiene toda la lógica de la aplicación

### Clases Principales
- `MyApp`: Widget raíz de la aplicación
- `WebViewScreen`: Pantalla principal con WebView
- `_WebViewScreenState`: Estado que maneja la lógica de impresión
- `NetworkPrinter`: Clase para manejar la conexión con impresoras de red

### Métodos Clave
- `_injectPrintInterceptor()`: Inyecta JavaScript para interceptar botones
- `_handleNativePrint()`: Procesa las llamadas de impresión desde JavaScript
- `_printDocument()`: Maneja el proceso de impresión de red
- `_extractTextFromHTML()`: Extrae texto del HTML de la página
- `NetworkPrinter.printToNetworkPrinter()`: Envía documento a la impresora
- `NetworkPrinter.testConnection()`: Prueba la conectividad

## Protocolo ESC/POS

La aplicación utiliza comandos ESC/POS estándar para formatear documentos:

- **Inicialización**: `ESC @` - Inicializa la impresora
- **Alineación**: `ESC a 1` (centro), `ESC a 0` (izquierda)
- **Negrita**: `ESC E 1` (activar), `ESC E 0` (desactivar)
- **Form Feed**: `0x0C` - Avanza al siguiente papel

## Solución de Problemas

### No se puede conectar a la impresora
1. Verifica que la IP `192.168.1.13` sea correcta
2. Confirma que el puerto `9100` esté abierto
3. Asegúrate de que la impresora esté encendida y conectada a la red
4. Usa el botón de prueba de conexión en la AppBar

### El documento no se imprime correctamente
1. Verifica que la impresora soporte comandos ESC/POS
2. Confirma que el papel esté disponible
3. Revisa los logs de la aplicación para errores específicos

## Extensibilidad

La aplicación está diseñada para ser fácilmente extensible:

1. **Más impresoras**: Agregar soporte para múltiples impresoras de red
2. **Configuración**: Interfaz para configurar IP y puerto de impresoras
3. **Formatos**: Implementar diferentes formatos de salida (PDF, texto, etc.)
4. **Protocolos**: Agregar soporte para otros protocolos de impresora

## Notas Técnicas

- La aplicación no funciona en Flutter Web debido a limitaciones de WebView
- El JavaScript inyectado se ejecuta después de que la página se carga completamente
- Se incluyen múltiples intentos de inyección para contenido dinámico
- Los datos de la página se capturan como HTML completo
- La conexión con la impresora usa sockets TCP directos
- Los comandos ESC/POS son estándar para impresoras térmicas y de punto

## Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature
3. Commit tus cambios
4. Push a la rama
5. Abre un Pull Request
#   w e b v o e w - p r i n t - p a g e 
 
 