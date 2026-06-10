// TeamUp - team-matching social network
// Copyright (C) 2026 Team 28
// Licensed under the GNU Affero General Public License v3.0 (see LICENSE).

import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../../core/app_strings.dart';

/// Full-screen circular cropper for the profile photo. Pops with the cropped
/// PNG bytes (or null if cancelled). Pure-Dart (no native uCrop dependency).
class CropAvatarScreen extends StatefulWidget {
  final Uint8List imageBytes;
  const CropAvatarScreen({super.key, required this.imageBytes});

  @override
  State<CropAvatarScreen> createState() => _CropAvatarScreenState();
}

class _CropAvatarScreenState extends State<CropAvatarScreen> {
  final _controller = CropController();
  bool _cropping = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(context.tr('crop.title')),
        actions: [
          if (_cropping)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: context.tr('common.confirm'),
              onPressed: () {
                setState(() => _cropping = true);
                _controller.crop();
              },
            ),
        ],
      ),
      body: Crop(
        image: widget.imageBytes,
        controller: _controller,
        aspectRatio: 1,
        withCircleUi: true,
        // Show the WHOLE image from the start (no auto-zoom on a portion); the
        // user frames by moving/resizing the circular crop area over it.
        baseColor: Colors.black,
        maskColor: Colors.black.withAlpha(150),
        cornerDotBuilder: (size, edge) => _CornerHandle(edge: edge),
        onCropped: (result) {
          switch (result) {
            case CropSuccess(:final croppedImage):
              Navigator.of(context).pop(croppedImage);
            case CropFailure():
              setState(() => _cropping = false);
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(context.tr('common.error'))));
          }
        },
      ),
    );
  }
}

/// L-shaped corner handle (two white strokes) instead of the default round dot.
class _CornerHandle extends StatelessWidget {
  final EdgeAlignment edge;
  const _CornerHandle({required this.edge});

  @override
  Widget build(BuildContext context) {
    const color = Colors.white;
    const w = 3.0;
    final top = edge == EdgeAlignment.topLeft || edge == EdgeAlignment.topRight;
    final left = edge == EdgeAlignment.topLeft || edge == EdgeAlignment.bottomLeft;
    const side = BorderSide(color: color, width: w);
    const none = BorderSide.none;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        border: Border(
          top: top ? side : none,
          bottom: top ? none : side,
          left: left ? side : none,
          right: left ? none : side,
        ),
      ),
    );
  }
}
