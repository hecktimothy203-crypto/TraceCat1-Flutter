from pathlib import Path

source_path = Path('lib/main.dart')
workspace_path = Path('lib/trace_workspace.dart')
source = source_path.read_text(encoding='utf-8')

start = source.index('Future<void> main() async {')
workspace_start = source.index('class TraceCatHome extends StatefulWidget')
source = source[:start] + source[workspace_start:]

old_widget = '''class TraceCatHome extends StatefulWidget {
  const TraceCatHome({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  State<TraceCatHome> createState() => _TraceCatHomeState();
}

class _TraceCatHomeState extends State<TraceCatHome>
'''

new_widget = '''class TraceWorkspace extends StatefulWidget {
  const TraceWorkspace({
    super.key,
    required this.cameras,
    this.openImportOnStart = false,
    this.initialProjectId,
  });

  final List<CameraDescription> cameras;
  final bool openImportOnStart;
  final String? initialProjectId;

  @override
  State<TraceWorkspace> createState() => _TraceWorkspaceState();
}

class _TraceWorkspaceState extends State<TraceWorkspace>
'''

if old_widget not in source:
    raise RuntimeError(
        'Could not locate the original TraceCatHome declaration.'
    )

source = source.replace(old_widget, new_widget, 1)

source = source.replace(
    '  final List<Offset> _anchorTaps = [];\n',
    '  final List<Offset> _anchorTaps = [];\n'
    '  bool _initialActionHandled = false;\n'
    '  bool _gridEnabled = false;\n',
    1,
)

old_initialize = '''  Future<void> _initialize() async {
    await _store.initialize();
    _projects = await _store.loadAll();
    final current = await _store.loadCurrent();
    if (current != null) await _setProject(current);
    if (mounted) setState(() {});
  }
'''

new_initialize = '''  Future<void> _initialize() async {
    await _store.initialize();
    _projects = await _store.loadAll();

    final requested = widget.initialProjectId == null
        ? await _store.loadCurrent()
        : await _store.load(widget.initialProjectId!);

    if (requested != null) {
      await _setProject(requested);
    }

    if (mounted) {
      setState(() {});
    }

    if (widget.openImportOnStart && !_initialActionHandled) {
      _initialActionHandled = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_importImage());
        }
      });
    }
  }
'''

if old_initialize not in source:
    raise RuntimeError('Could not locate _initialize.')

source = source.replace(old_initialize, new_initialize, 1)

old_layers = '''                  _cameraLayer(),
                  _templateLayer(),
                  if (_anchorMode || _project?.view.anchorQuad != null)
                    IgnorePointer(
                      child: CustomPaint(
                        painter: AnchorPainter(
                          points: _anchorMode
                              ? _anchorTaps
                              : (_project?.view.anchorQuad ?? const []),
                          active: _anchorMode,
                        ),
                      ),
                    ),
'''

new_layers = '''                  _cameraLayer(),
                  if (_gridEnabled)
                    const IgnorePointer(
                      child: CustomPaint(
                        painter: TraceGridPainter(),
                      ),
                    ),
                  _templateLayer(),
'''

if old_layers not in source:
    raise RuntimeError('Could not locate camera/template layers.')

source = source.replace(old_layers, new_layers, 1)

old_help = r'''            'Import Image adds a photo or line drawing without changing it.\n\n'
            'Drag with one finger. Pinch with two fingers to resize and rotate. '
            'Pin the image before drawing.\n\n'
            'Refocus before aligning the image. Start Tracing locks the current '
            'focus without refocusing and hides the controls without resizing '
            'the camera preview.\n\n'
            'Set Anchors by tapping the four paper marks in this order: top left, '
            'top right, bottom right, bottom left. Auto Adjust intentionally '
            'refocuses and realigns to those marks.\n\n'
            'Projects and images stay on this phone. The app does not need an '
            'internet permission.',
'''

new_help = r'''            'Import Image creates a project without changing the original picture.\n\n'
            'Drag with one finger. Pinch with two fingers to resize and rotate. '
            'Use Pin Image after the overlay is aligned.\n\n'
            'Refocus before aligning the image. Start Tracing locks the current '
            'focus and hides most controls without changing the camera preview.\n\n'
            'The grid is a visual guide only. It can be turned on or off without '
            'changing the imported image.\n\n'
            'Projects and images stay on this phone. Surface AR is planned for a '
            'later build and is not represented as active in this version.',
'''

