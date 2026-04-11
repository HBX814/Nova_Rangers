import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

import '../services/api_service.dart';

// ── Organisation list (replace with a live /organisations fetch if available) ─

const _kOrganisations = [
  _Org(id: 'org_001', name: 'Madhya Pradesh Relief Fund'),
  _Org(id: 'org_002', name: 'Jan Seva Foundation'),
  _Org(id: 'org_003', name: 'Bhopal Aid Society'),
  _Org(id: 'org_004', name: 'Narmada Sewa Samiti'),
  _Org(id: 'org_005', name: 'Rural Health Initiative'),
];

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

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _submittedByController.dispose();
    super.dispose();
  }

  // ── File picker ────────────────────────────────────────────────────────────

  Future<void> _pickFile() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() {
        _pickedFile = file;
        _uploadError = null;
      });
    }
  }

  // ── Upload ─────────────────────────────────────────────────────────────────

  Future<void> _handleUpload() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_pickedFile == null) {
      setState(() => _uploadError = 'Please select a file before uploading.');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadError = null;
    });

    try {
      final result = await ApiService.instance.uploadSubmission(
        _pickedFile!.path,
        _selectedOrgId!,
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
      appBar: AppBar(
        title: const Text('Submit Field Report'),
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
            Text(
              'Upload a Field Report',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Attach a JSON report file collected in the field. '
              'Our AI agents will classify, deduplicate and route it automatically.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: cs.onSurface.withOpacity(0.55)),
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
            DropdownButtonFormField<String>(
              value: _selectedOrgId,
              decoration: const InputDecoration(
                labelText: 'Organisation',
                prefixIcon: Icon(Icons.business_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
              items: _kOrganisations
                  .map(
                    (org) => DropdownMenuItem(
                      value: org.id,
                      child: Text(org.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedOrgId = v),
              validator: (v) =>
                  v == null ? 'Please select an organisation.' : null,
            ),
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
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: _isUploading ? null : _handleUpload,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: const Text(
                  'Upload Report',
                  style: TextStyle(fontSize: 16),
                ),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: hasFile
              ? cs.primaryContainer.withOpacity(0.4)
              : cs.surfaceContainerHighest.withOpacity(0.35),
          border: Border.all(
            color: hasFile
                ? cs.primary.withOpacity(0.6)
                : cs.onSurface.withOpacity(0.25),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              hasFile ? Icons.insert_drive_file : Icons.upload_file,
              size: 36,
              color: hasFile ? cs.primary : cs.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 8),
            Text(
              hasFile
                  ? File(file!.path).uri.pathSegments.last
                  : 'Tap to select a file (JSON / image)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: hasFile ? FontWeight.w600 : FontWeight.normal,
                color: hasFile ? cs.primary : cs.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (hasFile) ...[
              const SizedBox(height: 4),
              Text(
                'Tap to change',
                style: TextStyle(
                    fontSize: 11, color: cs.onSurface.withOpacity(0.4)),
              ),
            ],
          ],
        ),
      ),
    );
  }
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
        color: cs.errorContainer.withOpacity(0.35),
        border: Border.all(color: cs.error.withOpacity(0.5), width: 0.8),
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
                      color: cs.onErrorContainer.withOpacity(0.8)),
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
                color: const Color(0xFF2E7D32).withOpacity(0.12),
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
                  fontSize: 13, color: cs.onSurface.withOpacity(0.6)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Submission ID card
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withOpacity(0.5),
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
                        color: cs.onSurface.withOpacity(0.5),
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
