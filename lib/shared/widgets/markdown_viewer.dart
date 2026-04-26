import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:http/http.dart' as http;
import 'package:talkest/app/theme/text_styles.dart';
import 'package:url_launcher/url_launcher.dart';

class MarkdownViewer extends StatelessWidget {
  final String url;

  const MarkdownViewer({super.key, required this.url});

  Future<String> _loadMarkdown() async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return response.body;
      }
      return 'Failed to load document. (Status: ${response.statusCode})';
    } catch (e) {
      return 'Error connecting to server: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<String>(
      future: _loadMarkdown(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Text(
              'Something went wrong',
              style: AppTextStyles.bodyMedium.copyWith(
                color: colorScheme.error,
              ),
            ),
          );
        }

        return Markdown(
          data: snapshot.data!,
          selectable: true,
          onTapLink: (text, href, title) async {
            if (href != null) {
              final uri = Uri.parse(href);
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {
                debugPrint('Could not launch $href: $e');
              }
            }
          },
          padding: const EdgeInsets.all(16),
          styleSheet: MarkdownStyleSheet(
            h1: AppTextStyles.headlineLarge.copyWith(
              color: colorScheme.onSurface,
            ),
            h2: AppTextStyles.headlineMedium.copyWith(
              color: colorScheme.onSurface,
            ),
            h3: AppTextStyles.titleLarge.copyWith(color: colorScheme.onSurface),
            p: AppTextStyles.bodyMedium.copyWith(color: colorScheme.onSurface),
            a: AppTextStyles.link.copyWith(color: colorScheme.primary),
            listBullet: AppTextStyles.bodyMedium.copyWith(
              color: colorScheme.onSurface,
            ),
            strong: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
            blockquote: AppTextStyles.quote.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            blockquoteDecoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(color: colorScheme.primary, width: 4),
              ),
            ),
            horizontalRuleDecoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colorScheme.outlineVariant, width: 1),
              ),
            ),
            blockSpacing: 16,
          ),
        );
      },
    );
  }
}
