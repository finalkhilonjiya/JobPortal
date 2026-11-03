import 'package:flutter/material.dart';

import '../../core/anim.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/api.dart';
import '../../widgets/common.dart';

class GuidesScreen extends StatefulWidget {
  const GuidesScreen({super.key});

  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
  late Future<List<Article>> _f = Api.articles();
  String _cat = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Guides and tips', style: AppText.h2)),
      body: FutureBuilder<List<Article>>(
        future: _f,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
          if (snap.hasError) return ErrorState(message: errText(snap.error!), onRetry: () => setState(() => _f = Api.articles()));
          final all = snap.data ?? <Article>[];
          if (all.isEmpty) return const EmptyState(icon: Icons.menu_book_rounded, title: 'No guides yet', message: 'Helpful articles will show up here.');
          final cats = all.map((e) => e.category).toSet().toList();
          final list = _cat.isEmpty ? all : all.where((e) => e.category == _cat).toList();
          return Column(children: [
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                children: [
                  PillChip(label: 'All', selected: _cat.isEmpty, onTap: () => setState(() => _cat = '')),
                  for (final c in cats) Padding(padding: const EdgeInsets.only(left: 8), child: PillChip(label: cap(c), selected: _cat == c, onTap: () => setState(() => _cat = c))),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 30),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final a = list[i];
                  return FadeSlideIn(
                    delay: stagger(i, stepMs: 40),
                    child: Pressable(
                      scale: 0.985,
                      onTap: () => Navigator.of(context).push(fadeRoute(ArticleScreen(article: a))),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: softShadow(10)),
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Badge2(a.category.toUpperCase()),
                              const SizedBox(height: 8),
                              Text(a.title, style: AppText.title),
                              if (a.summary.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(a.summary, style: AppText.bodyS, maxLines: 2, overflow: TextOverflow.ellipsis)),
                            ]),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.text3),
                        ]),
                      ),
                    ),
                  );
                },
              ),
            ),
          ]);
        },
      ),
    );
  }
}

class ArticleScreen extends StatelessWidget {
  final Article article;
  const ArticleScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    for (final raw in article.body.split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(padding: const EdgeInsets.only(top: 14, bottom: 6), child: Text(line.substring(3), style: AppText.h3)));
      } else if (line.startsWith('- ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(padding: EdgeInsets.only(top: 7, right: 10), child: Icon(Icons.circle, size: 6, color: AppColors.primary)),
            Expanded(child: Text(line.substring(2), style: AppText.bodyM.copyWith(fontSize: 15))),
          ]),
        ));
      } else {
        widgets.add(Padding(padding: const EdgeInsets.only(bottom: 4), child: Text(line, style: AppText.bodyM.copyWith(fontSize: 15))));
      }
    }
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(title: const Text('Guide', style: AppText.h3)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Badge2(article.category.toUpperCase()),
          const SizedBox(height: 12),
          Text(article.title, style: AppText.h1.copyWith(fontSize: 24)),
          if (article.summary.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(article.summary, style: AppText.bodyM.copyWith(fontSize: 15.5))),
          const SizedBox(height: 10),
          ...widgets,
        ],
      ),
    );
  }
}
