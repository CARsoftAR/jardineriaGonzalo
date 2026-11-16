import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/cliente_model.dart';
import '../models/servicio_model.dart';

/// Servicio Singleton para la persistencia local con SQLite.
class DbService {
  static final DbService _instance = DbService._internal();
  factory DbService() => _instance;
  DbService._internal();

  static const String _dbName = 'jardineria_app.db';
  static const int _dbVersion = 5; // Versión 5: Reseteo completo y limpio de la base de datos

  // Tabla Servicios
  static const String tableServicios = 'servicios';
  static const String columnId = 'id';
  static const String columnClienteId = 'clienteId';
  static const String columnClienteNombre = 'clienteNombre';
  static const String columnTelefono = 'telefono';
  static const String columnDireccion = 'direccion';
  static const String columnFechaServicio = 'fechaServicio';
  static const String columnMontoCobrado = 'montoCobrado';
  static const String columnEstado = 'estado';
  static const String columnMinutosAnticipacion = 'minutosAnticipacion';
  static const String columnObservacion = 'observacion';

  // Tabla Clientes
  static const String tableClientes = 'clientes';
  static const String columnNombre = 'nombre';
  static const String columnTipoCliente = 'tipoCliente';
  static const String columnFrecuenciaAbono = 'frecuenciaAbono';
  static const String columnPrecioSugerido = 'precioSugerido';

  Database? _database;

  /// Permite inyectar una instancia de Database (útil para pruebas unitarias con FFI o mocks).
  void initForTesting(Database db) {
    _database = db;
  }

  /// Obtiene la instancia activa de la base de datos, inicializándola si es necesario.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Inicializa la base de datos creando la estructura requerida.
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Creación del esquema de la tabla de servicios y clientes.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableClientes (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnNombre TEXT NOT NULL,
        $columnTelefono TEXT,
        $columnDireccion TEXT NOT NULL,
        $columnTipoCliente TEXT NOT NULL,
        $columnFrecuenciaAbono TEXT NOT NULL,
        $columnPrecioSugerido REAL NOT NULL DEFAULT 0.0,
        $columnObservacion TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableServicios (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnClienteId INTEGER,
        $columnClienteNombre TEXT NOT NULL,
        $columnTelefono TEXT,
        $columnDireccion TEXT NOT NULL,
        $columnFechaServicio TEXT NOT NULL,
        $columnMontoCobrado REAL NOT NULL DEFAULT 0.0,
        $columnEstado TEXT NOT NULL,
        $columnMinutosAnticipacion INTEGER NOT NULL DEFAULT 60,
        $columnObservacion TEXT
      )
    ''');
  }

  /// Migraciones controladas para actualizaciones de esquema.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (newVersion >= 5) {
      // Reseteo total solicitado: eliminar tablas existentes y recrear esquema completamente limpio
      await db.execute('DROP TABLE IF EXISTS $tableServicios;');
      await db.execute('DROP TABLE IF EXISTS $tableClientes;');
      await _onCreate(db, newVersion);
      return;
    }
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE $tableServicios ADD COLUMN $columnTelefono TEXT',
      );
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableClientes (
          $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
          $columnNombre TEXT NOT NULL,
          $columnTelefono TEXT,
          $columnDireccion TEXT NOT NULL,
          $columnTipoCliente TEXT NOT NULL,
          $columnFrecuenciaAbono TEXT NOT NULL,
          $columnPrecioSugerido REAL NOT NULL DEFAULT 0.0
        )
      ''');