if old_help not in source:
    raise RuntimeError('Could not locate the help text.')

source = source.replace(old_help, new_help, 1)

old_controls = '''              Row(
                children: [
                  Expanded(
                    child: _smallButton(
                      label: project?.view.pinned == true
                          ? 'Unpin Image'
                          : 'Pin Image',
                      active: project?.view.pinned == true,
                      onPressed: project == null
                          ? null
                          : () {
                              if (project.view.anchorQuad != null) {
                                _setStatus('The four anchors already pin the image');
                                return;
                              }
                              setState(() => project.view.pinned = !project.view.pinned);
                            },
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: _smallButton(
                      label: 'Fit Screen',
                      onPressed: project == null ? null : _fitImage,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: _smallButton(
                      label: 'Set Anchors',
                      active: project?.view.anchorQuad != null,
                      onPressed: _startAnchors,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: _smallButton(
                      label: 'Auto Adjust',
                      onPressed: _autoAdjust,
                    ),
                  ),
                ],
              ),
'''

new_controls = '''              Row(
                children: [
                  Expanded(
                    child: _smallButton(
                      label: project?.view.pinned == true
                          ? 'Unpin Image'
                          : 'Pin Image',
                      active: project?.view.pinned == true,
                      onPressed: project == null
                          ? null
                          : () {
                              setState(
                                () => project.view.pinned =
                                    !project.view.pinned,
                              );

                              _setStatus(
                                project.view.pinned
                                    ? 'Image pinned in place'
                                    : 'Image unlocked',
                              );
                            },
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: _smallButton(
                      label: 'Fit Screen',
                      onPressed:
                          project == null ? null : _fitImage,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
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
                  const SizedBox(width: 5),
                  Expanded(
                    child: _smallButton(
                      label: 'Reset View',
                      onPressed:
                          project == null ? null : _resetView,
                    ),
                  ),
                ],
              ),
'''

if old_controls not in source:
    raise RuntimeError('Could not locate anchor controls.')

source = source.replace(old_controls, new_controls, 1)

old_last_button = '''                  Expanded(
                    child: _smallButton(
                      label: 'Reset View',
                      onPressed: project == null ? null : _resetView,
                    ),
                  ),
'''

new_last_button = '''                  Expanded(
                    child: _smallButton(
                      label: 'Home',
                      onPressed: () async {
                        await _saveCurrent(
                          showMessage: false,
                        );

                        if (mounted) {
                          Navigator.maybePop(context);
                        }
                      },
                    ),
                  ),
'''

last_position = source.rfind(old_last_button)

if last_position == -1:
    raise RuntimeError(
        'Could not locate the final Reset View button.'
    )

source = (
    source[:last_position]
    + new_last_button
    + source[last_position + len(old_last_button):]
)

grid_painter = '''class TraceGridPainter extends CustomPainter {
  const TraceGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.24)
      ..strokeWidth = 1;

    const divisions = 4;

    for (var index = 1; index < divisions; index++) {
      final x = size.width * index / divisions;
      final y = size.height * index / divisions;

      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );

      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    final centerPaint = Paint()
      ..color = const Color(0xFFFF8A00)
          .withValues(alpha: 0.52)
      ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      centerPaint,
    );

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant TraceGridPainter oldDelegate,
  ) {
    return false;
  }
}

'''

anchor_marker = 'class AnchorPainter extends CustomPainter {'

if anchor_marker not in source:
    raise RuntimeError('Could not locate AnchorPainter.')

source = source.replace(
    anchor_marker,
    grid_painter + anchor_marker,
    1,
)

if 'class TraceView {\n  TraceView();' not in source:
    source = source.replace(
        'class TraceView {\n',
        'class TraceView {\n'
        '  TraceView();\n\n',
        1,
    )

workspace_path.write_text(
    source,
    encoding='utf-8',
)

print(
    f'Prepared {workspace_path} '
    f'({len(source.splitlines())} lines).'
)
