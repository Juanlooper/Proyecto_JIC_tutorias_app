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
  
  bool _estaCargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosYProcesarMetric();
  }

  Future<void> _cargarDatosYProcesarMetric() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('tutorias').get();
      
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
        final nombreCorto = materia.length > 6 ? materia.substring(0, 6) : materia;
        
        // Sumamos la cantidad de inscritos
        final inscritos = data['listaDeEstudiantesInscritos'] as List<dynamic>? ?? [];
        final numInscritos = inscritos.length;
        
        conteoMaterias[nombreCorto] = (conteoMaterias[nombreCorto] ?? 0) + numInscritos;
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al procesar gráficas o conectar con la base de datos.')));
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
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ListaEstudiantesView()));
                        },
                        icon: const Icon(Icons.people),
                        label: const Text('Directorio de Estudiantes', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
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
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const HistorialTutoriasView()));
                        },
                        icon: const Icon(Icons.history_edu),
                        label: const Text('Historial General', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
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
        backgroundColor: AppTheme.fondoClaro,
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
                        if (controller.index > 0) controller.animateTo(controller.index - 1);
                      },
                    ),
                    const Expanded(
                      child: TabBar(
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white60,
                        indicatorColor: Colors.white,
                        tabs: [
                          Tab(icon: Icon(Icons.bar_chart), text: 'Estadísticas'),
                          Tab(icon: Icon(Icons.security), text: 'Moderación'),
                        ],
                      ),
                    ),
                    IconButton(
                        icon: const Icon(Icons.chevron_right, color: Colors.white),
                        onPressed: () {
                          final controller = DefaultTabController.of(context);
                          if (controller.index < controller.length - 1) controller.animateTo(controller.index + 1);
                        },
                    ),
                  ],
                );
              }
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
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textoOscuro),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPieChartCard() {
    final todosCero = _tutoriasPendientes == 0 && _tutoriasFinalizadas == 0 && _tutoriasCanceladas == 0;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                      radius: 60,
                      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      value: _tutoriasFinalizadas.toDouble(),
                      title: 'Finalizadas\n$_tutoriasFinalizadas',
                      color: Colors.blueAccent,
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      value: _tutoriasCanceladas.toDouble(),
                      title: 'Canceladas\n$_tutoriasCanceladas',
                      color: Colors.red.shade400,
                      radius: 50,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
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

    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < limitesKeys.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: _materiasSolicitadas[limitesKeys[i]]!.toDouble(),
              color: AppTheme.primarioAzul,
              width: 18,
              borderRadius: BorderRadius.circular(4),
            )
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.only(top: 32, right: 16, left: 16, bottom: 16),
        child: SizedBox(
          height: 300,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (_materiasSolicitadas.values.isEmpty ? 1 : _materiasSolicitadas.values.reduce((a, b) => a > b ? a : b) + 2).toDouble(),
              barTouchData: BarTouchData(enabled: true),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value.toInt() >= 0 && value.toInt() < limitesKeys.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(limitesKeys[value.toInt()], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                ),
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
