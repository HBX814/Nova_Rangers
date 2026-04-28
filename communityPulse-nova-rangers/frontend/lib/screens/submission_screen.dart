import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:shimmer/shimmer.dart';

import '../services/api_service.dart';

class _Org {
  const _Org({required this.id, required this.name});
  final String id;
  final String name;
}

// ── Screen ──────────────────────────────────────────────────────────────────

class SubmissionScreen extends ConsumerStatefulWidget {
  const SubmissionScreen({super.key});

  @override
  ConsumerState<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends ConsumerState<SubmissionScreen> {
  // ── State ──────────────────────────────────────────────────────────────────

  final _formKey = GlobalKey<FormState>();
  final _submittedByController =
      TextEditingController(text: 'field.officer@communitypulse.in');

  String? _selectedOrgId;
  XFile? _pickedFile;

  bool _isUploading = false;
  String? _uploadError;
  List<_Org> _organizations = [];
  bool _isLoadingOrganizations = true;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
  }

  @override
  void dispose() {
    _submittedByController.dispose();
    super.dispose();
  }

  Future<void> _loadOrganizations() async {
    setState(() {
      _isLoadingOrganizations = true;
    });
    try {
      final orgs = await ApiService.instance.fetchOrganizations();
      if (!mounted) return;
      setState(() {
        _organizations = orgs
            .map((org) => _Org(
                  id: (org['org_id'] ?? org['id'] ?? '').toString(),
                  name: (org['name'] ?? 'Unnamed organization').toString(),
                ))
            .where((org) => org.id.isNotEmpty)
            .toList();
        _isLoadingOrganizations = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _organizations = [];
        _isLoadingOrganizations = false;
      });
    }
  }

