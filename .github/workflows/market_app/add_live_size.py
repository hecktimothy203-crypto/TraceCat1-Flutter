from pathlib import Path

path = Path('lib/trace_workspace.dart')
source = path.read_text(encoding='utf-8')


def replace_once(old: str, new: str, label: str) -> None:
    global source
    if old not in source:
        raise RuntimeError(f'Could not locate {label}.')
    source = source.replace(old, new, 1)


replace_once(
    "import 'package:shared_preferences/shared_preferences.dart';\n",
    "import 'package:shared_preferences/shared_preferences.dart';\n\n"
    "import 'live_size_dialogs.dart';\n",
    'the shared_preferences import',
)

replace_once(
    '''  bool _initialActionHandled = false;
  bool _gridEnabled = false;
''',
    '''  bool _initialActionHandled = false;
  bool _gridEnabled = false;

  bool _liveSizeEnabled = false;
  bool _liveSizeCalibrating = false;
  String _liveSizeUnit = 'in';
  double? _surfaceWidthInches;
  double? _surfaceHeightInches;
  double? _pixelsPerInchX;
  double? _pixelsPerInchY;
  Offset? _liveSizeFirstTap;
  Offset? _liveSizeSecondTap;
''',
    'the TraceWorkspace state fields',
)

replace_once(
    '''      canPop: !_traceMode && !_anchorMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_anchorMode) {
''',
    '''      canPop: !_traceMode && !_anchorMode && !_liveSizeCalibrating,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_liveSizeCalibrating) {
          setState(() {
            _liveSizeCalibrating = false;
            _liveSizeFirstTap = null;
            _liveSizeSecondTap = null;
          });
          _setStatus('Live Size calibration canceled');
        } else if (_anchorMode) {
''',
    'the PopScope calibration handling',
)

replace_once(
    '''    if (project == null || project.view.pinned || project.view.anchorQuad != null) {
''',
    '''    if (project == null ||
        _liveSizeCalibrating ||
        project.view.pinned ||
        project.view.anchorQuad != null) {
''',
    'the scale-start guard',
)

replace_once(
    '''    if (project == null ||
        project.view.pinned ||
        project.view.anchorQuad != null ||
''',
    '''    if (project == null ||
        _liveSizeCalibrating ||
        project.view.pinned ||
        project.view.anchorQuad != null ||
''',
    'the scale-update guard',
)

old_tap = '''  void _handleStageTap(TapDownDetails details) {
    if (!_anchorMode || _stageSize.isEmpty) return;
    final normalized = Offset(
      details.localPosition.dx / _stageSize.width,
      details.localPosition.dy / _stageSize.height,
    );
    setState(() => _anchorTaps.add(normalized));
    if (_anchorTaps.length == 4) unawaited(_finishAnchors());
  }

'''

new_tap = '''  void _handleStageTap(TapDownDetails details) {
    if (_stageSize.isEmpty) return;

    final normalized = Offset(
      details.localPosition.dx / _stageSize.width,
      details.localPosition.dy / _stageSize.height,
    );

    if (_liveSizeCalibrating) {
      _handleLiveSizeTap(normalized);
      return;
    }

    if (!_anchorMode) return;

    setState(() => _anchorTaps.add(normalized));
    if (_anchorTaps.length == 4) unawaited(_finishAnchors());
  }

'''

replace_once(old_tap, new_tap, 'the stage tap handler')

