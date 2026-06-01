// TeamUp - student team-matching app
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/app_strings.dart';
import '../../design_system/ds.dart';
import '../../providers/feed_provider.dart';

/// Bottom sheet to compose a new post (text and/or an image). Pops on success.
class CreatePostSheet extends StatefulWidget {
  const CreatePostSheet({super.key});

  @override
  State<CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final _ctrl = TextEditingController();
  String _type = 'general';
  bool _busy = false;

  Uint8List? _imageBytes; // preview
  String? _imageDataUrl; // sent to the backend

  static const _typeCodes = [
    'general',
    'project_launch',
    'team_update',
    'looking_for',
    'milestone',
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 70,
    );
    if (x == null) return;
    final bytes = await x.readAsBytes();
    if (!mounted) return;
    setState(() {
      _imageBytes = bytes;
      _imageDataUrl = 'data:${x.mimeType ?? 'image/jpeg'};base64,${base64Encode(bytes)}';
    });
  }

  Future<void> _submit() async {
    final content = _ctrl.text.trim();
    // A post needs text OR an image.
    if (content.isEmpty && _imageDataUrl == null) return;
    setState(() => _busy = true);
    final ok = await context
        .read<FeedProvider>()
        .createPost(type: _type, content: content, image: _imageDataUrl);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('feed.publishFail'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPost = _ctrl.text.trim().isNotEmpty || _imageDataUrl != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('feed.newPost'), style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final code in _typeCodes)
                ChoiceChip(
                  label: Text(context.tr('posttype.$code')),
                  selected: _type == code,
                  onSelected: (_) => setState(() => _type = code),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            minLines: 3,
            maxLines: 6,
            maxLength: 4000,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(hintText: context.tr('feed.composeHint')),
          ),
          // ── Image preview (with a remove button) ────────────────────────────
          if (_imageBytes != null) ...[
            const SizedBox(height: 12),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(_imageBytes!,
                      width: double.infinity, height: 180, fit: BoxFit.cover),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () => setState(() {
                      _imageBytes = null;
                      _imageDataUrl = null;
                    }),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: _busy ? null : _pickImage,
                icon: const Icon(Icons.image_outlined, size: 20),
                label: Text(context.tr(_imageBytes == null ? 'feed.addImage' : 'feed.changeImage')),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppButton(
            onPressed: (_busy || !canPost) ? null : _submit,
            child: _busy
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(context.tr('feed.publish')),
          ),
        ],
      ),
    );
  }
}
