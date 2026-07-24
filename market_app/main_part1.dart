import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'trace_workspace.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final cameras = await availableCameras();
  runApp(TraceCatApp(cameras: cameras));
}

class TraceCatColors {
  static const background = Color(0xFF080A0D);
  static const surface = Color(0xFF111419);
  static const surfaceRaised = Color(0xFF181C22);
  static const border = Color(0xFF2B3038);
  static const orange = Color(0xFFFF8A00);
  static const orangeSoft = Color(0xFFFFB04A);
  static const text = Color(0xFFF5F6F7);
  static const muted = Color(0xFF9BA2AD);
}

class TraceCatApp extends StatelessWidget {
  const TraceCatApp({
    super.key,
    required this.cameras,
  });

  final List<CameraDescription> cameras;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: TraceCatColors.orange,
      brightness: Brightness.dark,
    ).copyWith(
      primary: TraceCatColors.orange,
      secondary: TraceCatColors.orangeSoft,
      surface: TraceCatColors.surface,
      outline: TraceCatColors.border,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TraceCat',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: scheme,
        scaffoldBackgroundColor: TraceCatColors.background,
        useMaterial3: true,
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: TraceCatColors.orange,
            foregroundColor: Colors.black,
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: Color(0xFF0E1115),
          indicatorColor: Color(0x33FF8A00),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      home: TraceCatSplash(
        cameras: cameras,
      ),
    );
  }
}

class TraceCatSplash extends StatefulWidget {
  const TraceCatSplash({
    super.key,
    required this.cameras,
  });

  final List<CameraDescription> cameras;

  @override
  State<TraceCatSplash> createState() {
    return _TraceCatSplashState();
  }
}