live_size_methods = r'''  Size? get _liveImageSizeInches {
    final project = _project;
    final image = _templateInfo;
    final pixelsPerInchX = _pixelsPerInchX;
    final pixelsPerInchY = _pixelsPerInchY;

    if (!_liveSizeEnabled ||
        project == null ||
        image == null ||
        pixelsPerInchX == null ||
        pixelsPerInchY == null ||
        pixelsPerInchX <= 0 ||
        pixelsPerInchY <= 0 ||
        _stageSize.isEmpty ||
        project.view.anchorQuad != null) {
      return null;
    }

    final widthPixels =
        project.view.baseWidth * _stageSize.width * project.view.scale;
    final aspect = image.width / image.height;
    final heightPixels = widthPixels / aspect;

    return Size(
      widthPixels / pixelsPerInchX,
      heightPixels / pixelsPerInchY,
    );
  }

  Size? get _liveImageSizeDisplay {
    final inches = _liveImageSizeInches;
    if (inches == null) return null;
    final factor = _liveSizeUnit == 'cm' ? 2.54 : 1.0;
    return Size(
      inches.width * factor,
      inches.height * factor,
    );
  }

  String get _liveMeasurementText {
    final size = _liveImageSizeDisplay;
    if (size == null) return 'Live Size';
    return '${size.width.toStringAsFixed(2)} × '
        '${size.height.toStringAsFixed(2)} $_liveSizeUnit';
  }

  Future<void> _openLiveSize() async {
    if (_project == null || _templateInfo == null) {
      _setStatus('Import an image before using Live Size');
      return;
    }

    if (!_liveSizeEnabled) {
      await _startLiveSizeCalibration();
      return;
    }

    final action = await showLiveSizeActionsDialog(
      context,
      measurement: _liveMeasurementText,
      unit: _liveSizeUnit,
    );

    if (!mounted || action == null) return;

    switch (action) {
      case 'disable':
        setState(() => _liveSizeEnabled = false);
        _setStatus('Live Size turned off');
        break;
      case 'unit':
        setState(() {
          _liveSizeUnit = _liveSizeUnit == 'cm' ? 'in' : 'cm';
        });
        _setStatus('Live Size now shows $_liveSizeUnit');
        break;
      case 'exact':
        await _setExactLiveSize();
        break;
      case 'recalibrate':
        await _startLiveSizeCalibration();
        break;
    }
  }

  Future<void> _startLiveSizeCalibration() async {
    final setup = await showLiveSizeSetupDialog(
      context,
      existingWidthInches: _surfaceWidthInches,
      existingHeightInches: _surfaceHeightInches,
      existingUnit: _liveSizeUnit,
    );

    if (!mounted || setup == null) return;

    setState(() {
      _surfaceWidthInches = setup.widthInches;
      _surfaceHeightInches = setup.heightInches;
      _liveSizeUnit = setup.unit;
      _liveSizeEnabled = false;
      _liveSizeCalibrating = true;
      _liveSizeFirstTap = null;
      _liveSizeSecondTap = null;
      _pixelsPerInchX = null;
      _pixelsPerInchY = null;
    });

    _setStatus(
      'Tap the paper or canvas top-left corner',
      hold: Duration.zero,
    );
  }

  void _handleLiveSizeTap(Offset normalized) {
    if (!_liveSizeCalibrating) return;

    if (_liveSizeFirstTap == null) {
      setState(() => _liveSizeFirstTap = normalized);
      _setStatus(
        'Now tap the bottom-right corner',
        hold: Duration.zero,
      );
      return;
    }

    final first = _liveSizeFirstTap!;
    final widthInches = _surfaceWidthInches;
    final heightInches = _surfaceHeightInches;

    if (widthInches == null || heightInches == null) {
      setState(() {
        _liveSizeCalibrating = false;
        _liveSizeFirstTap = null;
      });
      _setStatus('Live Size calibration data was missing');
      return;
    }

    final widthPixels =
        (normalized.dx - first.dx).abs() * _stageSize.width;
    final heightPixels =
        (normalized.dy - first.dy).abs() * _stageSize.height;

    if (widthPixels < 60 || heightPixels < 60) {
      setState(() {
        _liveSizeFirstTap = null;
        _liveSizeSecondTap = null;
      });
      _setStatus(
        'Corners were too close. Tap the top-left corner again',
        hold: Duration.zero,
      );
      return;
    }

    setState(() {
      _liveSizeSecondTap = normalized;
      _pixelsPerInchX = widthPixels / widthInches;
      _pixelsPerInchY = heightPixels / heightInches;
      _liveSizeCalibrating = false;
      _liveSizeEnabled = true;
    });

    _setStatus('Live Size calibrated: $_liveMeasurementText');
  }

  Future<void> _setExactLiveSize() async {
    final current = _liveImageSizeDisplay;
    final project = _project;
    if (current == null || project == null) return;

    final request = await showExactSizeDialog(
      context,
      current: current,
      unit: _liveSizeUnit,
    );

    if (!mounted || request == null) return;

    final currentValue = request.dimension == 'width'
        ? current.width
        : current.height;

    if (currentValue <= 0) return;

    final ratio = request.value / currentValue;

    setState(() {
      project.view.scale =
          (project.view.scale * ratio).clamp(0.08, 12.0);
    });

    _setStatus('Image set to $_liveMeasurementText');
  }

  Widget _liveSizeBadge() {
    final size = _liveImageSizeDisplay;
    if (!_liveSizeEnabled || size == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: MediaQuery.paddingOf(context).top + 102,
      right: 12,
      child: Material(
        color: const Color(0xE6030712),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _openLiveSize,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.straighten_rounded,
                  size: 17,
                  color: Color(0xFFFF8A00),
                ),
                const SizedBox(width: 7),
                Text(
                  _liveMeasurementText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

'''

