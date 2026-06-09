// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/app_strings.dart';
import '../core/theme.dart';

/// Bottom sheet to search GIPHY and pick a GIF. Returns the chosen GIF URL via
/// Navigator.pop, or null if dismissed. GIFs come from the backend proxy
/// (/giphy/search) so the GIPHY key stays server-side. Shows the required
/// "Powered by GIPHY" attribution.
class GifPickerSheet extends StatefulWidget {
  const GifPickerSheet({super.key});

  /// Opens the picker and returns the selected GIF URL (or null).
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => const GifPickerSheet(),
    );
  }

  @override
  State<GifPickerSheet> createState() => _GifPickerSheetState();
}

class _GifPickerSheetState extends State<GifPickerSheet> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _gifs = [];
  bool _loading = true;
  String? _error;
  int _reqSeq = 0;

  @override
  void initState() {
    super.initState();
    _load(''); // trending on open
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _load(q.trim()));
  }

  Future<void> _load(String q) async {
    final seq = ++_reqSeq;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await context.read<ApiClient>().dio.get(
        '/giphy/search',
        queryParameters: {'q': q, 'limit': 24},
      );
      if (!mounted || seq != _reqSeq) return; // ignore stale responses
      setState(() {
        _gifs = (res.data as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted || seq != _reqSeq) return;
      setState(() { _error = context.tr('gif.error'); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: palette.slate200, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _search,
                autofocus: false,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: context.tr('gif.searchHint'),
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                ),
              ),
            ),
            Expanded(child: _body()),
            // Required GIPHY attribution.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text('Powered by GIPHY',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: palette.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading && _gifs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _gifs.isEmpty) {
      return Center(child: Text(_error!, style: TextStyle(color: context.palette.textMuted)));
    }
    if (_gifs.isEmpty) {
      return Center(child: Text(context.tr('gif.empty'),
          style: TextStyle(color: context.palette.textMuted)));
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.1),
      itemCount: _gifs.length,
      itemBuilder: (_, i) {
        final g = _gifs[i];
        final preview = g['preview'] as String?;
        final url = g['gif'] as String?;
        if (preview == null || url == null) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(url),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              preview,
              fit: BoxFit.cover,
              loadingBuilder: (c, child, p) => p == null
                  ? child
                  : Container(color: context.palette.slate100),
              errorBuilder: (c, e, s) => Container(
                color: context.palette.slate100,
                child: Icon(Icons.broken_image_outlined, color: context.palette.textMuted),
              ),
            ),
          ),
        );
      },
    );
  }
}