class _TraceCatSplashState extends State<TraceCatSplash> {
  @override
  void initState() {
    super.initState();

    Future<void>.delayed(
      const Duration(milliseconds: 800),
      () {
        if (!mounted) {
          return;
        }

        Navigator.of(context).pushReplacement(
          PageRouteBuilder<void>(
            pageBuilder: (_, animation, __) {
              return FadeTransition(
                opacity: animation,
                child: TraceCatShell(
                  cameras: widget.cameras,
                ),
              );
            },
            transitionDuration: const Duration(
              milliseconds: 350,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TraceCatLogo(size: 132),
            SizedBox(height: 22),
            TraceCatWordmark(fontSize: 42),
            SizedBox(height: 8),
            Text(
              'Trace with confidence.',
              style: TextStyle(
                color: TraceCatColors.muted,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TraceCatShell extends StatefulWidget {
  const TraceCatShell({
    super.key,
    required this.cameras,
  });

  final List<CameraDescription> cameras;

  @override
  State<TraceCatShell> createState() {
    return _TraceCatShellState();
  }
}

class _TraceCatShellState extends State<TraceCatShell> {
  int _selectedIndex = 0;
  int _refreshToken = 0;

  Future<void> _openWorkspace({
    bool importFirst = false,
    String? projectId,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) {
          return TraceWorkspace(
            cameras: widget.cameras,
            openImportOnStart: importFirst,
            initialProjectId: projectId,
          );
        },
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _refreshToken++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      TraceCatHomePage(
        key: ValueKey(
          'home-$_refreshToken',
        ),
        onStart: () {
          _openWorkspace();
        },
        onImport: () {
          _openWorkspace(
            importFirst: true,
          );
        },
        onOpenProject: (id) {
          _openWorkspace(
            projectId: id,
          );
        },
        onShowProjects: () {
          setState(() {
            _selectedIndex = 1;
          });
        },
      ),
      TraceCatProjectsPage(
        key: ValueKey(
          'projects-$_refreshToken',
        ),
        onImport: () {
          _openWorkspace(
            importFirst: true,
          );
        },
        onOpenProject: (id) {
          _openWorkspace(
            projectId: id,
          );
        },
      ),
      const TraceCatSettingsPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () {
          _openWorkspace();
        },
        tooltip: 'Open tracing camera',
        backgroundColor: TraceCatColors.orange,
        foregroundColor: Colors.black,
        child: const Icon(
          Icons.photo_camera_rounded,
          size: 31,
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (value) {
          setState(() {
            _selectedIndex = value;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
            ),
            selectedIcon: Icon(
              Icons.home_rounded,
              color: TraceCatColors.orange,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.folder_outlined,
            ),
            selectedIcon: Icon(
              Icons.folder_rounded,
              color: TraceCatColors.orange,
            ),
            label: 'Projects',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.settings_outlined,
            ),
            selectedIcon: Icon(
              Icons.settings_rounded,
              color: TraceCatColors.orange,
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class TraceCatHomePage extends StatefulWidget {
  const TraceCatHomePage({
    super.key,
    required this.onStart,
    required this.onImport,
    required this.onOpenProject,
    required this.onShowProjects,
  });

  final VoidCallback onStart;
  final VoidCallback onImport;
  final ValueChanged<String> onOpenProject;
  final VoidCallback onShowProjects;

  @override
  State<TraceCatHomePage> createState() {
    return _TraceCatHomePageState();
  }
}

class _TraceCatHomePageState
    extends State<TraceCatHomePage> {
  final ProjectStore _store = ProjectStore();

  List<TraceProject> _projects = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    await _store.initialize();

    final projects = await _store.loadAll();

    if (!mounted) {
      return;
    }

    setState(() {
      _projects = projects;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            18,
            22,
            18,
            120,
          ),
          children: [
            const _HomeHeader(),
            const SizedBox(height: 24),
            _PrimaryCard(
              title: 'Start Tracing',
              subtitle:
                  'Open the camera and continue your current project.',
              icon: Icons.draw_rounded,
              onTap: widget.onStart,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    title: 'Import Image',
                    subtitle:
                        'Create a new tracing project.',
                    icon:
                        Icons.add_photo_alternate_outlined,
                    onTap: widget.onImport,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    title: 'My Projects',
                    subtitle:
                        'Open and manage saved work.',
                    icon:
                        Icons.folder_copy_outlined,
                    onTap: widget.onShowProjects,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            _SectionHeader(
              title: 'Recent projects',
              action: _projects.isEmpty
                  ? null
                  : widget.onShowProjects,
            ),
            const SizedBox(height: 12),
            if (_loading)
              const SizedBox(
                height: 170,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_projects.isEmpty)
              _EmptyProjectsCard(
                onImport: widget.onImport,
              )
            else
              SizedBox(
                height: 192,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: math.min(
                    6,
                    _projects.length,
                  ),
                  separatorBuilder: (_, __) {
                    return const SizedBox(
                      width: 12,
                    );
                  },
                  itemBuilder: (context, index) {
                    final project =
                        _projects[index];

                    return _ProjectPreview(
                      project: project,
                      onTap: () {
                        widget.onOpenProject(
                          project.id,
                        );
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 26),
            const _SectionHeader(
              title: 'TraceCat roadmap',
            ),
            const SizedBox(height: 12),
            const _RoadmapCard(
              title: 'Surface AR',
              subtitle:
                  'Scan real surfaces and keep artwork registered while the camera moves.',
              icon: Icons.view_in_ar_rounded,
              badge: 'In development',
            ),
            const SizedBox(height: 10),
            const _RoadmapCard(
              title: 'AR glasses',
              subtitle:
                  'Hands-free guidance for murals, sculpture, fabrication, and custom art.',
              icon: Icons.visibility_rounded,
              badge: 'Future Pro',
            ),
          ],
        ),
      ),
    );
  }
}

class TraceCatProjectsPage extends StatefulWidget {
  const TraceCatProjectsPage({
    super.key,
    required this.onImport,
    required this.onOpenProject,
  });

  final VoidCallback onImport;
  final ValueChanged<String> onOpenProject;

  @override
  State<TraceCatProjectsPage> createState() {
    return _TraceCatProjectsPageState();
  }
}

class _TraceCatProjectsPageState
    extends State<TraceCatProjectsPage> {
  final ProjectStore _store = ProjectStore();

  List<TraceProject> _projects = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    await _store.initialize();

    final projects = await _store.loadAll();

    if (!mounted) {
      return;
    }

    setState(() {
      _projects = projects;
      _loading = false;
    });
  }

  Future<void> _delete(
    TraceProject project,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete project?',
          ),
          content: Text(
            'Delete "${project.name}" from this phone?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _store.delete(project);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              18,
              22,
              18,
              14,
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Projects',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                      Text(
                        'Saved locally on this phone',
                        style: TextStyle(
                          color:
                              TraceCatColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: widget.onImport,
                  tooltip: 'Import image',
                  icon: const Icon(
                    Icons
                        .add_photo_alternate_outlined,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(),
                  )
                : _projects.isEmpty
                    ? Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(
                            22,
                          ),
                          child:
                              _EmptyProjectsCard(
                            onImport:
                                widget.onImport,
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child:
                            ListView.separated(
                          padding:
                              const EdgeInsets
                                  .fromLTRB(
                            16,
                            4,
                            16,
                            110,
                          ),
                          itemCount:
                              _projects.length,
                          separatorBuilder:
                              (_, __) {
                            return const SizedBox(
                              height: 10,
                            );
                          },
                          itemBuilder:
                              (context, index) {
                            final project =
                                _projects[index];

                            return _ProjectListCard(
                              project: project,
                              onOpen: () {
                                widget
                                    .onOpenProject(
                                  project.id,
                                );
                              },
                              onDelete: () {
                                _delete(project);
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class TraceCatSettingsPage extends StatelessWidget {
  const TraceCatSettingsPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          18,
          22,
          18,
          120,
        ),
        children: const [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'TraceCat 1.1 preview',
            style: TextStyle(
              color: TraceCatColors.muted,
            ),
          ),
          SizedBox(height: 22),
          _InfoTile(
            icon: Icons.lock_outline_rounded,
            title: 'Private by design',
            subtitle:
                'Projects and reference images stay on this phone.',
          ),
          _InfoTile(
            icon: Icons.camera_alt_outlined,
            title: 'Camera controls',
            subtitle:
                'Focus lock, refocus, flashlight, and opacity remain available.',
          ),
          _InfoTile(
            icon: Icons.grid_4x4_rounded,
            title: 'Tracing grid',
            subtitle:
                'Use the new grid control inside the tracing workspace.',
          ),
          _InfoTile(
            icon: Icons.view_in_ar_outlined,
            title: 'Surface AR',
            subtitle:
                'Flat and curved surface anchoring will be built as a later phase.',
          ),
          SizedBox(height: 18),
          _AboutCard(),
        ],
      ),
    );
  }
}
