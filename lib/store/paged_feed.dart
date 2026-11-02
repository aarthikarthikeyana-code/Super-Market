import 'dart:async';

import 'package:flutter/material.dart';

import 'api.dart';
import 'models.dart';
import 'loading.dart';
import 'widgets.dart';

class PagedFeed<T> extends StatefulWidget {
  final Object queryKey;
  final Future<StorePage<T>> Function(String? cursor) load;
  final String Function(T item) identity;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final Widget? header, endContent;
  final SliverGridDelegate? gridDelegate;
  final Listenable? changes;
  final VoidCallback? beforeRefresh;
  final void Function(Map<String, dynamic>)? onMetadata;
  final String emptyTitle, emptyMessage;
  final VoidCallback? onEmptyAction;
  final String? emptyAction;
  final EdgeInsets padding;
  const PagedFeed({
    super.key,
    required this.queryKey,
    required this.load,
    required this.identity,
    required this.itemBuilder,
    this.header,
    this.endContent,
    this.gridDelegate,
    this.changes,
    this.beforeRefresh,
    this.onMetadata,
    this.emptyTitle = 'Nothing here yet',
    this.emptyMessage = 'Pull down to refresh for the latest updates.',
    this.onEmptyAction,
    this.emptyAction,
    this.padding = const EdgeInsets.all(20),
  });
  @override
  State<PagedFeed<T>> createState() => _PagedFeedState<T>();
}

class _PagedFeedState<T> extends State<PagedFeed<T>> {
  final _scroll = ScrollController();
  final _seenCursors = <String>{};
  List<T> _items = [];
  String? _next;
  Object? _error;
  bool _busy = true, _more = true, _updates = false;
  int _generation = 0, _pages = 0, _emptyPages = 0;
  @override
  void initState() {
    super.initState();
    _scroll.addListener(_nearEnd);
    widget.changes?.addListener(_changed);
    _fetch(first: true);
  }

  @override
  void didUpdateWidget(covariant PagedFeed<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.changes != widget.changes) {
      oldWidget.changes?.removeListener(_changed);
      widget.changes?.addListener(_changed);
    }
    if (oldWidget.queryKey != widget.queryKey) {
      _reset();
      _fetch(first: true);
    }
  }

  void _reset() {
    _generation++;
    _items = [];
    _next = null;
    _error = null;
    _busy = true;
    _more = true;
    _pages = 0;
    _emptyPages = 0;
    _updates = false;
    _seenCursors.clear();
  }

  @override
  void dispose() {
    widget.changes?.removeListener(_changed);
    _scroll.removeListener(_nearEnd);
    _scroll.dispose();
    _generation++;
    super.dispose();
  }

  void _nearEnd() {
    if (_scroll.hasClients &&
        _scroll.position.hasContentDimensions &&
        _scroll.position.extentAfter < 450 &&
        !_busy &&
        _more &&
        _error == null) {
      _fetch();
    }
  }

  void _changed() {
    if (!mounted) return;
    if (_busy || _pages > 1) {
      setState(() => _updates = true);
    } else {
      _refresh(silent: true);
    }
  }

  Future<void> _refresh({bool silent = false}) async {
    widget.beforeRefresh?.call();
    final previous = silent ? _items : <T>[];
    setState(() {
      _reset();
      _items = previous;
    });
    await _fetch(first: true);
  }

  Future<void> _fetch({bool first = false}) async {
    if (!first && (_busy || !_more)) return;
    final generation = _generation;
    final cursor = first ? null : _next;
    if (!first && cursor == null) return;
    if (mounted) {
      setState(() {
        _busy = true;
        _error = null;
      });
    }
    try {
      final page = await widget
          .load(cursor)
          .timeout(const Duration(seconds: 65));
      if (!mounted || generation != _generation) return;
      if (page.nextCursor != null &&
          (page.nextCursor == cursor ||
              _seenCursors.contains(page.nextCursor))) {
        throw StoreException(
          'The list changed while loading. Pull down to refresh.',
        );
      }
      final combined = <String, T>{
        if (!first)
          for (final item in _items) widget.identity(item): item,
      };
      final before = combined.length;
      for (final item in page.items) {
        combined[widget.identity(item)] = item;
      }
      _emptyPages = combined.length == before && !first ? _emptyPages + 1 : 0;
      if (_emptyPages >= 2 && page.nextCursor != null) {
        throw StoreException(
          'No new items were received. Pull down to refresh.',
        );
      }
      setState(() {
        _items = combined.values.toList();
        _next = page.nextCursor;
        _more = _next != null;
        _pages = first ? 1 : _pages + 1;
        if (cursor != null) _seenCursors.add(cursor);
      });
      widget.onMetadata?.call(page.metadata);
    } on TimeoutException {
      if (mounted && generation == _generation) {
        setState(
          () => _error = StoreException(
            'Loading took too long. Check your connection and retry.',
          ),
        );
      }
    } catch (e) {
      if (mounted && generation == _generation) setState(() => _error = e);
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _busy = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _nearEnd();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _refresh,
    child: CustomScrollView(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (widget.header != null) SliverToBoxAdapter(child: widget.header),
        if (_updates)
          SliverToBoxAdapter(
            child: TextButton.icon(
              onPressed: () => _refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Updates available · refresh list'),
            ),
          ),
        if (_items.isEmpty && _busy)
          SliverToBoxAdapter(
            child: AppSkeleton(
              kind: widget.gridDelegate == null
                  ? SkeletonKind.list
                  : SkeletonKind.grid,
              count: widget.gridDelegate == null ? 4 : 6,
            ),
          )
        else if (_items.isEmpty && _error != null)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyPanel(
              icon: Icons.wifi_off_outlined,
              title: 'Could not load this list',
              message: '$_error',
              action: 'Try again',
              onAction: () => _refresh(),
            ),
          )
        else if (_items.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyPanel(
              icon: Icons.inventory_2_outlined,
              title: widget.emptyTitle,
              message: widget.emptyMessage,
              action: widget.emptyAction,
              onAction: widget.onEmptyAction,
            ),
          )
        else
          SliverPadding(
            padding: widget.padding,
            sliver: widget.gridDelegate != null
                ? SliverGrid(
                    gridDelegate: widget.gridDelegate!,
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => widget.itemBuilder(context, _items[i], i),
                      childCount: _items.length,
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: widget.itemBuilder(context, _items[i], i),
                      ),
                      childCount: _items.length,
                    ),
                  ),
          ),
        if (_items.isNotEmpty && _busy)
          const SliverToBoxAdapter(child: AppSkeleton(count: 2)),
        if (_items.isNotEmpty && _error != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('$_error', textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _fetch(first: _pages == 0),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry loading'),
                  ),
                ],
              ),
            ),
          ),
        if (_items.isNotEmpty && !_busy && !_more && _error == null)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'You’re all caught up',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ),
            ),
          ),
        if (!_more && widget.endContent != null && _items.isNotEmpty)
          SliverToBoxAdapter(child: widget.endContent),
      ],
    ),
  );
}
