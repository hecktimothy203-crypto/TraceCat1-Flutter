from pathlib import Path

path = Path('lib/trace_workspace.dart')
source = path.read_text(encoding='utf-8')


def replace_once(old: str, new: str, label: str) -> None:
    global source
    if old not in source:
        raise RuntimeError(f'Could not locate {label}.')
    source = source.replace(old, new, 1)


old_grid_button = '''                  Expanded(
                    child: _smallButton(
                      label:
                          _gridEnabled ? 'Grid On' : 'Grid',
                      active: _gridEnabled,
                      onPressed: () {
                        setState(
                          () => _gridEnabled = !_gridEnabled,
                        );

                        _setStatus(
                          _gridEnabled
                              ? 'Tracing grid on'
                              : 'Tracing grid off',
                        );
                      },
                    ),
                  ),
'''

new_match_button = '''                  Expanded(
                    child: _smallButton(
                      label: 'Match Lines',
                      onPressed: project == null || _busy
                          ? null
                          : () => unawaited(_matchLines()),
                    ),
                  ),
'''

replace_once(
    old_grid_button,
    new_match_button,
    'the Grid control button',
)

old_help = r'''            'The grid is a visual guide only. It can be turned on or off without '
            'changing the imported image.\n\n'
            'Projects and images stay on this phone. Surface AR is planned for a '
'''

new_help = r'''            'Match Lines compares the overlay with dark pencil lines already on '
            'the paper. Position the image close first, then tap Match Lines for '
            'a fine correction of position, size, and angle.\n\n'
            'Projects and images stay on this phone. Surface AR is planned for a '
'''

replace_once(
    old_help,
    new_help,
    'the Grid help paragraph',
)

