import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:talkest/app/provider/theme_provider.dart';
import 'package:talkest/app/theme/theme.dart';
import 'package:talkest/shared/utils/embed_context.dart';
import 'package:talkest/shared/utils/utils.dart';
import 'package:talkest/shared/widgets/custom_text_button.dart';

class AppScaffold extends StatefulWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints) body;
  final bool showAppBar;
  final bool showAppBarTitle;
  final Widget? customAppBarTitle;
  final PreferredSizeWidget? customAppBar;
  final bool isUsingBackButton;
  final bool isUsingSafeArea;
  final bool showProfileIcon;
  final bool showFunFactSection;
  final Widget? floatingActionButton;

  static const appBarDefaultConfig = _AppBarDefaultConfig();

  const AppScaffold({
    super.key,
    required this.body,
    this.showAppBar = true,
    this.showAppBarTitle = true,
    this.customAppBarTitle,
    this.customAppBar,
    this.isUsingBackButton = false,
    this.isUsingSafeArea = true,
    this.showProfileIcon = true,
    this.showFunFactSection = false,
    this.floatingActionButton,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  final appBarDefaultConfig = _AppBarDefaultConfig();
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
      extendBodyBehindAppBar: true,
      appBar: widget.showAppBar
          ? widget.customAppBar ??
                AppBar(
                  titleSpacing: widget.isUsingBackButton
                      ? appBarDefaultConfig.titleSpacing
                      : null,
                  leadingWidth: widget.isUsingBackButton
                      ? appBarDefaultConfig.leadingWidth
                      : null,
                  leading: widget.isUsingBackButton
                      ? appBarDefaultConfig.leading(context)
                      : null,
                  scrolledUnderElevation: 0,
                  title: widget.showAppBarTitle
                      ? widget.customAppBarTitle ??
                            Text("Talkest.", style: AppTextStyles.headlineSmall)
                      : null,
                  actionsPadding: const EdgeInsets.only(right: 8),
                  actions: [
                    if (widget.showProfileIcon)
                      CustomTextButton.icon(
                        padding: EdgeInsets.zero,
                        minWidth: 0,
                        icon: const Icon(Icons.account_circle),
                        onPressed: () {
                          // context.goNamed('profile');
                          final state = GoRouterState.of(context);

                          final embed = EmbedContext.fromUri(
                            state.uri,
                            pathTargetUid: state.pathParameters['id'],
                          );

                          if (embed.isValidEmbed) {
                            context.goNamed(
                              'profile',
                              queryParameters: {
                                'embed': '1',
                                'targetUid': embed.targetUid!,
                              },
                            );
                          } else {
                            context.goNamed('profile');
                          }
                        },
                        tooltip: 'Profile',
                      ),
                    _ThemeSwitcher(
                      currentMode: currentMode,
                      onThemeChanged: (mode) =>
                          themeProvider.setThemeModeTo(mode),
                    ),
                  ],
                )
          : null,
      floatingActionButton: widget.floatingActionButton,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              widget.isUsingSafeArea
                  ? SafeArea(child: widget.body(context, constraints))
                  : widget.body(context, constraints),
              if (widget.showFunFactSection)
                Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: constraints.maxHeight / 8,
                    horizontal: constraints.maxWidth / 6,
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
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

class _AppBarDefaultConfig {
  const _AppBarDefaultConfig();

  double get titleSpacing => 0;

  double get leadingWidth => 56 + 4; // 56 means default width of leading

  Widget leading(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: CustomTextButton.icon(
        minWidth: 0,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
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
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
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
