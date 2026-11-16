# 🌿 Jardinería Gonzalo

> **Aplicación Móvil para Gestión de Servicios de Jardinería en Terreno**  
> Desarrollada en **Flutter** con arquitectura modular *Feature-First*, base de datos local SQLite y sistema de alarmas nativas Android de alta prioridad.

---

## 📱 Características Principales

* 📅 **Agenda en Terreno:**
  * Control de servicios pendientes con fecha, hora, dirección y observaciones específicas de trabajo.
  * Acciones rápidas de terreno: llamada directa al cliente y apertura de ubicación en Google Maps.
  * Marcado de trabajos como completados con registro inmediato del cobro.

* 👥 **Libreta de Clientes:**
  * Registro de clientes habituales con tipo (Con Abono vs Ocasionales), dirección, teléfono y observaciones permanentes.
  * Filtros rápidos por estado y búsqueda en tiempo real.
  * Agendamiento directo desde la ficha del cliente.

* 🔁 **Gestión Inteligente de Abonos:**
  * Configuración de frecuencia por visitas mensuales (1 vez/mes, 2 veces/mes, 3 veces/mes y Semanal).
  * Autoprogramación inteligente de turnos recurrentes en la agenda con sus respectivas alarmas.

* 🔔 **Sistema de Alarmas de Alta Prioridad:**
  * Selector granular de anticipación (días, horas, minutos).
  * Notificaciones exactas con `AudioAttributesUsage.alarm`, vibración continua y sonido de alarma del sistema.
  * Acciones interactivas en segundo plano: **[Detener]** y **[Posponer 15m]**.
  * Persistencia ante reinicios o apagados del teléfono (`RECEIVE_BOOT_COMPLETED`).

* 💰 **Historial y Auditoría de Cobros:**
  * Resumen financiero mensual destacado (total cobrado y cantidad de servicios realizados).
  * Navegación por meses (`< MMMM yyyy >`) con botón de retorno al mes actual.
  * Ajuste y corrección de cobros registrados.

* 🎨 **Diseño Moderno "Jardín Vivo":**
  * Fondo mate anti-reflejo (`#F4F7F5`) para máxima legibilidad bajo la luz solar directa.
  * Tarjetas flotantes en blanco puro con sombras orgánicas y bordes redondeados.
  * Paleta pastel funcional de alto contraste (WCAG AAA).

---

## 🛠️ Stack Tecnológico

* **Framework:** Flutter 3.50+ / Dart 3.14+
* **Persistencia Local:** SQLite (`sqflite: ^2.4.2`)
* **Notificaciones & Alarmas:** `flutter_local_notifications: ^18.0.1` + `timezone: ^0.10.0`
* **Navegación & Enlaces:** `url_launcher: ^6.3.1`
* **Internacionalización:** `intl: ^0.20.2`
* **Tipografía:** Google Fonts (*Plus Jakarta Sans*)

---

## 🚀 Compilación y Ejecución

### Prerrequisitos
* Flutter SDK 3.50+
* Android Studio / JDK 17+

### Comandos Básicos

```bash
# Obtener dependencias
flutter pub get

# Ejecutar en modo desarrollo
flutter run

# Ejecutar pruebas unitarias
flutter test

# Compilar APK Release optimizado
flutter build apk --release
```

---

## 📄 Licencia
Este proyecto es de uso privado para la gestión operativa de Jardinería Gonzalo.