line_match_methods = r'''  Future<List<LineMatchPoint>> _buildLineMatchPoints() async {
    final image = _templateInfo;
    if (image == null) {
      throw StateError('tracing image is not loaded');
    }

    final rgba = await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    if (rgba == null) {
      throw StateError('tracing image could not be read');
    }

    final bytes = rgba.buffer.asUint8List();
    final aspect = image.width / image.height;
    final sampleWidth = math.min(280, image.width).toInt();
    final sampleHeight = math.max(
      1,
      (sampleWidth / aspect).round(),
    ).toInt();

    final points = <LineMatchPoint>[];
    const step = 2;

    for (var y = 0; y < sampleHeight; y += step) {
      final sourceY = math.min(
        image.height - 1,
        (y * image.height / sampleHeight).floor(),
      ).toInt();

      for (var x = 0; x < sampleWidth; x += step) {
        final sourceX = math.min(
          image.width - 1,
          (x * image.width / sampleWidth).floor(),
        ).toInt();
        final index = (sourceY * image.width + sourceX) * 4;
        final alpha = bytes[index + 3] / 255.0;
        final red = bytes[index] * alpha + 255 * (1 - alpha);
        final green = bytes[index + 1] * alpha + 255 * (1 - alpha);
        final blue = bytes[index + 2] * alpha + 255 * (1 - alpha);
        final gray = red * 0.299 + green * 0.587 + blue * 0.114;

        if (gray < 90) {
          points.add(
            LineMatchPoint(
              x / sampleWidth - 0.5,
              y / sampleHeight - 0.5,
            ),
          );
        }
      }
    }

    if (points.length < 40) {
      throw StateError('the tracing image does not have enough dark lines');
    }

    const maximumPoints = 1600;
    if (points.length <= maximumPoints) {
      return points;
    }

    final stride = (points.length / maximumPoints).ceil();
    return <LineMatchPoint>[
      for (var index = 0; index < points.length; index += stride)
        points[index],
    ];
  }

  LineMatchFrame _prepareLineMatchFrame(GrayFrame frame) {
    if (_stageSize.isEmpty) {
      throw StateError('camera view is not ready');
    }

    const width = 260;
    final height = math.max(
      180,
      (width * _stageSize.height / _stageSize.width).round(),
    ).toInt();
    final sampled = Float32List(width * height);

    final coverScale = math.max(
      _stageSize.width / frame.width,
      _stageSize.height / frame.height,
    );
    final renderedWidth = frame.width * coverScale;
    final renderedHeight = frame.height * coverScale;
    final offsetX = (_stageSize.width - renderedWidth) / 2;
    final offsetY = (_stageSize.height - renderedHeight) / 2;

    var total = 0.0;
    for (var y = 0; y < height; y++) {
      final screenY = (y + 0.5) * _stageSize.height / height;
      final sourceY = ((screenY - offsetY) / coverScale)
          .round()
          .clamp(0, frame.height - 1)
          .toInt();

      for (var x = 0; x < width; x++) {
        final screenX = (x + 0.5) * _stageSize.width / width;
        final sourceX = ((screenX - offsetX) / coverScale)
            .round()
            .clamp(0, frame.width - 1)
            .toInt();
        final value = frame.gray[sourceY * frame.width + sourceX].toDouble();
        sampled[y * width + x] = value;
        total += value;
      }
    }

    final mean = total / sampled.length;
    final darkness = Float32List(sampled.length);

    for (var index = 0; index < sampled.length; index++) {
      darkness[index] = ((mean - sampled[index] - 4) / 65)
          .clamp(0.0, 1.0)
          .toDouble();
    }

    final spread = Float32List(darkness.length);
    for (var y = 1; y < height - 1; y++) {
      for (var x = 1; x < width - 1; x++) {
        var strongest = 0.0;
        for (var offsetY = -1; offsetY <= 1; offsetY++) {
          for (var offsetX = -1; offsetX <= 1; offsetX++) {
            strongest = math.max(
              strongest,
              darkness[(y + offsetY) * width + x + offsetX],
            ).toDouble();
          }
        }
        spread[y * width + x] = strongest;
      }
    }

    return LineMatchFrame(
      width: width,
      height: height,
      darkness: spread,
    );
  }

  double _scoreLineMatchCandidate(
    LineMatchFrame camera,
    LineMatchCandidate candidate,
    List<LineMatchPoint> points,
    double baseWidth,
    double aspect,
  ) {
    final imageWidth = baseWidth * candidate.scale;
    final imageHeight = imageWidth / aspect;
    final cosine = math.cos(candidate.rotation);
    final sine = math.sin(candidate.rotation);
    final screenToCameraX = camera.width / _stageSize.width;
    final screenToCameraY = camera.height / _stageSize.height;

    var total = 0.0;
    var count = 0;

    for (final point in points) {
      final localX = point.x * imageWidth;
      final localY = point.y * imageHeight;
      final screenX = candidate.centerX + localX * cosine - localY * sine;
      final screenY = candidate.centerY + localX * sine + localY * cosine;
      final cameraX = (screenX * screenToCameraX).round();
      final cameraY = (screenY * screenToCameraY).round();

      if (cameraX > 1 &&
          cameraY > 1 &&
          cameraX < camera.width - 2 &&
          cameraY < camera.height - 2) {
        total += camera.darkness[cameraY * camera.width + cameraX];
        count++;
      }
    }

    return count == 0 ? 0 : total / count;
  }

  Future<void> _matchLines() async {
    final project = _project;
    final image = _templateInfo;
    final controller = _camera;

    if (project == null || image == null) {
      _setStatus('Import an image before using Match Lines');
      return;
    }
    if (controller == null || !controller.value.isInitialized) {
      _setStatus('Start the camera before using Match Lines');
      return;
    }
    if (_stageSize.isEmpty) {
      _setStatus('Camera view is not ready');
      return;
    }
    if (project.view.anchorQuad != null) {
      _setStatus('Reset View before using Match Lines');
      return;
    }
    if (_busy) return;

    setState(() => _busy = true);
    _setStatus(
      'Comparing the image with your drawn lines...',
      hold: Duration.zero,
    );

    await Future<void>.delayed(const Duration(milliseconds: 60));

    try {
      final frame = await _captureGrayFrame();
      final camera = _prepareLineMatchFrame(frame);
      final points = await _buildLineMatchPoints();
      final view = project.view;
      final aspect = image.width / image.height;
      final baseWidth = view.baseWidth * _stageSize.width;

      final original = LineMatchCandidate(
        centerX: view.centerX * _stageSize.width,
        centerY: view.centerY * _stageSize.height,
        scale: view.scale,
        rotation: view.rotation,
      );
      original.score = _scoreLineMatchCandidate(
        camera,
        original,
        points,
        baseWidth,
        aspect,
      );

      var best = original.copy();
      const coarseOffsets = <double>[-30, -20, -10, 0, 10, 20, 30];
      const coarseScales = <double>[0.92, 0.96, 1, 1.04, 1.08];
      const coarseAngles = <double>[-5, -2.5, 0, 2.5, 5];

      for (final offsetX in coarseOffsets) {
        for (final offsetY in coarseOffsets) {
          for (final scaleFactor in coarseScales) {
            for (final angleDegrees in coarseAngles) {
              final candidate = LineMatchCandidate(
                centerX: original.centerX + offsetX,
                centerY: original.centerY + offsetY,
                scale: original.scale * scaleFactor,
                rotation: original.rotation + angleDegrees * math.pi / 180,
              );
              candidate.score = _scoreLineMatchCandidate(
                camera,
                candidate,
                points,
                baseWidth,
                aspect,
              );
              if (candidate.score > best.score) {
                best = candidate;
              }
            }
          }
        }
      }

      final coarseBest = best.copy();
      const refineOffsets = <double>[-6, -3, 0, 3, 6];
      const refineScales = <double>[0.985, 1, 1.015];
      const refineAngles = <double>[-1, 0, 1];

      for (final offsetX in refineOffsets) {
        for (final offsetY in refineOffsets) {
          for (final scaleFactor in refineScales) {
            for (final angleDegrees in refineAngles) {
              final candidate = LineMatchCandidate(
                centerX: coarseBest.centerX + offsetX,
                centerY: coarseBest.centerY + offsetY,
                scale: coarseBest.scale * scaleFactor,
                rotation: coarseBest.rotation + angleDegrees * math.pi / 180,
              );
              candidate.score = _scoreLineMatchCandidate(
                camera,
                candidate,
                points,
                baseWidth,
                aspect,
              );
              if (candidate.score > best.score) {
                best = candidate;
              }
            }
          }
        }
      }

      final improvement = best.score - original.score;
      if (best.score < 0.055 || improvement < 0.004) {
        _setStatus(
          'No clear match. Darken more traced lines and place the image closer first.',
          hold: const Duration(seconds: 4),
        );
        return;
      }

      setState(() {
        view.centerX = best.centerX / _stageSize.width;
        view.centerY = best.centerY / _stageSize.height;
        view.scale = best.scale.clamp(0.08, 12.0).toDouble();
        view.rotation = best.rotation;
      });

      await _saveCurrent(showMessage: false);
      final quality = (best.score * 240).round().clamp(1, 99);
      _setStatus(
        'Line match applied. Estimated match $quality%',
        hold: const Duration(seconds: 3),
      );
    } catch (error) {
      _setStatus(
        'Line matching failed: $error',
        hold: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

'''

