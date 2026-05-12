import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../providers/gamification_provider.dart';

class CertificateScreen extends ConsumerStatefulWidget {
  const CertificateScreen({super.key});

  @override
  ConsumerState<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends ConsumerState<CertificateScreen> {
  bool _generating = false;

  Future<void> _generateAndShare() async {
    setState(() => _generating = true);
    try {
      final user = ref.read(currentUserProvider);
      final gs   = ref.read(gamificationNotifierProvider);
      final g    = gs.data;
      final name = user?.name ?? 'Élève Yikri';
      final level = g?.level ?? 1;
      final xp    = g?.totalXp ?? 0;
      final badges = g?.unlockedBadgeIds.length ?? 0;
      final date  = DateTime.now();

      final pdf = pw.Document();

      pdf.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context ctx) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(
                color: const PdfColor.fromInt(0xFF7B2D8B), width: 4),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Header
                pw.Text('YIKRI',
                    style: pw.TextStyle(
                        fontSize: 36, fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF7B2D8B))),
                pw.SizedBox(height: 4),
                pw.Text('Plateforme Éducative — Burkina Faso',
                    style: pw.TextStyle(fontSize: 12,
                        color: const PdfColor.fromInt(0xFF666666))),

                pw.SizedBox(height: 20),
                pw.Divider(color: const PdfColor.fromInt(0xFF7B2D8B), thickness: 1.5),
                pw.SizedBox(height: 20),

                // Title
                pw.Text('CERTIFICAT DE PROGRESSION',
                    style: pw.TextStyle(
                        fontSize: 22, fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF333333))),
                pw.SizedBox(height: 8),
                pw.Text('Ce certificat est décerné à',
                    style: pw.TextStyle(fontSize: 14,
                        color: const PdfColor.fromInt(0xFF666666))),

                pw.SizedBox(height: 16),

                // Student name
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFF3E5F5),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(name,
                      style: pw.TextStyle(
                          fontSize: 28, fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF4A148C))),
                ),

                pw.SizedBox(height: 20),
                pw.Text(
                    'pour sa progression et ses efforts sur la plateforme Yikri.',
                    style: pw.TextStyle(fontSize: 13,
                        color: const PdfColor.fromInt(0xFF555555))),

                pw.SizedBox(height: 24),

                // Stats row
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    _pdfStat('NIVEAU', '$level'),
                    _pdfStat('POINTS XP', '$xp'),
                    _pdfStat('BADGES', '$badges'),
                  ],
                ),

                pw.SizedBox(height: 24),
                pw.Divider(color: const PdfColor.fromInt(0xFFCCCCCC), thickness: 0.5),
                pw.SizedBox(height: 12),

                // Footer
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                        'Ouagadougou, le ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                        style: pw.TextStyle(fontSize: 11,
                            color: const PdfColor.fromInt(0xFF888888))),
                    pw.Text('yikri.app — Apprendre partout, toujours',
                        style: pw.TextStyle(fontSize: 11,
                            color: const PdfColor.fromInt(0xFF888888))),
                  ],
                ),
              ],
            ),
          );
        },
      ));

      final bytes = await pdf.save();
      await Printing.sharePdf(
          bytes: bytes,
          filename: 'certificat_yikri_$name.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur génération PDF : $e')));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  pw.Widget _pdfStat(String label, String value) => pw.Column(children: [
    pw.Text(value,
        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF7B2D8B))),
    pw.SizedBox(height: 4),
    pw.Text(label,
        style: pw.TextStyle(fontSize: 10,
            color: const PdfColor.fromInt(0xFF888888))),
  ]);

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final gs   = ref.watch(gamificationNotifierProvider);
    final g    = gs.data;
    final name = user?.name ?? 'Élève Yikri';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon Certificat'),
        backgroundColor: AppColors.levelPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          // Preview card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.levelPurple, Color(0xFF4A148C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(children: [
              // Yikri header
              const Text('YIKRI',
                  style: TextStyle(
                      color: Colors.white, fontFamily: 'Nunito',
                      fontSize: 28, fontWeight: FontWeight.w900,
                      letterSpacing: 4)),
              const SizedBox(height: 4),
              const Text('Plateforme Éducative — Burkina Faso',
                  style: TextStyle(color: Colors.white60, fontFamily: 'Nunito', fontSize: 11)),
              const SizedBox(height: 20),
              const Divider(color: Colors.white24),
              const SizedBox(height: 16),
              const Text('CERTIFICAT DE PROGRESSION',
                  style: TextStyle(
                      color: AppColors.xpGold, fontFamily: 'Nunito',
                      fontSize: 16, fontWeight: FontWeight.w800,
                      letterSpacing: 2)),
              const SizedBox(height: 12),
              const Text('Ce certificat est décerné à',
                  style: TextStyle(color: Colors.white70, fontFamily: 'Nunito', fontSize: 13)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(name,
                    style: const TextStyle(
                        color: Colors.white, fontFamily: 'Nunito',
                        fontSize: 22, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 16),
              const Text('pour sa progression et ses efforts sur Yikri.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontFamily: 'Nunito', fontSize: 13)),
              const SizedBox(height: 24),
              // Stats
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                _StatBadge(label: 'Niveau', value: '${g?.level ?? 1}'),
                _StatBadge(label: 'XP Total', value: '${g?.totalXp ?? 0}'),
                _StatBadge(label: 'Badges', value: '${g?.unlockedBadgeIds.length ?? 0}'),
              ]),
              const SizedBox(height: 20),
              const Divider(color: Colors.white12),
              const SizedBox(height: 10),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(
                  'Ouagadougou, ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: const TextStyle(
                      color: Colors.white38, fontFamily: 'Nunito', fontSize: 11),
                ),
                const Text('yikri.app',
                    style: TextStyle(
                        color: Colors.white38, fontFamily: 'Nunito', fontSize: 11)),
              ]),
            ]),
          ),

          const SizedBox(height: 24),

          // Info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.levelPurple.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.levelPurple.withOpacity(0.15)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded, color: AppColors.levelPurple, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text(
                'Le certificat est généré en PDF et peut être partagé, imprimé ou envoyé à tes parents.',
                style: TextStyle(fontFamily: 'Nunito', fontSize: 12,
                    color: AppColors.levelPurple, height: 1.4),
              )),
            ]),
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _generating ? null : _generateAndShare,
              icon: _generating
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.share_rounded),
              label: Text(
                _generating ? 'Génération...' : 'Générer et partager le PDF',
                style: const TextStyle(
                    fontFamily: 'Nunito', fontWeight: FontWeight.w800, fontSize: 15),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.levelPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),

          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label, value;
  const _StatBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value,
        style: const TextStyle(
            color: AppColors.xpGold, fontFamily: 'Nunito',
            fontSize: 24, fontWeight: FontWeight.w900)),
    const SizedBox(height: 2),
    Text(label,
        style: const TextStyle(
            color: Colors.white60, fontFamily: 'Nunito', fontSize: 11)),
  ]);
}
