class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        TraceCatLogo(size: 84),
        SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TraceCatWordmark(fontSize: 34),
              SizedBox(height: 4),
              Text(
                'Bring your reference into the real world.',
                style: TextStyle(
                  color: TraceCatColors.muted,
                  fontSize: 13.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PrimaryCard extends StatelessWidget {
  const _PrimaryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TraceCatColors.orange,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(19),
          child: Row(
            children: [
              Icon(
                icon,
                color: Colors.black,
                size: 36,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xB8000000),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.black,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TraceCatColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: TraceCatColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: TraceCatColors.orange,
                size: 29,
              ),
              const SizedBox(height: 13),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: TraceCatColors.muted,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.action,
  });

  final String title;
  final VoidCallback? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: action,
            child: const Text('View all'),
          ),
      ],
    );
  }
}

class _EmptyProjectsCard extends StatelessWidget {
  const _EmptyProjectsCard({
    required this.onImport,
  });

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _panelDecoration(),
      child: Column(
        children: [
          const Icon(
            Icons.image_search_rounded,
            color: TraceCatColors.orange,
            size: 38,
          ),
          const SizedBox(height: 10),
          const Text(
            'No projects yet',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Import an image to create your first TraceCat project.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: TraceCatColors.muted,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.tonal(
            onPressed: onImport,
            child: const Text(
              'Import image',
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectPreview extends StatelessWidget {
  const _ProjectPreview({
    required this.project,
    required this.onTap,
  });

  final TraceProject project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      child: Material(
        color: TraceCatColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: TraceCatColors.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ColoredBox(
                  color: Colors.white,
                  child: SizedBox.expand(
                    child: Image.file(
                      File(project.imagePath),
                      fit: BoxFit.contain,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.black45,
                            size: 38,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  11,
                  9,
                  11,
                  2,
                ),
                child: Text(
                  project.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  11,
                  0,
                  11,
                  9,
                ),
                child: Text(
                  _formatDate(project.modified),
                  style: const TextStyle(
                    color: TraceCatColors.muted,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectListCard extends StatelessWidget {
  const _ProjectListCard({
    required this.project,
    required this.onOpen,
    required this.onDelete,
  });

  final TraceProject project;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: TraceCatColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: TraceCatColors.border,
        ),
      ),
      child: ListTile(
        onTap: onOpen,
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: ColoredBox(
            color: Colors.white,
            child: Image.file(
              File(project.imagePath),
              width: 64,
              height: 70,
              fit: BoxFit.contain,
              errorBuilder: (
                context,
                error,
                stackTrace,
              ) {
                return const SizedBox(
                  width: 64,
                  height: 70,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.black45,
                  ),
                );
              },
            ),
          ),
        ),
        title: Text(
          project.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          'Updated ${_formatDate(project.modified)}',
          style: const TextStyle(
            color: TraceCatColors.muted,
          ),
        ),
        trailing: IconButton(
          onPressed: onDelete,
          tooltip: 'Delete project',
          icon: const Icon(
            Icons.delete_outline_rounded,
          ),
        ),
      ),
    );
  }
}

class _RoadmapCard extends StatelessWidget {
  const _RoadmapCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Icon(
            icon,
            color: TraceCatColors.orange,
            size: 30,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      badge,
                      style: const TextStyle(
                        color:
                            TraceCatColors.orangeSoft,
                        fontSize: 10.5,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: TraceCatColors.muted,
                    fontSize: 12.5,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
     