replace_once(
    '  Future<void> _autoAdjust() async {\n',
    line_match_methods + '  Future<void> _autoAdjust() async {\n',
    'the Auto Adjust method',
)

helper_classes = r'''class LineMatchPoint {
  const LineMatchPoint(this.x, this.y);

  final double x;
  final double y;
}

class LineMatchCandidate {
  LineMatchCandidate({
    required this.centerX,
    required this.centerY,
    required this.scale,
    required this.rotation,
    this.score = 0,
  });

  final double centerX;
  final double centerY;
  final double scale;
  final double rotation;
  double score;

  LineMatchCandidate copy() => LineMatchCandidate(
        centerX: centerX,
        centerY: centerY,
        scale: scale,
        rotation: rotation,
        score: score,
      );
}

class LineMatchFrame {
  const LineMatchFrame({
    required this.width,
    required this.height,
    required this.darkness,
  });

  final int width;
  final int height;
  final Float32List darkness;
}

'''

replace_once(
    'class TraceGridPainter extends CustomPainter {\n',
    helper_classes + 'class TraceGridPainter extends CustomPainter {\n',
    'the TraceGridPainter declaration',
)

path.write_text(source, encoding='utf-8')
print(f'Restored Match Lines in {path} ({len(source.splitlines())} lines).')
