import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:talkest/app/provider/theme_provider.dart';
import 'package:talkest/app/theme/theme.dart';
import 'package:talkest/shared/utils/utils.dart';

class AppScaffold extends StatefulWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints) body;
  final bool showAppBar;
  final bool showAppBarTitle;
  final bool showFunFactSection;

  const AppScaffold({
    super.key,
    required this.body,
    this.showAppBar = true,
    this.showAppBarTitle = true,
    this.showFunFactSection = true,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  String funFact = "";

  @override
  void initState() {
    funFact = getRandomChattingAppTip();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final currentMode = themeProvider.getThemeMode;

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: widget.showAppBarTitle
                  ? Text("Talkest.", style: AppTextStyles.headlineSmall)
                  : null,
              actions: [
                _ThemeSwitcher(
                  currentMode: currentMode,
                  onThemeChanged: (mode) => themeProvider.setThemeModeTo(mode),
                ),
                const SizedBox(width: 8),
              ],
            )
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              widget.body(context, constraints),
              if (widget.showFunFactSection)
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: constraints.maxHeight / 8,
                    horizontal: constraints.maxWidth / 6,
                  ),
                  child: Align(
                    alignment: AlignmentGeometry.bottomCenter,
                    child: Container(
                      constraints: BoxConstraints(maxWidth: 300),
                      child: Text(
                        "Fun Fact!\n$funFact",
                        textAlign: TextAlign.center,
                        style: AppTextStyles.quote.copyWith(fontSize: 12),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ThemeSwitcher extends StatelessWidget {
  final ThemeMode currentMode;
  final Function(ThemeMode) onThemeChanged;

  const _ThemeSwitcher({
    required this.currentMode,
    required this.onThemeChanged,
  });

  IconData _getThemeIcon(ThemeMode mode, Brightness brightness) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
      case ThemeMode.system:
        // Show current system theme icon
        return brightness == Brightness.dark
            ? Icons.dark_mode_rounded
            : Icons.light_mode_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;

    return PopupMenuButton<ThemeMode>(
      icon: Icon(_getThemeIcon(currentMode, brightness)),
      tooltip: 'Change theme',
      onSelected: onThemeChanged,
      itemBuilder: (BuildContext context) => [
        _buildMenuItem(
          context,
          ThemeMode.system,
          Icons.brightness_auto_rounded,
          'System',
          'Follow system theme',
        ),
        _buildMenuItem(
          context,
          ThemeMode.light,
          Icons.light_mode_rounded,
          'Light',
          'Always use light theme',
        ),
        _buildMenuItem(
          context,
          ThemeMode.dark,
          Icons.dark_mode_rounded,
          'Dark',
          'Always use dark theme',
        ),
      ],
    );
  }

  PopupMenuItem<ThemeMode> _buildMenuItem(
    BuildContext context,
    ThemeMode mode,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final isSelected = currentMode == mode;
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuItem<ThemeMode>(
      value: mode,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          icon,
          color: isSelected ? colorScheme.primary : colorScheme.onSurface,
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: isSelected
            ? Icon(
                Icons.check_circle_rounded,
                color: colorScheme.primary,
                size: 20,
              )
            : null,
      ),
    );
  }
}
