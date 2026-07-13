import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:proof/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalLinkButton extends StatelessWidget {
  const LegalLinkButton({
    super.key,
    required this.label,
    this.url,
    this.route,
  }) : assert(url != null || route != null);

  final String label;
  final String? url;
  final String? route;

  Future<void> _open(BuildContext context) async {
    if (route != null) {
      context.push(route!);
      return;
    }

    final uri = Uri.parse(url!);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _open(context),
      icon: Icon(
        route != null ? Icons.article_outlined : Icons.open_in_new,
        size: 18,
      ),
      label: Text(label),
    );
  }
}

class LegalInlineLink extends StatelessWidget {
  const LegalInlineLink({
    super.key,
    required this.label,
    this.url,
    this.route,
  }) : assert(url != null || route != null);

  final String label;
  final String? url;
  final String? route;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (route != null) {
          context.push(route!);
          return;
        }

        final uri = Uri.parse(url!);
        final launched =
            await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open $url')),
          );
        }
      },
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.accent,
              decoration: TextDecoration.underline,
            ),
      ),
    );
  }
}
