// TeamUp - student team-matching app
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
        baseColor: Colors.black,
        maskColor: Colors.black.withAlpha(150),
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
