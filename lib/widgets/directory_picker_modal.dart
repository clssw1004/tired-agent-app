import 'dart:math';

import 'package:flutter/material.dart';

import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/protocol/http_sse_transport.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

/// Modal for browsing the remote Agent's filesystem.
///
/// Shows favorites / recent shortcuts and a directory browser.
/// Calls [onSelect] with the chosen absolute path, or [onClose] on dismiss.
class DirectoryPickerModal extends StatefulWidget {
  final ServerRef serverRef;
  final String agentId;
  final String? initialPath;
  final ValueChanged<String> onSelect;
  final VoidCallback onClose;

  const DirectoryPickerModal({
    super.key,
    required this.serverRef,
    required this.agentId,
    this.initialPath,
    required this.onSelect,
    required this.onClose,
  });

  /// Show as a bottom sheet returning the selected path, or null on dismiss.
  static Future<String?> show(
    BuildContext context, {
    required ServerRef serverRef,
    required String agentId,
    String? initialPath,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.three)),
      ),
      builder: (_) => DirectoryPickerModal(
        serverRef: serverRef,
        agentId: agentId,
        initialPath: initialPath,
        onSelect: (path) => Navigator.of(context).pop(path),
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  State<DirectoryPickerModal> createState() => _DirectoryPickerModalState();
}

