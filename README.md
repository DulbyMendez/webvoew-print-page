# Sistema de Impresión WebView Flutter

Este proyecto proporciona un sistema simplificado de impresión para aplicaciones Flutter que utilizan WebView. El sistema recibe solicitudes de impresión desde código JavaScript y las procesa para imprimir en impresoras ESC/POS de red.

## 🚀 Características Principales

- **Sistema Simplificado**: Solo se enfoca en la función de impresión, sin intercepción automática de elementos web
- **Soporte Multi-Impresora**: Permite imprimir en múltiples impresoras simultáneamente
- **Caracteres Españoles**: Soporte completo para caracteres especiales (á, é, í, ó, ú, ñ, ¿, ¡)
- **Configuración Flexible**: Múltiples opciones de codificación y normalización de caracteres
- **Validación de Datos**: Validación completa de los datos de impresión antes de procesar
- **Código Limpio**: Eliminadas funciones innecesarias y dependencias no utilizadas

## 📋 Requisitos

- Flutter SDK ^3.7.2
- Impresoras ESC/POS de red
- Dependencias mínimas especificadas en `pubspec.yaml`

## 🔧 Instalación

1. Clona el repositorio
2. Ejecuta `flutter pub get`
3. Configura las IPs de tus impresoras en el código
4. Ejecuta la aplicación

## 📖 Uso desde Código Web

### Método 1: Usando `callDirectPrint`

```javascript
// Llamar la función directamente con un objeto
callDirectPrint({
    content: "Texto a imprimir",
    title: "Título de impresión",
    printers: [
        { ip: "192.168.1.13", copies: 2 },
        { ip: "192.168.1.8", copies: 1 }
    ]
});
```

### Método 2: Usando `printToNative`

```javascript
// Función de conveniencia con parámetros separados
printToNative(
    "Texto a imprimir",
    "Título de impresión", 
    [
        { ip: "192.168.1.13", copies: 2 },
        { ip: "192.168.1.8", copies: 1 }
    ]
);
```

### Método 3: Usando `window.NativePrinter.postMessage`

```javascript
// Enviar mensaje JSON directamente
window.NativePrinter.postMessage(JSON.stringify({
    content: "Texto a imprimir",
    title: "Título de impresión",
    printers: [
        { ip: "192.168.1.13", copies: 2 },
        { ip: "192.168.1.8", copies: 1 }
    ]
}));
```

## 📋 Estructura de Datos

### Campos Requeridos

- **content** (string): El texto a imprimir
- **title** (string): El título del documento
- **printers** (array): Lista de impresoras con configuración

### Estructura de Impresora

```javascript
{
    ip: "192.168.1.13",    // IP de la impresora (string)
    copies: 2               // Número de copias (number >= 1)
}
```

## 🔧 Configuración de Caracteres

El sistema soporta múltiples configuraciones para el manejo de caracteres especiales:

### Codificaciones Disponibles

- **CP1252**: Recomendado para texto español
- **CP437**: Codificación estándar ESC/POS
- **CP850**: Codificación extendida
- **CP858**: Codificación con símbolos adicionales

### Opciones de Normalización

- **Normalización Parcial**: Solo reemplaza caracteres problemáticos
- **Normalización Completa**: Reemplaza todos los caracteres especiales

## 🧪 Pruebas

### Botones de Prueba Disponibles

- **⚡ Impresión Rápida**: Prueba con CP1252
- **🖨️ Probar Conexión**: Verifica conectividad con impresoras
- **🌐 Probar Caracteres Españoles**: Prueba con texto en español
- **⚙️ Configurar Caracteres**: Abre diálogo de configuración
- **▶️ Probar Función**: Envía solicitud de prueba desde Flutter
- **❓ Información de Uso**: Muestra información de uso de funciones

## 📁 Estructura del Proyecto

```
lib/
├── main.dart                           # Aplicación principal
├── services/
│   ├── printer_service.dart           # Lógica de impresión
│   ├── webview_communication_service.dart # Comunicación WebView
│   ├── print_job_manager.dart         # Gestión de trabajos
│   ├── javascript_injection_service.dart # Scripts JavaScript
│   ├── config_service.dart            # Configuración persistente
│   └── test_methods_service.dart      # Métodos de prueba básicos
├── utils/
│   └── character_fixer.dart           # Normalización de caracteres
└── widgets/
    ├── character_dialog.dart          # Diálogo de configuración
    └── print_status_widget.dart       # Widget de estado
```

## 🔍 Funciones Clave para Llevar a Otros Proyectos

### Para Impresión
- `PrinterService.printSpanish()` - Para texto español
- `PrinterService.printLatin1()` - Para caracteres latinos
- `PrinterService.printSimple()` - Con normalización completa

### Para Arreglo de Texto
- `normalizeText()` - Normalización completa
- `normalizeSpanishText()` - Solo caracteres problemáticos

### Para Gestión
- `PrintJobManager` - Control de impresiones simultáneas
- `validatePrintData()` - Validación de datos

### Para WebView
- `JavaScriptInjectionService.getPrintInterceptorScript()` - Script principal
- `WebViewCommunicationService` - Comunicación con la web

## 📦 Dependencias Simplificadas

```yaml
dependencies:
  # UI components
  cupertino_icons: ^1.0.8
  
  # WebView functionality
  webview_flutter: ^4.0.0
  
  # Printer functionality
  esc_pos_utils_plus: ^2.0.4
  
  # Configuration storage
  shared_preferences: ^2.2.2
  path_provider: ^2.1.1
```

## 🧹 Limpieza Realizada

### Funciones Eliminadas
- ❌ Intercepción automática de botones web
- ❌ Diagnósticos complejos de página
- ❌ Pruebas de estrategias de caracteres múltiples
- ❌ Funciones de detección de WebView forzada
- ❌ Depuración de inyección JavaScript compleja

### Dependencias Eliminadas
- ❌ `printing: ^5.11.1` - No se usa
- ❌ `http: ^1.1.0` - No se usa
- ❌ `socket_io_client: ^2.0.3+1` - No se usa
- ❌ `printer_plus: ^1.0.0` - No se usa

### Código Simplificado
- ✅ Solo funciones esenciales de impresión
- ✅ Validación de datos simplificada
- ✅ Scripts JavaScript mínimos
- ✅ Interfaz de usuario limpia

## 🚨 Validaciones

El sistema valida automáticamente:

- Que el contenido no esté vacío
- Que el título sea una cadena válida
- Que las impresoras tengan IP válida
- Que el número de copias sea >= 1
- Que no haya impresiones simultáneas

## 📝 Ejemplo Completo

```javascript
// Ejemplo completo de uso
function imprimirDocumento() {
    const datosImpresion = {
        content: "Este es un documento de prueba con caracteres especiales: á, é, í, ó, ú, ñ, ¿, ¡",
        title: "Documento de Prueba",
        printers: [
            { ip: "192.168.1.13", copies: 1 },
            { ip: "192.168.1.8", copies: 2 }
        ]
    };
    
    // Verificar que la función esté disponible
    if (typeof callDirectPrint === 'function') {
        callDirectPrint(datosImpresion);
        console.log('✅ Solicitud de impresión enviada');
    } else {
        console.error('❌ Función de impresión no disponible');
    }
}
```

## 🔧 Configuración de Impresoras

Asegúrate de configurar las IPs correctas de tus impresoras en el código. Por defecto, el sistema usa:

- IP: `192.168.1.13`
- Puerto: `9100`

## 📞 Soporte

Para problemas o preguntas, revisa los logs de la consola de Flutter y la consola del WebView para obtener información detallada sobre errores y estado del sistema.