      try {
        await db.execute('ALTER TABLE $tableServicios ADD COLUMN $columnClienteId INTEGER;');
      } catch (_) {}
    }
    if (oldVersion < 4) {
      try {
        await db.execute('ALTER TABLE $tableClientes ADD COLUMN $columnObservacion TEXT;');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE $tableServicios ADD COLUMN $columnObservacion TEXT;');
      } catch (_) {}
    }
  }

  // ==========================================
  // MÉTODOS PARA CLIENTES
  // ==========================================

  /// Inserta un nuevo cliente en la libreta.
  Future<int> insertCliente(Cliente cliente) async {
    final db = await database;
    return await db.insert(
      tableClientes,
      cliente.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene todos los clientes registrados ordenados alfabéticamente.
  Future<List<Cliente>> getClientes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableClientes,
      orderBy: '$columnNombre COLLATE NOCASE ASC',
    );
    return List.generate(maps.length, (i) => Cliente.fromMap(maps[i]));
  }

  /// Obtiene un cliente específico por su ID.
  Future<Cliente?> getClienteById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableClientes,
      where: '$columnId = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return Cliente.fromMap(maps.first);
    }
    return null;
  }

  /// Actualiza los datos de un cliente existente.
  Future<int> updateCliente(Cliente cliente) async {
    if (cliente.id == null) return 0;
    final db = await database;
    return await db.update(
      tableClientes,
      cliente.toMap(),
      where: '$columnId = ?',
      whereArgs: [cliente.id],
    );
  }

  /// Elimina un cliente de la libreta.
  Future<int> deleteCliente(int id) async {
    final db = await database;
    return await db.delete(
      tableClientes,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  /// Limpia por completo la base de datos eliminando todos los registros de clientes y servicios.
  Future<void> limpiarBaseDeDatosCompleta() async {
    final db = await database;
    await db.delete(tableServicios);
    await db.delete(tableClientes);
  }

  // ==========================================
  // MÉTODOS PARA SERVICIOS
  // ==========================================

  /// Inserta un nuevo servicio en la base de datos y retorna el ID autogenerado.
  Future<int> insertServicio(Servicio servicio) async {
    final db = await database;
    return await db.insert(
      tableServicios,
      servicio.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Obtiene la lista de servicios con estado 'PENDIENTE', ordenados por fecha ascendente.
  Future<List<Servicio>> getServiciosPendientes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableServicios,
      where: '$columnEstado = ?',
      whereArgs: [Servicio.estadoPendiente],
      orderBy: '$columnFechaServicio ASC',
    );

    return List.generate(maps.length, (i) => Servicio.fromMap(maps[i]));
  }

  /// Obtiene el historial de servicios con estado 'COMPLETADO', ordenados por fecha descendente.
  Future<List<Servicio>> getServiciosCompletados() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableServicios,
      where: '$columnEstado = ?',
      whereArgs: [Servicio.estadoCompletado],
      orderBy: '$columnFechaServicio DESC',
    );

    return List.generate(maps.length, (i) => Servicio.fromMap(maps[i]));
  }

  /// Actualiza el estado de un servicio a 'COMPLETADO' registrando su monto final cobrado.
  Future<int> completarServicio(int id, double montoCobrado) async {
    final db = await database;
    return await db.update(
      tableServicios,
      {
        columnEstado: Servicio.estadoCompletado,
        columnMontoCobrado: montoCobrado,
      },
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  /// Actualiza únicamente el monto cobrado de un servicio completado existente.
  Future<int> actualizarMontoCobrado(int id, double nuevoMonto) async {
    final db = await database;
    return await db.update(
      tableServicios,
      {columnMontoCobrado: nuevoMonto},
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  /// Obtiene un servicio específico por su identificador.
  Future<Servicio?> getServicioById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableServicios,
      where: '$columnId = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Servicio.fromMap(maps.first);
    }
    return null;
  }

  /// Actualiza los datos generales de un servicio existente.
  Future<int> updateServicio(Servicio servicio) async {
    if (servicio.id == null) return 0;
    final db = await database;
    final int filasAfectadas = await db.update(
      tableServicios,
      servicio.toMap(),
      where: '$columnId = ?',
      whereArgs: [servicio.id],
    );
    print('DbService.updateServicio - ID: ${servicio.id}, Fecha: ${servicio.fechaServicio}, Filas afectadas: $filasAfectadas');
    return filasAfectadas;
  }

  /// Elimina un servicio por su identificador.
  Future<int> deleteServicio(int id) async {
    final db = await database;
    return await db.delete(
      tableServicios,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }

  /// Cierra la conexión activa de la base de datos.
  Future<void> close() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
    }
  }
}