class _DirectoryPickerModalState extends State<DirectoryPickerModal>
    with SingleTickerProviderStateMixin {
  final HttpSseTransport _transport = HttpSseTransport();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;

  String _currentPath = '';
  String? _parent;
  List<DirectoryEntry> _entries = [];
  List<DirectoryFavorite> _favorites = [];
  List<RecentDirectory> _recent = [];
  bool _loading = true;
  String? _error;
  bool _savingFavorite = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentPath = widget.initialPath ?? '';
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  bool get _isFavorited => _favorites.any((f) => f.path == _currentPath);
  DirectoryFavorite? get _currentFavorite => _favorites.where((f) => f.path == _currentPath).firstOrNull;

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _transport.listDirectories(widget.serverRef, path: _currentPath.isNotEmpty ? _currentPath : null, agentId: widget.agentId),
        _transport.getDirectoryShortcuts(widget.serverRef, agentId: widget.agentId),
      ]);
      final listing = results[0] as DirectoryListing;
      final shortcuts = results[1] as DirectoryShortcuts;
      setState(() {
        _currentPath = listing.path;
        _parent = listing.parent;
        _entries = listing.entries;
        _favorites = shortcuts.favorites;
        _recent = shortcuts.recent;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _navigateTo(String path) async {
    setState(() { _loading = true; _error = null; });
    try {
      final listing = await _transport.listDirectories(
        widget.serverRef, path: path, agentId: widget.agentId,
      );
      setState(() {
        _currentPath = listing.path;
        _parent = listing.parent;
        _entries = listing.entries;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _pickShortcut(String path) async {
    // Verify the path exists before selecting
    try {
      await _transport.listDirectories(
        widget.serverRef, path: path, agentId: widget.agentId,
      );
      widget.onSelect(path);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _toggleFavorite() async {
    if (_currentPath.isEmpty) return;
    setState(() => _savingFavorite = true);
    try {
      if (_currentFavorite != null) {
        await _transport.removeDirectoryFavorite(
          widget.serverRef, _currentFavorite!.id, agentId: widget.agentId,
        );
        setState(() => _favorites.removeWhere((f) => f.id == _currentFavorite!.id));
      } else {
        final created = await _transport.addDirectoryFavorite(
          widget.serverRef, path: _currentPath, agentId: widget.agentId,
        );
        setState(() => _favorites.add(created));
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _savingFavorite = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return SizedBox(
      height: min(mediaQuery.size.height * 0.85, 560),
      child: Column(
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.two),
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withAlpha(80),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.four, vertical: AppSpacing.three,
            ),
            child: Row(
              children: [
                ThemedText.title('Select working directory'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          // Browse toolbar with current path + parent button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.four),
            child: Row(
              children: [
                if (_parent != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, color: AppColors.accent, size: 20),
                    onPressed: _loading ? null : () => _navigateTo(_parent!),
                    tooltip: 'Up one level',
                  ),
                const SizedBox(width: AppSpacing.two),
                Expanded(
                  child: ThemedText.small(
                    _currentPath.isNotEmpty ? _currentPath : '(loading…)',
                    color: AppColors.textSecondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Error banner
          if (_error != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.four, vertical: AppSpacing.one),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.three, vertical: AppSpacing.two),
              decoration: BoxDecoration(
                color: AppColors.danger.withAlpha(30),
                borderRadius: BorderRadius.circular(AppSpacing.two),
              ),
              child: Row(
                children: [
                  Expanded(child: ThemedText.small(_error!, color: AppColors.danger)),
                  GestureDetector(
                    onTap: () => setState(() => _error = null),
                    child: const Icon(Icons.close, color: AppColors.danger, size: 16),
                  ),
                ],
              ),
            ),
          // Tab bar
          TabBar(
            controller: _tabController,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.accent,
            tabs: const [
              Tab(text: 'Favorites'),
              Tab(text: 'Recent'),
              Tab(text: 'Browse'),
            ],
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFavoritesTab(),
                _buildRecentTab(),
                _buildBrowseTab(),
              ],
            ),
          ),
          // Bottom action bar
          Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.four, AppSpacing.two, AppSpacing.four, AppSpacing.three),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: AppColors.backgroundElement)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  TextButton(
                    onPressed: _currentPath.isEmpty || _savingFavorite ? null : _toggleFavorite,
                    child: ThemedText.small(
                      _savingFavorite ? '…' : (_isFavorited ? 'Unfavorite' : 'Favorite'),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: widget.onClose,
                    child: ThemedText.body('Cancel'),
                  ),
                  const SizedBox(width: AppSpacing.two),
                  ElevatedButton(
                    onPressed: _currentPath.isEmpty || _loading ? null : () => widget.onSelect(_currentPath),
                    child: ThemedText.body('Select'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab() {
    if (_favorites.isEmpty) {
      return Center(child: ThemedText.small('No favorites yet'));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.four),
      itemCount: _favorites.length,
      separatorBuilder: (_, __) => const Divider(color: AppColors.backgroundElement, height: 1),
      itemBuilder: (context, index) {
        final fav = _favorites[index];
        return ListTile(
          leading: const Icon(Icons.star, color: AppColors.warning, size: 20),
          title: ThemedText.body(fav.name),
          subtitle: ThemedText.small(fav.path, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => _pickShortcut(fav.path),
        );
      },
    );
  }

  Widget _buildRecentTab() {
    if (_recent.isEmpty) {
      return Center(child: ThemedText.small('No recent directories'));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.four),
      itemCount: _recent.length,
      separatorBuilder: (_, __) => const Divider(color: AppColors.backgroundElement, height: 1),
      itemBuilder: (context, index) {
        final recent = _recent[index];
        return ListTile(
          leading: const Icon(Icons.history, color: AppColors.textSecondary, size: 20),
          title: ThemedText.small(recent.path, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: ThemedText.small(_relativeTime(recent.lastUsedAt)),
          onTap: () => _pickShortcut(recent.path),
        );
      },
    );
  }

  Widget _buildBrowseTab() {
    if (_loading && _entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_entries.isEmpty) {
      return Center(child: ThemedText.small('Empty directory'));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.four),
      itemCount: _entries.length,
      separatorBuilder: (_, __) => const Divider(color: AppColors.backgroundElement, height: 1),
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return ListTile(
          leading: const Icon(Icons.folder_outlined, color: AppColors.accent, size: 20),
          title: ThemedText.body(entry.name),
          onTap: () => _navigateTo(entry.path),
        );
      },
    );
  }

  String _relativeTime(int epochMs) {
    final delta = DateTime.now().millisecondsSinceEpoch - epochMs;
    if (delta < 60000) return 'just now';
    if (delta < 3600000) return '${delta ~/ 60000}m ago';
    if (delta < 86400000) return '${delta ~/ 3600000}h ago';
    return '${delta ~/ 86400000}d ago';
  }
}