replace_once(
    '  void _startAnchors() {\n',
    live_size_methods + '  void _startAnchors() {\n',
    'the anchor setup method',
)

replace_once(
    '''                  _templateLayer(),
                  if (!_traceMode) ...[
''',
    '''                  _templateLayer(),
                  if (_liveSizeCalibrating)
                    IgnorePointer(
                      child: CustomPaint(
                        painter: LiveSizeCalibrationPainter(
                          first: _liveSizeFirstTap,
                          second: _liveSizeSecondTap,
                        ),
                      ),
                    ),
                  if (_liveSizeEnabled) _liveSizeBadge(),
                  if (!_traceMode) ...[
''',
    'the workspace overlay stack',
)

replace_once(
    '''              const SizedBox(height: 6),
              Row(
                children: [
                  const SizedBox(width: 48, child: Text('Image', style: TextStyle(fontSize: 12))),
''',
    '''              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: _smallButton(
                  label: _liveSizeEnabled
                      ? _liveMeasurementText
                      : (_liveSizeCalibrating
                          ? 'Tap surface corners'
                          : 'Live Size'),
                  active: _liveSizeEnabled || _liveSizeCalibrating,
                  onPressed: project == null ? null : _openLiveSize,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const SizedBox(width: 48, child: Text('Image', style: TextStyle(fontSize: 12))),
''',
    'the Live Size control row',
)

replace_once(
    '''            'The grid is a visual guide only. It can be turned on or off without '
            'changing the imported image.\\n\\n'
            'Projects and images stay on this phone. Surface AR is planned for a '
''',
    '''            'The grid is a visual guide only. It can be turned on or off without '
            'changing the imported image.\\n\\n'
            'Live Size measures the overlay after you select the surface size and '
            'tap its top-left and bottom-right corners. Recalibrate after moving '
            'the phone.\\n\\n'
            'Projects and images stay on this phone. Surface AR is planned for a '
''',
    'the workspace help text',
)

live_size_painter = r'''class LiveSizeCalibrationPainter extends CustomPainter {
  const LiveSizeCalibrationPainter({
    required this.first,
    required this.second,
  });

  final Offset? first;
  final Offset? second;

  @override
  void paint(Canvas canvas, Size size) {
    final firstPoint = first == null
        ? null
        : Offset(first!.dx * size.width, first!.dy * size.height);
    final secondPoint = second == null
        ? null
        : Offset(second!.dx * size.width, second!.dy * size.height);

    final line = Paint()
      ..color = const Color(0xFFFF8A00)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final shade = Paint()
      ..color = Colors.black.withValues(alpha: 0.24)
      ..style = PaintingStyle.fill;

    canvas.drawRect(Offset.zero & size, shade);

    if (firstPoint != null && secondPoint != null) {
      canvas.drawRect(
        Rect.fromPoints(firstPoint, secondPoint),
        line,
      );
    }

    for (final point in [firstPoint, secondPoint]) {
      if (point == null) continue;
      canvas.drawCircle(
        point,
        15,
        Paint()..color = const Color(0xCC030712),
      );
      canvas.drawCircle(point, 13, line);
      canvas.drawLine(
        point - const Offset(9, 0),
        point + const Offset(9, 0),
        line,
      );
      canvas.drawLine(
        point - const Offset(0, 9),
        point + const Offset(0, 9),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant LiveSizeCalibrationPainter oldDelegate,
  ) {
    return oldDelegate.first != first || oldDelegate.second != second;
  }
}

'''

replace_once(
    'class TraceGridPainter extends CustomPainter {\n',
    live_size_painter + 'class TraceGridPainter extends CustomPainter {\n',
    'the TraceGridPainter declaration',
)

path.write_text(source, encoding='utf-8')
print(f'Added Live Size to {path} ({len(source.splitlines())} lines).')
