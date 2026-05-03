import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_theme.dart';
import 'lista_estudiantes_view.dart';
import 'historial_tutorias_view.dart';
import 'quejas_view.dart';

class MetricasView extends StatefulWidget {
  const MetricasView({super.key});

  @override
  State<MetricasView> createState() => _MetricasViewState();
}

class _MetricasViewState extends State<MetricasView> {
  // Estado general
  int _tutoriasPendientes = 0;
  int _tutoriasFinalizadas = 0;
  int _tutoriasCanceladas = 0;

  // Frecuencia por materia
  final Map<String, int> _materiasSolicitadas = {};
  // Horas
  final Map<String, double> _horasPorTutor = {};
  final Map<String, double> _horasPorMateria = {};
  final Map<String, double> _horasPorAlumno = {};
  bool _estaCargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosYProcesarMetric();
  }

  Future<void> _cargarDatosYProcesarMetric() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tutorias')
          .get();

      int pendientes = 0;
      int finalizadas = 0;
      int canceladas = 0;
      Map<String, int> conteoMaterias = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // 1. Conteo de Estados
        final estado = data['estadoDeLaSolicitud'] ?? 'solicitada';
        if (estado == 'finalizada') {
          finalizadas++;
        } else if (estado == 'cancelada') {
          canceladas++;
        } else {
          pendientes++;
        }

        // 2. Conteo de Materias
        final materia = data['materiaOAsignatura'] as String? ?? 'Desconocida';
        // Reducimos el string si es muy largo para la gráfica de barras
        final nombreCorto = materia.length > 6
            ? materia.substring(0, 6)
            : materia;

        // Sumamos la cantidad de inscritos
        final inscritos =
            data['listaDeEstudiantesInscritos'] as List<dynamic>? ?? [];
        final numInscritos = inscritos.length;
        conteoMaterias[nombreCorto] = (conteoMaterias[nombreCorto] ?? 0) + numInscritos;

        if (estado == 'finalizada') {
          double horas = (data['duracionMinutos'] ?? 60) / 60.0;
          final tutorId = data['identificadorDelTutor'] as String? ?? 'Desc';
          final tutorNombre = data['nombre_tutor'] ?? 'Tutor ${tutorId.length > 4 ? tutorId.substring(0,4) : tutorId}';
          
          _horasPorTutor[tutorNombre] = (_horasPorTutor[tutorNombre] ?? 0) + horas;
          _horasPorMateria[nombreCorto] = (_horasPorMateria[nombreCorto] ?? 0) + horas;
          
          for (var uid in inscritos) {
             final nombreEst = uid.toString().length > 4 ? uid.toString().substring(0,4) : uid.toString();
             _horasPorAlumno['Alum $nombreEst'] = (_horasPorAlumno['Alum $nombreEst'] ?? 0) + horas;
          }
        }
      }

      if (mounted) {
        setState(() {
          _tutoriasPendientes = pendientes;
          _tutoriasFinalizadas = finalizadas;
          _tutoriasCanceladas = canceladas;
          _materiasSolicitadas.addAll(conteoMaterias);
          _estaCargando = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _estaCargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error al procesar gráficas o conectar con la base de datos.',
            ),
          ),
        );
      }
    }
  }

  Widget _buildContenidoMetricas() {
    return _estaCargando
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTitulo('Estado Global de Sesiones'),
                const SizedBox(height: 16),
                _buildPieChartCard(),

                const SizedBox(height: 32),

                _buildTitulo('Demanda por Materias (Alumnos Inscritos)'),
                const SizedBox(height: 16),
                _buildBarChartCard(),

                const SizedBox(height: 32),
                _buildTitulo('Horas Impartidas por Tutor'),
                const SizedBox(height: 16),
                _buildHorasChartCard(_horasPorTutor, Colors.deepPurpleAccent, 'Hrs'),

                const SizedBox(height: 32),
                _buildTitulo('Horas Impartidas por Materia'),
                const SizedBox(height: 16),
                _buildHorasChartCard(_horasPorMateria, Colors.orangeAccent, 'Hrs'),
                
                const SizedBox(height: 32),
                _buildTitulo('Horas Recibidas por Estudiante'),
                const SizedBox(height: 16),
                _buildHorasChartCard(_horasPorAlumno, Colors.lightBlue, 'Hrs'),

                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ListaEstudiantesView(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.people),
                        label: const Text(
                          'Directorio de Estudiantes',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HistorialTutoriasView(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history_edu),
                        label: const Text(
                          'Historial General',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 48), // Padding inferior
              ],
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Métricas y Análisis'),
          backgroundColor: AppTheme.primarioVerde,
          foregroundColor: Colors.white,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(72.0),
            child: Builder(
              builder: (context) {
                return Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white),
                      onPressed: () {
                        final controller = DefaultTabController.of(context);
                        if (controller.index > 0) {
                          controller.animateTo(controller.index - 1);
                        }
                      },
                    ),
                    const Expanded(
                      child: TabBar(
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white60,
                        indicatorColor: Colors.white,
                        tabs: [
                          Tab(
                            icon: Icon(Icons.bar_chart),
                            text: 'Estadísticas',
                          ),
                          Tab(icon: Icon(Icons.security), text: 'Moderación'),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        final controller = DefaultTabController.of(context);
                        if (controller.index < controller.length - 1) {
                          controller.animateTo(controller.index + 1);
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildContenidoMetricas(),
            const QuejasView(ocultarAppBar: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTitulo(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPieChartCard() {
    final todosCero =
        _tutoriasPendientes == 0 &&
        _tutoriasFinalizadas == 0 &&
        _tutoriasCanceladas == 0;

    return Card(
      elevation: 8,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        padding: const EdgeInsets.all(24.0),
        child: SizedBox(
          height: 250,
          child: todosCero 
            ? const Center(child: Text('Sin datos registrados en la plataforma'))
            : PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: _tutoriasPendientes.toDouble(),
                      title: 'Pendientes\n$_tutoriasPendientes',
                      color: AppTheme.primarioVerde,
                      radius: 65,
                      titleStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white, shadows: [Shadow(color: Colors.black26, blurRadius: 4)]),
                    ),
                    PieChartSectionData(
                      value: _tutoriasFinalizadas.toDouble(),
                      title: 'Finalizadas\n$_tutoriasFinalizadas',
                      color: const Color(0xFF3B82F6), // Azul moderno
                      radius: 55,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black26, blurRadius: 4)]),
                    ),
                    PieChartSectionData(
                      value: _tutoriasCanceladas.toDouble(),
                      title: 'Canceladas\n$_tutoriasCanceladas',
                      color: const Color(0xFFEF4444), // Rojo moderno
                      radius: 55,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black26, blurRadius: 4)]),
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildBarChartCard() {
    if (_materiasSolicitadas.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: Text('Sin materias demandadas aún.')),
        ),
      );
    }

    final keys = _materiasSolicitadas.keys.toList();
    // Filtramos para evitar que la gráfica colapse
    final limitesKeys = keys.take(8).toList();

    final maxYValue = (_materiasSolicitadas.values.isEmpty ? 1 : _materiasSolicitadas.values.reduce((a, b) => a > b ? a : b) + 2).toDouble();

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < limitesKeys.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: _materiasSolicitadas[limitesKeys[i]]!.toDouble(),
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 22,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxYValue,
                color: Colors.blueAccent.withValues(alpha: 0.05),
              ),
            )
          ],
          showingTooltipIndicators: [0],
        ),
      );
    }

    return Card(
      elevation: 8,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.blue.shade50.withValues(alpha: 0.3)],
          ),
        ),
        padding: const EdgeInsets.only(top: 40, right: 24, left: 24, bottom: 24),
        child: SizedBox(
          height: 320,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxYValue,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${rod.toY.toInt()} inscritos',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value.toInt() >= 0 &&
                          value.toInt() < limitesKeys.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            limitesKeys[value.toInt()], 
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
                          ),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: 36,
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              barGroups: barGroups,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorasChartCard(Map<String, double> datos, Color colorBarra, String sufijo) {
    if (datos.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: Text('Sin datos suficientes para graficar.')),
        ),
      );
    }

    var entradas = datos.entries.toList();
    entradas.sort((a, b) => b.value.compareTo(a.value));
    final topEntradas = entradas.take(8).toList();
    final maxYValue = topEntradas.first.value * 1.3;

    // Determinar el gradiente según el color base para darle un look premium
    final isPurple = colorBarra == Colors.deepPurpleAccent;
    final gradientColors = isPurple 
        ? const [Color(0xFF8B5CF6), Color(0xFFA78BFA)] // Purple 500 to 400
        : const [Color(0xFFF59E0B), Color(0xFFFCD34D)]; // Amber 500 to 300

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < topEntradas.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: topEntradas[i].value,
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 24,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxYValue,
                color: colorBarra.withValues(alpha: 0.05),
              ),
            )
          ],
          showingTooltipIndicators: [0],
        ),
      );
    }

    return Card(
      elevation: 8,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, colorBarra.withValues(alpha: 0.03)],
          ),
        ),
        padding: const EdgeInsets.only(top: 45, right: 24, left: 24, bottom: 24),
        child: SizedBox(
          height: 320,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxYValue,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${rod.toY.toStringAsFixed(1)} $sufijo',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value.toInt() >= 0 && value.toInt() < topEntradas.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            topEntradas[value.toInt()].key, 
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF4B5563)),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: 44,
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              barGroups: barGroups,
            ),
          ),
        ),
      ),
    );
  }
}
