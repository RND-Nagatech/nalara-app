class PageResult<T> {
  final List<T> items;
  final int total, page, limit;
  const PageResult({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });
  bool get hasNext => page * limit < total;
}

PageResult<T> appendPage<T>(PageResult<T> previous, PageResult<T> next) =>
    PageResult(
      items: List.unmodifiable([...previous.items, ...next.items]),
      total: next.total,
      page: next.page,
      limit: next.limit,
    );
