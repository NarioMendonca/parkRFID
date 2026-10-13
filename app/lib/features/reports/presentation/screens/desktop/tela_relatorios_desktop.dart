import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/api/api_client.dart';
import '../../../data/models/session_report_model.dart';
import '../../../data/models/consumption_report_model.dart';
import '../../../data/repositories/reports_repositories.dart';


class TelaRelatoriosDesktop extends StatefulWidget {
  const TelaRelatoriosDesktop({super.key});

  @override
  State<TelaRelatoriosDesktop> createState() => _TelaRelatoriosDesktopState();
}

class _TelaRelatoriosDesktopState extends State<TelaRelatoriosDesktop> {
  late final ReportsRepository _reportsRepository;

  SessionReportModel? _sessionReport;
  ConsumptionReportModel? _consumptionReport;
  bool _isLoading = true;
  bool _isApiOffline = false;

  @override
  void initState() {
    super.initState();
    _reportsRepository = ReportsRepository(ApiClient.dio);
    _fetchAllReports();
  }

  Future<void> _fetchAllReports() async {
    setState(() {
      _isLoading = true;
      _isApiOffline = false;
    });

    try {
      final sessionRes = await _reportsRepository.fetchSessionReport();
      final consumptionRes = await _reportsRepository.fetchConsumptionToday();

      if (mounted) {
        setState(() {
          _sessionReport = sessionRes;
          _consumptionReport = consumptionRes;
          _isLoading = false;
          _isApiOffline = false;
        });
      }
    } on DioException catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isApiOffline = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isApiOffline = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      body: Column(
        children: [
          // Header Superior
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colorScheme.primary, colorScheme.primaryContainer],
              ),
            ),
            child: Row(
              children: [
                Image.asset('assets/images/logo.png', height: 42, fit: BoxFit.contain),
                const SizedBox(width: 16),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dashboard Analítico e Métricas', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),

          // Conteúdo do Dashboard
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colorScheme.outlineVariant),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho Interno
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Visão Geral do Parque',
                              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Monitoramento em tempo real de fluxo de visitantes e faturamento.',
                              style: TextStyle(fontSize: 16, color: colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _fetchAllReports();
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 22),
                          label: const Text('Atualizar Dados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Conteúdo
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            // Linha de KPIs com dados reais da API
                            Row(
                              children: [
                                Expanded(
                                  child: _KpiCard(
                                    title: 'Sessões Ativas',
                                    value: '${_sessionReport?.activeSessions ?? 0}',
                                    subtitle: 'Visitantes no parque agora',
                                    icon: Icons.people_alt_rounded,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _KpiCard(
                                    title: 'Check-ins Hoje',
                                    value: '${_sessionReport?.sessionsCreatedToday ?? 0}',
                                    subtitle: 'Total de entradas registradas',
                                    icon: Icons.today_rounded, 
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _KpiCard(
                                    title: 'Faturamento Hoje',
                                    value: 'R\$ ${_consumptionReport?.total ?? "0.00"}',
                                    subtitle: _consumptionReport?.date.isNotEmpty == true
                                        ? 'Data: ${_consumptionReport!.date}'
                                        : 'Atualizado hoje',
                                    icon: Icons.payments_rounded,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Bloco do Dashboard
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Coluna Esquerda: Métricas com os valores da API
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    padding: const EdgeInsets.all(28),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: colorScheme.outlineVariant),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Fluxo de Atividade do Parque',
                                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                            ),
                                            Icon(Icons.bar_chart_rounded, color: colorScheme.primary, size: 28),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Totais consolidados retornado pelos endpoints de relatório.',
                                          style: TextStyle(color: Colors.grey, fontSize: 14),
                                        ),
                                        const SizedBox(height: 32),

                                        _MetricStatRow(
                                          label: 'Sessões Ativas no Momento',
                                          value: '${_sessionReport?.activeSessions ?? 0}',
                                          icon: Icons.directions_walk_rounded,
                                          color: Colors.blue,
                                        ),
                                        const Divider(height: 28),
                                        _MetricStatRow(
                                          label: 'Novas Sessões Criadas Hoje',
                                          value: '${_sessionReport?.sessionsCreatedToday ?? 0}',
                                          icon: Icons.add_business_rounded,
                                          color: Colors.orange,
                                        ),
                                        const Divider(height: 28),
                                        _MetricStatRow(
                                          label: 'Total de Consumo do Dia',
                                          value: 'R\$ ${_consumptionReport?.total ?? "0.00"}',
                                          icon: Icons.account_balance_wallet_rounded,
                                          color: Colors.green,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24),

                                // Coluna Direita: Status Real de Conexão e API
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(28),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: colorScheme.outlineVariant),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Status de Conexão',
                                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                            ),
                                            Icon(
                                              _isApiOffline ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                                              color: _isApiOffline ? Colors.red : Colors.green,
                                              size: 28,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        const Text(
                                          'Conectividade verificada em tempo real com a API.',
                                          style: TextStyle(color: Colors.grey, fontSize: 14),
                                        ),
                                        const SizedBox(height: 28),

                                        _StatusRow(
                                          title: 'Servidor Fastify',
                                          status: _isApiOffline ? 'Offline' : 'Online',
                                          isOk: !_isApiOffline,
                                        ),
                                        const Divider(height: 32),
                                        _StatusRow(
                                          title: 'Banco de Dados (Prisma)',
                                          status: _isApiOffline ? 'Sem Resposta' : 'Conectado',
                                          isOk: !_isApiOffline,
                                        ),
                                        const Divider(height: 32),
                                        _StatusRow(
                                          title: 'Serviço de Relatórios',
                                          status: _isApiOffline ? 'Falha de Carga' : 'Sincronizado',
                                          isOk: !_isApiOffline,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurfaceVariant)),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: colorScheme.onSurface)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}

class _MetricStatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricStatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String title;
  final String status;
  final bool isOk;

  const _StatusRow({
    required this.title,
    required this.status,
    required this.isOk,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: isOk ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(status, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isOk ? Colors.green.shade700 : Colors.red)),
          ],
        ),
      ],
    );
  }
}