  // ── File picker ────────────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    final platformFile = result?.files.single;
    final bytes = platformFile?.bytes;
    if (platformFile == null || bytes == null) {
      return;
    }
    final XFile file = XFile.fromData(
      bytes,
      name: platformFile.name,
      mimeType: _mimeTypeFromName(platformFile.name),
    );
    setState(() {
      _pickedFile = file;
      _uploadError = null;
    });
    }

  String _mimeTypeFromName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }

  // ── Upload ─────────────────────────────────────────────────────────────────

  Future<void> _handleUpload() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_pickedFile == null) {
      setState(() => _uploadError = 'Please select a file before uploading.');
      return;
    }
    if (_selectedOrgId == null || _selectedOrgId!.isEmpty) {
      setState(() => _uploadError = 'Please select an organisation.');
      return;
    }

    final pickedFile = _pickedFile!;
    final selectedOrgId = _selectedOrgId!;

    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      final result = await ApiService.instance.uploadSubmission(
        pickedFile,
        selectedOrgId,
        _submittedByController.text.trim(),
      );

      if (!mounted) return;
      setState(() => _isUploading = false);

      final submissionId =
          (result['submission_id'] ?? result['id'] ?? 'N/A').toString();
      final status = (result['status'] ?? 'queued').toString();

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _SuccessDialog(
          submissionId: submissionId,
          status: status,
          onDone: () {
            Navigator.of(ctx).pop();
            // Reset form for another submission
            setState(() {
              _pickedFile = null;
              _selectedOrgId = null;
              _uploadError = null;
            });
            _formKey.currentState?.reset();
          },
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _uploadError = e.toString();
      });
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0A1628), Color(0xFF1565C0)],
            ),
          ),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFF90CAF9)],
          ).createShader(bounds),
          child: const Text(
            'Submit Field Report',
            style: TextStyle(color: Colors.white),
          ),
        ),
        centerTitle: false,
      ),
      body: _isUploading ? _buildUploadingShimmer() : _buildForm(context, cs),
    );
  }

  // ── Upload shimmer ─────────────────────────────────────────────────────────

  Widget _buildUploadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _shimBox(w: 200, h: 28),
            const SizedBox(height: 24),
            _shimBox(w: double.infinity, h: 56),
            const SizedBox(height: 16),
            _shimBox(w: double.infinity, h: 56),
            const SizedBox(height: 16),
            _shimBox(w: double.infinity, h: 100),
            const SizedBox(height: 24),
            _shimBox(w: double.infinity, h: 52),
          ],
        ),
      ),
    );
  }

  Widget _shimBox({required double w, required double h}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      );

  // ── Form ───────────────────────────────────────────────────────────────────

  Widget _buildForm(BuildContext context, ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Section header ────────────────────────────────────────────
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFF90CAF9)],
              ).createShader(bounds),
              child: const Text(
                'Upload a Field Report',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Attach a JSON report file collected in the field. '
              'Our AI agents will classify, deduplicate and route it automatically.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B8CAE),
              ),
            ),
            const SizedBox(height: 24),

            // ── Submitter (current-user) ───────────────────────────────────
            TextFormField(
              controller: _submittedByController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Submitted by (email / user ID)',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter a submitter identifier.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // ── Organisation dropdown ──────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A2744),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF2A4A7F), width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedOrgId,
                dropdownColor: const Color(0xFF1A2744),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Organisation',
                  labelStyle: TextStyle(color: Color(0xFF6B8CAE)),
                  prefixIcon: Icon(Icons.business_outlined, color: Color(0xFF6B8CAE)),
                  border: InputBorder.none,
                ),
                items: _organizations
                    .map(
                      (org) => DropdownMenuItem(
                        value: org.id,
                        child: Text(org.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedOrgId = v),
                validator: (v) => v == null || v.isEmpty
                    ? 'Please select an organisation.'
                    : null,
              ),
            ),
            if (_isLoadingOrganizations) ...[
              const SizedBox(height: 8),
              const Text(
                'Loading organisations...',
                style: TextStyle(fontSize: 12),
              ),
            ] else if (_organizations.isEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'No organisations available from backend.',
                style: TextStyle(fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),

            // ── File picker ───────────────────────────────────────────────
            _FilePicker(
              file: _pickedFile,
              onPick: _pickFile,
              cs: cs,
            ),

            // ── Error banner ──────────────────────────────────────────────
            if (_uploadError != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(
                message: _uploadError!,
                onRetry: _handleUpload,
              ),
            ],

            const SizedBox(height: 28),

            // ── Upload button ─────────────────────────────────────────────
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1565C0).withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FilledButton(
                onPressed: _isUploading ? null : _handleUpload,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Upload Report',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── FilePicker widget ─────────────────────────────────────────────────────────

class _FilePicker extends StatelessWidget {
  const _FilePicker({
    required this.file,
    required this.onPick,
    required this.cs,
  });

  final XFile? file;
  final VoidCallback onPick;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null;

    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A2744), Color(0xFF0F1B2D)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: hasFile
              ? Border.all(color: const Color(0xFF4CAF50), width: 1.5)
              : null,
        ),
        child: CustomPaint(
          painter: hasFile
              ? null
              : _DashedBorderPainter(
                  color: const Color(0xFF2A5298),
                  dashWidth: 8,
                  dashSpace: 4,
                  radius: 20,
                ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1565C0).withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.cloud_upload,
                      size: 56,
                      color: hasFile
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    hasFile
                        ? file!.name
                        : 'Tap to select a file (PDF / JPEG / PNG)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: hasFile ? FontWeight.w600 : FontWeight.normal,
                      color: hasFile
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF6B8CAE),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.dashWidth,
    required this.dashSpace,
    required this.radius,
  });

  final Color color;
  final double dashWidth;
  final double dashSpace;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.75, 0.75, size.width - 1.5, size.height - 1.5),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = (distance + dashWidth).clamp(0, metric.length);
        canvas.drawPath(metric.extractPath(distance, next.toDouble()), paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.dashWidth != dashWidth ||
      oldDelegate.dashSpace != dashSpace ||
      oldDelegate.radius != radius;
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.errorContainer.withValues(alpha: 0.35),
        border: Border.all(color: cs.error.withValues(alpha: 0.5), width: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: cs.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload failed',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: cs.onErrorContainer),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                      fontSize: 11,
                      color: cs.onErrorContainer.withValues(alpha: 0.8)),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: cs.error,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

// ── Success dialog ────────────────────────────────────────────────────────────

class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog({
    required this.submissionId,
    required this.status,
    required this.onDone,
  });

  final String submissionId;
  final String status;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2E7D32),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Report Submitted!',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Your field report has been queued for AI processing.',
              style: TextStyle(
                  fontSize: 13, color: cs.onSurface.withValues(alpha: 0.6)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Submission ID card
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Submission ID',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.5),
                        letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    submissionId,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: Color(0xFF2E7D32)),
                      const SizedBox(width: 6),
                      Text(
                        'Status: ${status.toUpperCase()}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E7D32)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Done button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onDone,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
