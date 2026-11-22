import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/async_view.dart';
import '../../core/widgets/badges.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/net_image.dart';
import '../../models/conservation.dart';
import '../../models/json.dart';
import '../../state/services.dart';

class NewsTile extends StatelessWidget {
  const NewsTile({super.key, required this.article});
  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final a = article;
    return Panel(
      padding: const EdgeInsets.all(10),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailScreen(article: a))),
      child: Row(children: [
        NetImage(a.thumbnailUrl, width: 96, height: 80, icon: a.ecosystem.icon),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            EcosystemTag(a.ecosystem),
            const SizedBox(height: 4),
            Text(a.title, style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(Fmt.date(a.publishedAt), style: t.labelSmall?.copyWith(color: AppColors.textMuted)),
          ]),
        ),
      ]),
    );
  }
}

class NewsListScreen extends StatelessWidget {
  const NewsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Impact stories')),
      body: AsyncView<Paged<NewsArticle>>(
        load: () => context.read<Services>().conservation.news(),
        isEmpty: (p) => p.items.isEmpty,
        empty: const EmptyState(title: 'No stories yet', message: 'Field updates will appear here.', icon: Icons.article_outlined),
        builder: (context, page, reload) => RefreshIndicator(
          onRefresh: reload,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: page.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, i) => NewsTile(article: page.items[i]),
          ),
        ),
      ),
    );
  }
}

class NewsDetailScreen extends StatelessWidget {
  const NewsDetailScreen({super.key, required this.article});
  final NewsArticle article;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final a = article;
    return Scaffold(
      appBar: AppBar(title: const Text('Impact story')),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
        NetImage(a.thumbnailUrl, height: 210, icon: a.ecosystem.icon),
        const SizedBox(height: 14),
        Row(children: [
          EcosystemTag(a.ecosystem),
          const Spacer(),
          Text(Fmt.date(a.publishedAt), style: t.labelMedium?.copyWith(color: AppColors.textMuted)),
        ]),
        const SizedBox(height: 10),
        Text(a.title, style: t.headlineSmall),
        const SizedBox(height: 10),
        Text(a.summary, style: t.titleSmall?.copyWith(color: AppColors.textMuted, height: 1.4)),
        const Divider(height: 28),
        Text(a.content, style: t.bodyLarge?.copyWith(height: 1.55)),
      ]),
    );
  }
}
