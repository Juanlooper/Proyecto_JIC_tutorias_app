import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/admin_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'quejas_view.dart';

class MetricasView extends StatefulWidget {
  const MetricasView({super.key});

  @override
  State<MetricasView> createState() => _MetricasViewState();
}

class _MetricasViewState extends State<MetricasView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().cargarEstadisticasDashboard();
    });
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
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.analytics), text: 'Rendimiento y Bienestar'),
              Tab(icon: Icon(Icons.security), text: 'Moderación'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDashboard(context),
            const QuejasView(ocultarAppBar: true),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final admin = context.watch<AdminProvider>();

    if (admin.estaCargando) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTotalHoras(admin),
          const SizedBox(height: 24),
          _buildSeccionHeader('Auditoría Estricta (Rendimiento del Tutor)'),
          const SizedBox(height: 16),
          _buildRetencionTutor(admin),
          const SizedBox(height: 24),
          _buildCancelacionTardia(admin),
          const SizedBox(height: 24),
          _buildSLA(admin),
          const SizedBox(height: 24),
          _buildDistribucionEstrellas(admin),

          const SizedBox(height: 40),
          _buildSeccionHeader('Mapa de Calor Académico (Bienestar Estudiantil)'),
          const SizedBox(height: 16),
          _buildDesercion(admin),
          const SizedBox(height: 24),
          _buildCuellosBotella(admin),
          const SizedBox(height: 24),
          _buildTreemap(admin),
          const SizedBox(height: 24),
          _buildHeavyUsers(admin),
          const SizedBox(height: 24),
          _buildHorasTutor(admin),

          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSeccionHeader(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
      textAlign: TextAlign.center,
    );
  }

  // ==========================================
  // GRÁFICOS MÓDULO 1
  // ==========================================

  Widget _buildRetencionTutor(AdminProvider admin) {
    // Calculamos el promedio global de retención solo para mostrar un velocímetro resumen
    double promedioGlobal = 0.0;
    if (admin.tasaRetencionTutor.isNotEmpty) {
      promedioGlobal = admin.tasaRetencionTutor.values.reduce((a, b) => a + b) / admin.tasaRetencionTutor.length;
    }

    Color colorSemaforo = Colors.red;
    if (promedioGlobal > 60) {
      colorSemaforo = Colors.green;
    } else if (promedioGlobal >= 30) {
      colorSemaforo = Colors.orange;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Tasa Media de Retención de Estudiantes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Promedio de alumnos que repiten clase con un mismo tutor.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 20),
            Text(
              '${promedioGlobal.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: colorSemaforo),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  promedioGlobal >= 50 ? Icons.arrow_upward : Icons.arrow_downward,
                  color: colorSemaforo,
                ),
                Text(' Nivel de calidad', style: TextStyle(color: colorSemaforo, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCancelacionTardia(AdminProvider admin) {
    // Mostrar lista de atención requerida
    var tutoresEnRiesgo = admin.tasaCancelacionTardiaTutor.entries
        .where((e) => e.value > 15.0) // Umbral 15%
        .toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Alertas: Cancelaciones Tardías (>15%)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Tutores que cancelan clases con menos de 12 horas de aviso.', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            if (tutoresEnRiesgo.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('No hay tutores con altas tasas de cancelación.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            else
              ...tutoresEnRiesgo.map((t) => ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: Text('ID Tutor: ${t.key.substring(0, 6)}...'),
                trailing: Text('${t.value.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildSLA(AdminProvider admin) {
    int horasSLA = admin.slaPromedioGlobal.inHours;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Tiempo Medio de Aceptación (SLA)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('El tiempo que demora una solicitud huérfana en ser aceptada por un tutor.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 20),
            Text(
              '$horasSLA hrs',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: horasSLA > 48 ? Colors.red : Colors.blue),
            ),
            if (horasSLA > 48)
              const Text('¡SLA EXCEDIDO! Se requieren más tutores', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
            else
              const Text('Dentro del límite aceptable (48 hrs)', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildDistribucionEstrellas(AdminProvider admin) {
    int total = admin.distribucionEstrellasGlobal.values.fold(0, (sum, x) => sum + x);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Distribución Global de Estrellas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            if (total == 0)
              const Text('Sin evaluaciones registradas')
            else
              ...List.generate(5, (index) {
                int estrella = 5 - index;
                int count = admin.distribucionEstrellasGlobal[estrella] ?? 0;
                double pct = count / total;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text('$estrella ★', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: Colors.grey[200],
                          color: Colors.amber,
                          minHeight: 12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildDesercion(AdminProvider admin) {
    double desercion = admin.indiceDesercionGlobal;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Índice de Deserción en Tutorías', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Alumnos que solicitan clase pero no asisten.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 20),
            Text(
              '${desercion.toStringAsFixed(1)}%',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: desercion > 20 ? Colors.red : Colors.purple),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCuellosBotella(AdminProvider admin) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Materias Cuello de Botella (Top 5)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Materias huérfanas con alta demanda no cubierta.', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            if (admin.materiasCuelloDeBotella.isEmpty)
              const Text('No hay cuellos de botella.', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
            else
              ...admin.materiasCuelloDeBotella.map((m) => ListTile(
                leading: const Icon(Icons.book, color: Colors.blueGrey),
                title: Text(m.key),
                trailing: Text('${m.value} solic.', style: const TextStyle(fontWeight: FontWeight.bold)),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalHoras(AdminProvider admin) {
    List<FlSpot> spots = [];
    if (admin.horasPorSemana.isNotEmpty) {
      var sortedKeys = admin.horasPorSemana.keys.toList()..sort();
      for (int i = 0; i < sortedKeys.length; i++) {
        spots.add(FlSpot(i.toDouble(), admin.horasPorSemana[sortedKeys[i]]!));
      }
    } else {
      spots = [const FlSpot(0, 0)];
    }

    return Card(
      elevation: 6,
      color: AppTheme.primarioAzul,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Control General de Horas Usadas en la Plataforma',
              style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '${admin.totalHorasImpartidas.toStringAsFixed(1)} Horas de Tutoría Impartidas',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 60,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.amberAccent,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.amberAccent.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreemap(AdminProvider admin) {
    if (admin.horasPorAsignaturaTreemap.isEmpty) {
      return const SizedBox.shrink();
    }

    double maxHoras = admin.horasPorAsignaturaTreemap.values.reduce((a, b) => a > b ? a : b);
    if (maxHoras == 0) maxHoras = 1;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Horas Consumidas por Asignatura (Profundidad de Estudio)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Desglose de materias y temas basado en asistencia confirmada.', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: admin.horasPorAsignaturaTreemap.entries.map((e) {
                double heightScore = (e.value / maxHoras) * 100;
                double size = 60 + heightScore; // min 60, max 160
                
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: (e.value / maxHoras).clamp(0.2, 1.0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(8),
                  alignment: Alignment.center,
                  child: Text(
                    '${e.key}\n${e.value.toStringAsFixed(1)}h',
                    style: TextStyle(
                      color: (e.value / maxHoras) > 0.5 ? Colors.white : Colors.black87,
                      fontSize: 10 + (e.value / maxHoras) * 4,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeavyUsers(AdminProvider admin) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                SizedBox(width: 8),
                Expanded(child: Text('Tabla de Riesgo: Estudiantes Heavy Users', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrange))),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Identificar alumnos que consumen excesivas horas. Podrían requerir consejería psicológica o académica.', style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            if (admin.heavyUsers.isEmpty)
              const Text('Sin datos de riesgo registrados.')
            else
              ...admin.heavyUsers.map((u) {
                bool riesgoAlto = (u['horas'] as double) >= 10; // >10 hours is high risk
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: riesgoAlto ? Colors.red.shade100 : Colors.orange.shade100,
                    child: Icon(Icons.person, color: riesgoAlto ? Colors.red : Colors.orange),
                  ),
                  title: Text(u['nombre'], style: TextStyle(fontWeight: riesgoAlto ? FontWeight.bold : FontWeight.normal)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: riesgoAlto ? Colors.red : Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('${(u['horas'] as double).toStringAsFixed(1)} hrs', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildHorasTutor(AdminProvider admin) {
    var tutores = admin.horasPorTutor.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Conteo de Horas Trabajadas por Tutor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            if (tutores.isEmpty)
              const Text('Sin datos registrados.')
            else
              ...tutores.map((t) => ListTile(
                leading: const Icon(Icons.work_history, color: Colors.blue),
                title: Text(t.key),
                trailing: Text('${t.value.toStringAsFixed(1)} hrs', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              )),
          ],
        ),
      ),
    );
  }
}
