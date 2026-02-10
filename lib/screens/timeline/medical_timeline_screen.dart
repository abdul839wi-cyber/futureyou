import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class MedicalTimelineScreen extends StatefulWidget {
  const MedicalTimelineScreen({super.key});

  @override
  State<MedicalTimelineScreen> createState() => _MedicalTimelineScreenState();
}

class _MedicalTimelineScreenState extends State<MedicalTimelineScreen> {
  bool _busy = false;
  String? _error;

  final _db = FirebaseFirestore.instance;

  // ✅ Gen-2 (Cloud Run) HTTPS URL (invokable now)
  static const String functionUrl =
      'https://processmedicalfiles-glppuqrjma-el.a.run.app';

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  Future<void> _openPdf(String url) async {
    try {
      final uri = Uri.parse(url);
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) _snack('Could not open PDF');
    } catch (_) {
      _snack('Could not open PDF');
    }
  }

  Future<void> _pickAndProcess() async {
    setState(() {
      _error = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = 'You must be logged in.');
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: true, // keeps bytes in memory (OK for MVP)
    );

    if (result == null || result.files.isEmpty) return;

    // Basic size guard (optional)
    final totalBytes = result.files.fold<int>(0, (sum, f) => sum + f.size);
    if (totalBytes > 20 * 1024 * 1024) {
      setState(
        () => _error =
            'Total file size too large for MVP. Try fewer/smaller PDFs.',
      );
      return;
    }

    setState(() => _busy = true);

    http.Client? client;
    try {
      final idToken = await user.getIdToken();

      final uri = Uri.parse(functionUrl);
      debugPrint('Calling: $uri');
      debugPrint('Host: ${uri.host}');

      final req = http.MultipartRequest('POST', uri);
      req.headers['Authorization'] = 'Bearer $idToken';

      int attached = 0;

      for (final f in result.files) {
        final bytes = f.bytes;
        if (bytes == null) continue;

        req.files.add(
          http.MultipartFile.fromBytes(
            'files', // must match server field name in busboy
            bytes,
            filename: f.name,
          ),
        );

        attached++;
      }

      if (attached == 0) {
        setState(() => _error = 'No readable PDF bytes found.');
        return;
      }

      client = http.Client();
      final streamed = await client.send(req);

      final respBytes = await streamed.stream.toBytes();
      final body = utf8.decode(respBytes);

      debugPrint('STATUS: ${streamed.statusCode}');
      debugPrint('BODY: ${_safeErr(body, max: 800)}');

      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        setState(
          () => _error =
              'Upload failed (${streamed.statusCode}).\n\n${_safeErr(body, max: 1800)}',
        );
        return;
      }

      final jsonBody = jsonDecode(body) as Map<String, dynamic>;
      final pdfUrl = (jsonBody['pdfUrl'] ?? '').toString();

      _snack('Processed ✅ Added to timeline');
      debugPrint('pdfUrl: $pdfUrl');

      // Optional: auto-open the latest PDF right after success
      // (comment out if you don't want this)
      if (pdfUrl.isNotEmpty) {
        await _openPdf(pdfUrl);
      }
    } catch (e) {
      setState(() => _error = 'Something went wrong.\n\n${e.toString()}');
    } finally {
      client?.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  String _safeErr(String s, {int max = 240}) {
    if (s.length <= max) return s;
    return '${s.substring(0, max)}…';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(),
                      const SizedBox(height: 16),
                      _uploadCard(),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        _errorCard(_error!),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        'RECENT ITEMS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: uid == null
                            ? _emptyState('Login to view your timeline.')
                            : StreamBuilder<
                                QuerySnapshot<Map<String, dynamic>>
                              >(
                                stream: _db
                                    .collection('users')
                                    .doc(uid)
                                    .collection('medicalTimeline')
                                    // ✅ your function stores createdAt
                                    .orderBy('createdAt', descending: true)
                                    .limit(25)
                                    .snapshots(),
                                builder: (context, snap) {
                                  if (snap.hasError) {
                                    return _emptyState(
                                      'Could not load timeline.',
                                    );
                                  }
                                  if (!snap.hasData) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  final docs = snap.data!.docs;
                                  if (docs.isEmpty) {
                                    return _emptyState(
                                      'No medical records yet. Upload your first PDF.',
                                    );
                                  }

                                  return ListView.separated(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    itemCount: docs.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, i) {
                                      final d = docs[i].data();
                                      return _timelineTile(d);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Medical Timeline',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Upload reports → get a clean summary PDF → save it as a timeline item.',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black.withOpacity(0.65),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _uploadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.upload_file_outlined,
                  color: Color(0xFF8E24AA),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Upload & Process PDFs',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Best for: lab reports, prescriptions, discharge summaries.',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy ? null : _pickAndProcess,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E24AA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(_busy ? 'Processing…' : 'Choose PDFs'),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: 16,
                color: Colors.black.withOpacity(0.55),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Privacy-first: secret stays on server. PDFs are processed securely.',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _errorCard(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.red.withOpacity(0.08),
        border: Border.all(color: Colors.red.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.error_outline, size: 18, color: Colors.red),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: SingleChildScrollView(
                child: Text(
                  msg,
                  style: const TextStyle(color: Colors.red, height: 1.25),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineTile(Map<String, dynamic> d) {
    final title = (d['title'] ?? 'Timeline Item').toString();
    final type = (d['eventType'] ?? 'document').toString();
    final processed = (d['aiProcessed'] ?? false) == true;

    String plain = '';
    final summary = d['summary'];
    if (summary is Map && summary['plainLanguage'] != null) {
      plain = summary['plainLanguage'].toString();
    }

    // Your function stores: sourceDocument.fileUrl
    final src = d['sourceDocument'];
    String? url;
    if (src is Map && src['fileUrl'] != null) url = src['fileUrl'].toString();

    final hasUrl = url != null && url!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: processed
                  ? const Color(0xFFE8F5E9)
                  : const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              processed
                  ? Icons.auto_awesome_outlined
                  : Icons.description_outlined,
              color: processed
                  ? const Color(0xFF2E7D32)
                  : const Color(0xFF1565C0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  plain.isEmpty ? 'Type: $type' : plain,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black.withOpacity(0.6),
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasUrl) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _openPdf(url!),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.open_in_new,
                                  size: 18,
                                  color: Color(0xFF1565C0),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Open / Download PDF',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF1565C0),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // ✅ Download icon button
                      IconButton(
                        onPressed: () => _openPdf(url!),
                        icon: const Icon(Icons.download_rounded),
                        tooltip: 'Download PDF',
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.black.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}
