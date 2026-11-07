import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/api/api_client.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/app_ui.dart';
import '../../../../../core/widgets/skeleton.dart';
import '../../../data/models/session_report_model.dart';
import '../../../data/models/consumption_report_model.dart';
import '../../../data/repositories/reports_repositories.dart';


class TelaRelatoriosDesktop extends StatefulWidget {
  const TelaRelatoriosDesktop({super.key, this.refreshSignal});


  final ValueListenable<int>? refreshSignal;

  @override
  State<TelaRelatoriosDesktop> createState() => _TelaRelatoriosDesktopState();
}

class _TelaRelatoriosDesktopState extends State<TelaRelatoriosDesktop> {
  late final ReportsRepository _reportsRepository;

  SessionReportModel? _sessionReport;
  ConsumptionReportModel? _consumptionReport;

  bool _isLoading = true;


  bool _isFetching = false;
  bool _isApiOffline = false;

  @override
  void initState() {
    super.initState();
    _reportsRepository = ReportsRepository(ApiClient.dio);
    widget.refreshSignal?.addListener(_fetchAllReports);
    _fetchAllReports();
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_fetchAllReports);
    super.dispose();
  }

  Future<void> _fetchAllReports() async {
    if (_isFetching) return;
    _isFetching = true;
    if (mounted) setState(() {});

    try {
      final (sessionRes, consumptionRes) = await (
        _reportsRepository.fetchSessionReport(),
        _reportsRepository.fetchConsumptionToday(),
      ).wait;

      if (!mounted) return;
      setState(() {
        _sessionReport = sessionRes;
        _consumptionReport = consumptionRes;
        _isApiOffline = false;
      });
    } on ParallelWaitError<dynamic, dynamic> catch (_) {
      if (mounted) setState(() => _isApiOffline = true);
    } on DioException catch (_) {
      if (mounted) setState(() => _isApiOffline = true);
    } catch (_) {
      if (mounted) setState(() => _isApiOffline = true);
    } finally {
      _isFetching = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesktopHeader(
            title: 'Dashboard',
            subtitle: 'Fluxo de visitantes e faturamento em tempo real.',
            trailing: HeaderButton(
              label: _isFetching && !_isLoading ? 'Atualizando...' : 'Atualizar dados',
              icon: Icons.refresh_rounded,
              onPressed: _isFetching
                  ? null
                  : () {
                      HapticFeedback.lightImpact();
                      _fetchAllReports();
                    },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const _DashboardSkeleton()
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(36, 8, 36, 36),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _KpiCard(
                                title: 'Sessões ativas',
                                value: '${_sessionReport?.activeSessions ?? 0}',
                                subtitle: 'Visitantes no parque agora',
                                icon: Icons.people_alt_rounded,
                                color: AppTheme.primary,
                                highlight: true,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _KpiCard(
                                title: 'Check-ins hoje',
                                value: '${_sessionReport?.sessionsCreatedToday ?? 0}',
                                subtitle: 'Entradas registradas',
                                icon: Icons.today_rounded,
                                color: AppTheme.accentInk,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _KpiCard(
                                title: 'Faturamento hoje',
                                value: 'R\$ ${_consumptionReport?.total ?? "0.00"}',
                                subtitle: _consumptionReport?.date.isNotEmpty == true
                                    ? 'Data: ${_consumptionReport!.date}'
                                    : 'Atualizado hoje',
                                icon: Icons.payments_rounded,
                                color: AppTheme.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: AppCard(
                                padding: const EdgeInsets.all(28),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _CardTitle(title: 'Atividade do parque', icon: Icons.bar_chart_rounded),
                                    const SizedBox(height: 24),
                                    _MetricStatRow(
                                      label: 'Sessões ativas no momento',
                                      value: '${_sessionReport?.activeSessions ?? 0}',
                                      icon: Icons.directions_walk_rounded,
                                      color: AppTheme.primary,
                                    ),
                                    const Divider(height: 32),
                                    _MetricStatRow(
                                      label: 'Novas sessões hoje',
                                      value: '${_sessionReport?.sessionsCreatedToday ?? 0}',
                                      icon: Icons.add_business_rounded,
                                      color: AppTheme.accentInk,
                                    ),
                                    const Divider(height: 32),
                                    _MetricStatRow(
                                      label: 'Consumo total do dia',
                                      value: 'R\$ ${_consumptionReport?.total ?? "0.00"}',
                                      icon: Icons.account_balance_wallet_rounded,
                                      color: AppTheme.success,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              flex: 2,
                              child: AppCard(
                                padding: const EdgeInsets.all(28),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _CardTitle(
                                      title: 'Status de conexão',
                                      icon: _isApiOffline
                                          ? Icons.error_outline_rounded
                                          : Icons.check_circle_outline_rounded,
                                      color: _isApiOffline ? AppTheme.danger : AppTheme.success,
                                    ),
                                    const SizedBox(height: 24),
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
    );
  }
}


class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget kpi() => Container(
          height: 168,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.border),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SkeletonBox(width: 48, height: 48, radius: 16),
                  SizedBox(width: 14),
                  SkeletonBox(width: 120, height: 14),
                ],
              ),
              Spacer(),
              SkeletonBox(width: 90, height: 34),
              SizedBox(height: 8),
              SkeletonBox(width: 160, height: 12),
            ],
          ),
        );

    Widget row() => const Row(
          children: [
            SkeletonBox(width: 46, height: 46, radius: 14),
            SizedBox(width: 16),
            Expanded(child: Align(alignment: Alignment.centerLeft, child: SkeletonBox(width: 200))),
            SkeletonBox(width: 70, height: 22),
          ],
        );

    Widget card(int flex) => Expanded(
          flex: flex,
          child: AppCard(
            shadow: false,
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 180, height: 22),
                const SizedBox(height: 24),
                row(),
                const Divider(height: 32),
                row(),
                const Divider(height: 32),
                row(),
              ],
            ),
          ),
        );

    return SkeletonPulse(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(36, 8, 36, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: kpi()),
                const SizedBox(width: 20),
                Expanded(child: kpi()),
                const SizedBox(width: 20),
                Expanded(child: kpi()),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [card(3), const SizedBox(width: 24), card(2)],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTitle extends StatelessWidget {
  const _CardTitle({required this.title, required this.icon, this.color = AppTheme.primary});

  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTheme.display(size: 22, color: AppTheme.textDark))),
        Icon(icon, color: color, size: 28),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool highlight;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = highlight ? Colors.white : AppTheme.textDark;
    final muted = highlight ? Colors.white.withValues(alpha: 0.85) : AppTheme.textMuted;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: highlight ? null : Colors.white,
        gradient: highlight
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.primary, AppTheme.navy],
              )
            : null,
        borderRadius: BorderRadius.circular(24),
        border: highlight ? null : Border.all(color: AppTheme.border),
        boxShadow: highlight ? AppTheme.coloredShadow(AppTheme.primary) : AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: highlight ? AppTheme.accent : color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: highlight ? AppTheme.onAccent : color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(value, style: AppTheme.display(size: 36, color: fg)),
          Text(subtitle, style: TextStyle(fontSize: 13.5, color: muted)),
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
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        Text(value, style: AppTheme.display(size: 22, color: color)),
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
      children: [
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
        StatusPill(
          label: status,
          icon: isOk ? Icons.check_circle_rounded : Icons.error_rounded,
          tone: isOk ? AppTone.success : AppTone.danger,
        ),
      ],
    );
  }
}
