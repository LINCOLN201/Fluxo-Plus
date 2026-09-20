# Identidade Visual "Grafite Fluxo+" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Fluxo+ app's current green Material-seed color system with the approved "Grafite premium" identity (near-black surfaces + vivid lima/red accents, dark and light variants) across every screen, without touching navigation structure, typography, or app logic.

**Architecture:** Introduce a single `AppColors` class in `lib/core/theme/app_colors.dart` implementing Flutter's `ThemeExtension<AppColors>`, with `AppColors.dark` and `AppColors.light` constant instances holding the token values. Register one instance on each `ThemeData` in `lib/core/theme/app_theme.dart` via the `extensions:` list. Every screen reads colors through a `context.colors` extension getter instead of the old static `AppColors.primary`-style constants, so the same code automatically renders correctly in both themes — this eliminates the `dark ? Color(A) : Color(B)` ternaries currently duplicated across `main_shell.dart` and `dashboard_screen.dart`. Two screens (`splash_screen.dart`, and the promo header in `update_prompt.dart`) intentionally render with a fixed dark chrome regardless of the user's theme setting; those reference `AppColors.dark` directly rather than `context.colors`.

**Tech Stack:** Flutter 3.x / Dart >=3.4.0, Material 3 (`useMaterial3: true`), `flutter_test` for tests. No new dependencies.

**Spec:** `docs/superpowers/specs/2026-09-17-identidade-visual-grafite-design.md`

## Global Constraints

- Do not change navigation structure, screen layout, typography (keep `Manrope`), or iconography (keep Material Icons) — this is a color-only reskin.
- Both light and dark themes must remain fully supported and equally polished (per spec: "manter os dois temas").
- No changes to `lib/core/database/`, any `*_repository.dart`, or any business logic — presentation layer only.
- Normal body text must meet WCAG AA contrast (≥4.5:1) against its background; the two "dim"/tertiary tokens (`textMutedDim`) are exempt because they're documented as decorative/tertiary-only (never the sole carrier of information).
- Every task must leave `flutter analyze` clean (zero issues) for the files it touches, and the full `flutter test` suite passing, before committing.
- Follow existing project commit style (`type: short description`, seen in `git log`: `feat:`, `fix:`, `chore:`, `style:`).

---

## Migration Rules

These are referenced by ID in later tasks instead of being re-explained per line.

- **R1** — `dark ? const Color(A) : const Color(B)` (or `dark ? Colors.X : AppColors.Y`, etc.), where A/B are the app's own background/surface/border/text-muted/text-primary pair → single `context.colors.<token>` expression. The surrounding `final dark = Theme.of(context).brightness == Brightness.dark;` and any `dark`-only constructor parameter become dead code once every branch in that file is converted — remove them (this will show up as "unused" issues in `flutter analyze` if missed, so the check step catches it either way).
- **R2** — `AppColors.primary` (old static const) → `context.colors.primary` when used for brand/nav/accent purposes; → `context.colors.income` when used specifically to color a receita (income) amount.
- **R3** — `AppColors.expense` / `.warning` / `.muted` / `.text` (old static consts) → `context.colors.expense` / `.warning` / `.textMuted` / `.textPrimary` respectively.
- **R4** — `AppColors.primaryDark` (old static const) → `context.colors.onPrimary` when it was providing legible contrast against a `primary`-filled shape (icon/text drawn on top of a solid primary circle or highlight); the new `primary` (bright lima in dark mode) is too light for white-on-primary to still work, which is why this token exists.
- **R5** — Alpha-blended literal hex derived from the old primary/expense (e.g. `Color(0x660F9D58)` = old primary at ~40% alpha, `Color(0x330F9D58)` ≈ 20%, `Color(0x440F9D58)` ≈ 27%, `Color(0x33E53935)` ≈ 20%) → `context.colors.<token>.withValues(alpha: <same fraction>)`.
- **R6** — Full-bleed saturated gradient "hero" cards (dark-color → old accent color) with white/near-white text on top → replace with a solid `context.colors.surface` fill, optionally `border: Border.all(color: context.colors.<semantic>.withValues(alpha: .35))`. Reason: a gradient ending in the new `primary` (very light lima in dark mode) breaks contrast for white text sitting on top of it, and a solid neutral card with a colored value is what the approved mockup direction actually showed (colors on values, not on backgrounds). The big value number and any icon take the semantic color (`income`/`expense`) directly — verified ≥3:1 against `surface` at 24px+/bold, which is the applicable WCAG threshold for large text. Supporting/caption text takes `textMuted`.
- **R7** — Any `const` modifier on a widget/constructor whose color argument changes from a literal to `context.colors.X` must be removed — `context.colors` reads `Theme.of(context)` at runtime and is not a compile-time constant. This does **not** apply to `AppColors.dark.<field>` / `AppColors.light.<field>` — accessing a field of a `static const` instance is still a compile-time constant in Dart, so `const` can stay wherever it's used with those.
- **R8** — A `CustomPainter` has no `BuildContext`, so it cannot call `context.colors`. Pass the colors it needs in through its constructor from the caller (which does have `context`), as an `AppColors colors` field.
- **R9** — A widget whose only use of a `dark`/`bool` constructor parameter was to branch colors should have that parameter removed once its body reads `context.colors` directly. Update every call site. A missed call site becomes a compile error under `flutter analyze` (passing a named argument that no longer exists), so this is self-verifying.

---

### Task 1: `AppColors` theme extension + token tests

**Files:**
- Modify: `lib/core/theme/app_colors.dart` (full rewrite)
- Test: `test/core/theme/app_colors_test.dart` (new)

**Interfaces:**
- Produces: `class AppColors extends ThemeExtension<AppColors>` with fields `background, surface, surfaceElevated, border, textPrimary, textMuted, textMutedDim, primary, onPrimary, income, expense, warning` (all `Color`), plus `static const AppColors dark` and `static const AppColors light`, plus `extension AppColorsContext on BuildContext { AppColors get colors; }`. Every later task consumes `context.colors.<field>` and, for the two fixed-dark-chrome screens, `AppColors.dark.<field>` directly.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/theme/app_colors_test.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_plus/core/theme/app_colors.dart';

double _channelLuminance(double c) =>
    c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4).toDouble();

double _relativeLuminance(Color color) =>
    0.2126 * _channelLuminance(color.r) +
    0.7152 * _channelLuminance(color.g) +
    0.0722 * _channelLuminance(color.b);

double _contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a);
  final lb = _relativeLuminance(b);
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('AppColors.dark', () {
    test('token values', () {
      expect(AppColors.dark.background, const Color(0xFF0A0A0B));
      expect(AppColors.dark.surface, const Color(0xFF151516));
      expect(AppColors.dark.surfaceElevated, const Color(0xFF1A1A1C));
      expect(AppColors.dark.border, const Color(0xFF262628));
      expect(AppColors.dark.textPrimary, const Color(0xFFF2F2F0));
      expect(AppColors.dark.textMuted, const Color(0xFF8A8A8E));
      expect(AppColors.dark.textMutedDim, const Color(0xFF6E6E72));
      expect(AppColors.dark.primary, const Color(0xFFC6FF5E));
      expect(AppColors.dark.onPrimary, const Color(0xFF0A0A0B));
      expect(AppColors.dark.income, const Color(0xFFC6FF5E));
      expect(AppColors.dark.expense, const Color(0xFFFF5C5C));
      expect(AppColors.dark.warning, const Color(0xFFF2B84B));
    });

    test('textPrimary meets WCAG AA (4.5:1) on background', () {
      expect(
        _contrastRatio(AppColors.dark.textPrimary, AppColors.dark.background),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('textMuted meets WCAG AA (4.5:1) on background', () {
      expect(
        _contrastRatio(AppColors.dark.textMuted, AppColors.dark.background),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('expense meets WCAG AA (4.5:1) on background', () {
      expect(
        _contrastRatio(AppColors.dark.expense, AppColors.dark.background),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('warning meets WCAG AA (4.5:1) on background', () {
      expect(
        _contrastRatio(AppColors.dark.warning, AppColors.dark.background),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('onPrimary meets WCAG AA (4.5:1) on primary', () {
      expect(
        _contrastRatio(AppColors.dark.onPrimary, AppColors.dark.primary),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  group('AppColors.light', () {
    test('token values', () {
      expect(AppColors.light.background, const Color(0xFFF5F5F3));
      expect(AppColors.light.surface, const Color(0xFFFFFFFF));
      expect(AppColors.light.surfaceElevated, const Color(0xFFF0F0EE));
      expect(AppColors.light.border, const Color(0xFFE4E4E1));
      expect(AppColors.light.textPrimary, const Color(0xFF1A1A1B));
      expect(AppColors.light.textMuted, const Color(0xFF6E6E72));
      expect(AppColors.light.textMutedDim, const Color(0xFF9A9A96));
      expect(AppColors.light.primary, const Color(0xFF4A7010));
      expect(AppColors.light.onPrimary, const Color(0xFFFFFFFF));
      expect(AppColors.light.income, const Color(0xFF4A7010));
      expect(AppColors.light.expense, const Color(0xFFC22B2B));
      expect(AppColors.light.warning, const Color(0xFF8A5A00));
    });

    test('textPrimary meets WCAG AA (4.5:1) on background', () {
      expect(
        _contrastRatio(
            AppColors.light.textPrimary, AppColors.light.background),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('textMuted meets WCAG AA (4.5:1) on background', () {
      expect(
        _contrastRatio(AppColors.light.textMuted, AppColors.light.background),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('primary meets WCAG AA (4.5:1) on background', () {
      expect(
        _contrastRatio(AppColors.light.primary, AppColors.light.background),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('expense meets WCAG AA (4.5:1) on background', () {
      expect(
        _contrastRatio(AppColors.light.expense, AppColors.light.background),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('warning meets WCAG AA (4.5:1) on background', () {
      expect(
        _contrastRatio(AppColors.light.warning, AppColors.light.background),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('onPrimary meets WCAG AA (4.5:1) on primary', () {
      expect(
        _contrastRatio(AppColors.light.onPrimary, AppColors.light.primary),
        greaterThanOrEqualTo(4.5),
      );
    });
  });

  testWidgets('context.colors resolves the extension registered on the theme',
      (tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.dark]),
      home: Builder(
        builder: (context) {
          capturedContext = context;
          return const SizedBox();
        },
      ),
    ));
    expect(capturedContext.colors, AppColors.dark);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/theme/app_colors_test.dart`
Expected: FAIL to compile — `AppColors.dark`/`.light` don't exist yet, current `AppColors` only has `primary`, `primaryDark`, `background`, `text`, `muted`, `expense`, `warning`, `income` as flat static consts, and there is no `context.colors` extension.

- [ ] **Step 3: Write the implementation**

```dart
// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.textMutedDim,
    required this.primary,
    required this.onPrimary,
    required this.income,
    required this.expense,
    required this.warning,
  });

  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color textMutedDim;
  final Color primary;
  final Color onPrimary;
  final Color income;
  final Color expense;
  final Color warning;

  static const dark = AppColors(
    background: Color(0xFF0A0A0B),
    surface: Color(0xFF151516),
    surfaceElevated: Color(0xFF1A1A1C),
    border: Color(0xFF262628),
    textPrimary: Color(0xFFF2F2F0),
    textMuted: Color(0xFF8A8A8E),
    textMutedDim: Color(0xFF6E6E72),
    primary: Color(0xFFC6FF5E),
    onPrimary: Color(0xFF0A0A0B),
    income: Color(0xFFC6FF5E),
    expense: Color(0xFFFF5C5C),
    warning: Color(0xFFF2B84B),
  );

  static const light = AppColors(
    background: Color(0xFFF5F5F3),
    surface: Color(0xFFFFFFFF),
    surfaceElevated: Color(0xFFF0F0EE),
    border: Color(0xFFE4E4E1),
    textPrimary: Color(0xFF1A1A1B),
    textMuted: Color(0xFF6E6E72),
    textMutedDim: Color(0xFF9A9A96),
    primary: Color(0xFF4A7010),
    onPrimary: Color(0xFFFFFFFF),
    income: Color(0xFF4A7010),
    expense: Color(0xFFC22B2B),
    warning: Color(0xFF8A5A00),
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? border,
    Color? textPrimary,
    Color? textMuted,
    Color? textMutedDim,
    Color? primary,
    Color? onPrimary,
    Color? income,
    Color? expense,
    Color? warning,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textMuted: textMuted ?? this.textMuted,
      textMutedDim: textMutedDim ?? this.textMutedDim,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      income: income ?? this.income,
      expense: expense ?? this.expense,
      warning: warning ?? this.warning,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textMutedDim: Color.lerp(textMutedDim, other.textMutedDim, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/theme/app_colors_test.dart`
Expected: PASS (all groups green).

- [ ] **Step 5: Commit**

```bash
git add lib/core/theme/app_colors.dart test/core/theme/app_colors_test.dart
git commit -m "feat: replace AppColors with theme-aware Grafite token extension"
```

---

### Task 2: Wire `AppColors` into `AppTheme`

**Files:**
- Modify: `lib/core/theme/app_theme.dart` (full rewrite)
- Test: `test/core/theme/app_theme_test.dart` (new)

**Interfaces:**
- Consumes: `AppColors`, `AppColors.dark`, `AppColors.light` from Task 1.
- Produces: `AppTheme.light()` and `AppTheme.dark()` each return a `ThemeData` with `extensions: [AppColors.light]` / `[AppColors.dark]` registered, so `context.colors` resolves correctly anywhere under a `MaterialApp` using these themes.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/theme/app_theme_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_plus/core/theme/app_colors.dart';
import 'package:fluxo_plus/core/theme/app_theme.dart';

void main() {
  testWidgets('AppTheme.dark() registers AppColors.dark', (tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: Builder(
        builder: (context) {
          capturedContext = context;
          return const SizedBox();
        },
      ),
    ));
    final theme = Theme.of(capturedContext);
    expect(theme.extension<AppColors>(), AppColors.dark);
    expect(theme.scaffoldBackgroundColor, AppColors.dark.background);
  });

  testWidgets('AppTheme.light() registers AppColors.light', (tester) async {
    late BuildContext capturedContext;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Builder(
        builder: (context) {
          capturedContext = context;
          return const SizedBox();
        },
      ),
    ));
    final theme = Theme.of(capturedContext);
    expect(theme.extension<AppColors>(), AppColors.light);
    expect(theme.scaffoldBackgroundColor, AppColors.light.background);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/theme/app_theme_test.dart`
Expected: FAIL — current `AppTheme.light()`/`dark()` don't register any `ThemeExtension`, so `theme.extension<AppColors>()` is `null`.

- [ ] **Step 3: Write the implementation**

```dart
// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() {
    const colors = AppColors.light;
    final scheme = ColorScheme.fromSeed(
      seedColor: colors.primary,
      brightness: Brightness.light,
      primary: colors.primary,
      surface: colors.surface,
      error: colors.expense,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      fontFamily: 'Manrope',
      fontFamilyFallback: const ['Inter', 'Roboto', 'Segoe UI'],
      extensions: const [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: colors.textPrimary),
        bodyMedium: TextStyle(color: colors.textMuted),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        labelStyle: TextStyle(color: colors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colors.border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colors.primary.withValues(alpha: .16),
      ),
      navigationRailTheme: NavigationRailThemeData(
        indicatorColor: colors.primary.withValues(alpha: .16),
      ),
    );
  }

  static ThemeData dark() {
    const colors = AppColors.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: colors.primary,
      brightness: Brightness.dark,
      primary: colors.primary,
      surface: colors.surface,
      error: colors.expense,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      fontFamily: 'Manrope',
      extensions: const [colors],
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: TextStyle(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: colors.textPrimary),
        bodyMedium: TextStyle(color: colors.textMuted),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: colors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        labelStyle: TextStyle(color: colors.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: colors.primary.withValues(alpha: .16),
      ),
      navigationRailTheme: NavigationRailThemeData(
        indicatorColor: colors.primary.withValues(alpha: .16),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/theme/app_theme_test.dart`
Expected: PASS.

- [ ] **Step 5: Run the full existing suite before moving on**

Run: `flutter test`
Expected: PASS (nothing else references `AppTheme` yet in a way that would break — `main.dart` and `app.dart` only call `AppTheme.light()`/`dark()` positionally).

- [ ] **Step 6: Commit**

```bash
git add lib/core/theme/app_theme.dart test/core/theme/app_theme_test.dart
git commit -m "feat: register Grafite AppColors extension on light/dark ThemeData"
```

---

### Task 3: Migrate `main_shell.dart`

**Files:**
- Modify: `lib/features/shell/presentation/main_shell.dart`

**Interfaces:**
- Consumes: `context.colors.*` from Task 1/2.

At this point `flutter analyze lib/features/shell/presentation/main_shell.dart` will already report compile errors — `AppColors.primary`, `.primaryDark` no longer exist as static members. That is the expected "red" state for this task.

- [ ] **Step 1: Run analyze to confirm the expected break**

Run: `flutter analyze lib/features/shell/presentation/main_shell.dart`
Expected: errors referencing `AppColors.primary`/`AppColors.primaryDark` as undefined static getters (from Task 1's rewrite).

- [ ] **Step 2: Apply the migration**

Top-level `_MainShellState.build` (around line 190): delete `final dark = Theme.of(context).brightness == Brightness.dark;` — no longer needed (R1/R9). Remove the `dark:` argument from both the `_DesktopSidebar(...)` and `_MobileNavigation(...)` instantiations inside the `LayoutBuilder`.

| Line(s) | Old | New | Rule |
|---|---|---|---|
| 202 | `dark ? const Color(0xFF0D1820) : const Color(0xFFF6F8FA)` (Scaffold `backgroundColor`) | `context.colors.background` | R1, R7 |
| 285-289 | `Container` decoration with `gradient: LinearGradient(colors: [Color(0xFF0B6B3A), AppColors.primary])` (profile header in `_MobileMore`) | `color: context.colors.surfaceElevated, border: Border.all(color: context.colors.border)` — drop the `gradient:` property entirely | R6 |
| 295-303 | `CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person_rounded, color: AppColors.primaryDark, ...))` | `CircleAvatar(backgroundColor: context.colors.primary, child: Icon(Icons.person_rounded, color: context.colors.onPrimary, ...))` | R4 |
| 309-316 | `Text(userName ?? ..., style: TextStyle(color: Colors.white, ...))` | `style: TextStyle(color: context.colors.textPrimary, ...)` | R1 |
| 318-323 | `Text(email ?? ..., style: TextStyle(color: Color(0xFFD4F4DF)))` | `style: TextStyle(color: context.colors.textMuted)` | R1 |
| 454 | `Border(right: BorderSide(color: Color(0xFF26343D)))` (desktop sidebar) | `Border(right: BorderSide(color: context.colors.border))` | R1 |
| 456 | `dark ? const Color(0xFF111E27) : Colors.white` (desktop sidebar bg) | `context.colors.surface` | R1, R7 |
| 495 | `selected ? const Color(0xFFE4F7EB) : Colors.transparent` (nav item highlight) | `selected ? context.colors.primary.withValues(alpha: .16) : Colors.transparent` | R5 |
| 507-515 | icon `color: selected ? AppColors.primaryDark : dark ? const Color(0xFF9AA8B1) : const Color(0xFF41505C)` | `color: selected ? context.colors.primary : context.colors.textMuted` | R2, R4, R1 |
| 517-529 | label `color: selected ? AppColors.primaryDark : dark ? const Color(0xFFE8EEF2) : AppColors.text` | `color: selected ? context.colors.primary : context.colors.textPrimary` | R2, R3, R4 |
| 544-545 | `CircleAvatar(backgroundColor: Color(0xFFE4F7EB), child: Icon(Icons.person_outline, color: AppColors.primary))` ("Meu perfil" footer) | `CircleAvatar(backgroundColor: context.colors.primary.withValues(alpha: .16), child: Icon(Icons.person_outline, color: context.colors.primary))` | R2, R5 |
| 600 | `dark ? const Color(0xFF111E27) : Colors.white` (mobile bottom nav bg) | `context.colors.surface` | R1, R7 |
| 603 | `dark ? const Color(0xFF22313B) : const Color(0xFFE2E8EE)` (mobile bottom nav top border) | `context.colors.border` | R1, R7 |
| 620-625 | FAB circle `color: AppColors.primary`, shadow `color: Color(0x660F9D58)` | `color: context.colors.primary`; shadow `color: context.colors.primary.withValues(alpha: .4)` | R2, R5 |
| 631 | FAB `Icon(Icons.add_rounded, color: Colors.white)` | `Icon(Icons.add_rounded, color: context.colors.onPrimary)` — **important:** white-on-lima is unreadable in dark mode, this must use `onPrimary`, not `textPrimary` | R4 |
| 655, 662 | `selected ? AppColors.primary : const Color(0xFF82909A)` (mobile nav icon/label) | `selected ? context.colors.primary : context.colors.textMuted` | R2, R1 |

`_FluxoMark` (around line 672-717): the first shape already uses `AppColors.primary` as a flat `color:` — change to `context.colors.primary` (R2). The second shape uses `gradient: LinearGradient(colors: [AppColors.primary, AppColors.primaryDark])` — since `primaryDark` no longer exists, replace with a flat `color: context.colors.primary` (drop the `gradient:` property), matching R6's reasoning (a two-stop gradient using the old darker-green stop has no direct equivalent, and a solid fill is visually simpler and consistent with the rest of the reskin). The call site `const _FluxoMark(size: 34)` at line ~464 stays `const` — only the `Container` decorations *inside* `_FluxoMark.build()` lose their `const` modifiers.

`_DesktopSidebar` and `_MobileNavigation` classes: remove their `required this.dark` field and constructor parameter entirely (R9) — every color decision inside them now comes from `context.colors`.

- [ ] **Step 3: Run analyze to verify the file is clean**

Run: `flutter analyze lib/features/shell/presentation/main_shell.dart`
Expected: `No issues found!`

- [ ] **Step 4: Run the full test suite**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/shell/presentation/main_shell.dart
git commit -m "style: apply Grafite tokens to main shell navigation"
```

---

### Task 4: Migrate `dashboard_screen.dart`

**Files:**
- Modify: `lib/features/dashboard/presentation/dashboard_screen.dart`

**Interfaces:**
- Consumes: `context.colors.*` from Task 1/2.
- The `_FlowPainter` class needs a new `required AppColors colors` constructor field (R8) since it's a `CustomPainter` with no `BuildContext`.

- [ ] **Step 1: Run analyze to confirm the expected break**

Run: `flutter analyze lib/features/dashboard/presentation/dashboard_screen.dart`
Expected: errors referencing removed `AppColors` static members.

- [ ] **Step 2: Apply the migration**

Add `import '../../../core/theme/app_colors.dart';` if not already present (it is, per existing import at line 6 — no change needed there).

| Line(s) | Old | New | Rule |
|---|---|---|---|
| 116, 298 | `dark ? const Color(0xFF0D1820) : const Color(0xFFF6F8FA)` | `context.colors.background` | R1, R7 |
| 322 | `TextStyle(color: Color(0xFF91A0AA))` | `TextStyle(color: context.colors.textMuted)` | R1 |
| 336 | `Badge(backgroundColor: AppColors.expense, ...)` | `Badge(backgroundColor: context.colors.expense, ...)` | R3 |
| 341 | `color: dark ? Colors.white : AppColors.text` (notification bell icon) | `color: context.colors.textPrimary` | R1, R3 |
| 350-399 | "Despesas totais do mês" hero card: `gradient: LinearGradient(colors: [Color(0xFF922D2A), AppColors.expense])`, `boxShadow: [BoxShadow(color: Color(0x33E53935), ...)]`, title `TextStyle(color: Color(0xFFFFE3E3))`, chevron `Icon(color: Colors.white)`, amount `TextStyle(color: Colors.white, fontSize: 28, ...)`, caption `TextStyle(color: Color(0xFFFFD0D0), fontSize: 11)` | Apply R6: `decoration: BoxDecoration(color: context.colors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.colors.expense.withValues(alpha: .35)))` — drop `gradient`/`boxShadow`. Title → `TextStyle(color: context.colors.textMuted)`. Chevron icon → `color: context.colors.textMuted`. Amount → `TextStyle(color: context.colors.expense, fontSize: 28, fontWeight: FontWeight.w800)`. Caption → `TextStyle(color: context.colors.textMuted, fontSize: 11)` | R6 |
| 586 | `dark ? const Color(0xFF111E27) : Colors.white` (`_SummaryStatCard`/similar small stat card bg) | `context.colors.surface` | R1, R7 |
| 599 | `dark ? Colors.white : AppColors.text` (stat card value text) | `context.colors.textPrimary` | R1, R3 |
| 668, 691-712 | `_FlowPainter(items)` call site; class fields `this.items`; grid line `Paint()..color = const Color(0xFFE8EDF2)`; series calls `_drawLine(..., AppColors.primary)` and `_drawLine(..., AppColors.expense)` | See dedicated snippet below | R8 |
| 758, 803 | `dark ? const Color(0xFF91A0AA) : AppColors.muted` (`_CategoryChart` empty-state / percent text) | `context.colors.textMuted` | R1, R3 |
| 795 | `dark ? Colors.white : AppColors.text` (`_CategoryChart` item name) | `context.colors.textPrimary` | R1, R3 |
| 966 | `BorderSide(color: Color(0xFFE0E6EB))` | `BorderSide(color: context.colors.border)` | R1 |
| 1024, 1039 | `dark ? const Color(0xFF111E27) : Colors.white` / `const Color(0xFF111E27)` (bottom sheet or card bg) | `context.colors.surface` | R1, R7 |
| 1027 | `dark ? const Color(0xFF26343D) : const Color(0xFFE8EDF2)` | `context.colors.border` | R1, R7 |
| 1031 | `BoxShadow(color: Color(0x08000000), ...)` (near-transparent black shadow, theme-neutral) | Leave as-is — this is a generic ~3%-alpha black drop shadow, not derived from any app color; not part of this migration. | — |
| 1041 | `Border.all(color: const Color(0xFF22313B))` | `Border.all(color: context.colors.border)` | R1, R7 |

`_CategoryChart` (StatelessWidget, around line 745): remove its `this.dark = false` field and constructor parameter (R9). Update its two call sites (around lines 239 and 440) to stop passing `dark:`.

`_FlowPainter` (R8) — before:
```dart
class _FlowPainter extends CustomPainter {
  _FlowPainter(this.items);
  final List<MonthlyFlow> items;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFFE8EDF2)
      ..strokeWidth = 1;
    // ...
    _drawLine(canvas, size, maxValue, (item) => item.income, AppColors.primary);
    _drawLine(canvas, size, maxValue, (item) => item.expense, AppColors.expense);
  }
  // ...
}
```

after:
```dart
class _FlowPainter extends CustomPainter {
  _FlowPainter(this.items, {required this.colors});
  final List<MonthlyFlow> items;
  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = colors.border
      ..strokeWidth = 1;
    // ...
    _drawLine(canvas, size, maxValue, (item) => item.income, colors.income);
    _drawLine(canvas, size, maxValue, (item) => item.expense, colors.expense);
  }
  // ...

  @override
  bool shouldRepaint(covariant _FlowPainter oldDelegate) =>
      oldDelegate.items != items || oldDelegate.colors != colors;
}
```

And its call site (around line 668):
```dart
painter: _FlowPainter(items, colors: context.colors),
```

- [ ] **Step 3: Run analyze to verify the file is clean**

Run: `flutter analyze lib/features/dashboard/presentation/dashboard_screen.dart`
Expected: `No issues found!`

- [ ] **Step 4: Run the full test suite**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/dashboard/presentation/dashboard_screen.dart
git commit -m "style: apply Grafite tokens to dashboard screen"
```

---

### Task 5: Migrate `reports_screen.dart`

**Files:**
- Modify: `lib/features/reports/presentation/reports_screen.dart`

**Interfaces:**
- Consumes: `context.colors.*` from Task 1/2.

- [ ] **Step 1: Run analyze to confirm the expected break**

Run: `flutter analyze lib/features/reports/presentation/reports_screen.dart`
Expected: errors referencing removed `AppColors` static members (13 usages) plus the `AppColors.primary`/`.expense` references inside the hero gradient.

- [ ] **Step 2: Apply the migration**

`_ResultHero` (around lines 156-223) is the same full-bleed hero pattern as the dashboard's expense card — apply R6:

Before (lines 165-219, abbreviated):
```dart
decoration: BoxDecoration(
  gradient: LinearGradient(
    colors: positive
        ? const [Color(0xFF075F34), AppColors.primary]
        : const [Color(0xFF8F2525), AppColors.expense],
  ),
  borderRadius: BorderRadius.circular(20),
  boxShadow: [
    BoxShadow(
      color: (positive ? AppColors.primary : AppColors.expense)
          .withValues(alpha: .24),
      blurRadius: 22,
      offset: const Offset(0, 9),
    ),
  ],
),
// ...
Text('Resultado previsto do mês', style: TextStyle(color: Colors.white70)),
Icon(positive ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: Colors.white),
// ...
Text(AppFormatters.currency(report.result), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800)),
// ...
Text(..., style: const TextStyle(color: Colors.white)),
```

After:
```dart
final semantic = positive ? context.colors.income : context.colors.expense;
// ...
decoration: BoxDecoration(
  color: context.colors.surface,
  borderRadius: BorderRadius.circular(20),
  border: Border.all(color: semantic.withValues(alpha: .35)),
),
// ...
Text('Resultado previsto do mês', style: TextStyle(color: context.colors.textMuted)),
Icon(positive ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: semantic),
// ...
Text(AppFormatters.currency(report.result), style: TextStyle(color: semantic, fontSize: 30, fontWeight: FontWeight.w800)),
// ...
Text(..., style: TextStyle(color: context.colors.textMuted)),
```

(remove the `const` from the `Text`/`TextStyle` calls that now use `context.colors`/`semantic`, per R7.)

For the remaining 11 `AppColors.*` references elsewhere in the file (category bars, legends, totals — same shape as everywhere else): apply R2/R3 mechanically — `AppColors.primary` → `context.colors.income` or `context.colors.primary` depending on whether that spot colors an income value or a generic accent (check each call site: if it's coloring a receita amount/bar, use `.income`; if it's a generic highlight/icon, use `.primary`), `AppColors.expense` → `context.colors.expense`, `AppColors.muted`/`.text` → `context.colors.textMuted`/`.textPrimary`.

- [ ] **Step 3: Run analyze to verify the file is clean**

Run: `flutter analyze lib/features/reports/presentation/reports_screen.dart`
Expected: `No issues found!`

- [ ] **Step 4: Run the full test suite**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/reports/presentation/reports_screen.dart
git commit -m "style: apply Grafite tokens to reports screen"
```

---

### Task 6: Migrate `premium_screen.dart` and `update_prompt.dart`

**Files:**
- Modify: `lib/features/premium/presentation/premium_screen.dart`
- Modify: `lib/core/update/update_prompt.dart`

**Interfaces:**
- `premium_screen.dart` consumes `context.colors.*` (it's a normal theme-aware screen).
- `update_prompt.dart`'s header banner is a **fixed dark chrome** (it has no `dark ?` branching today — it always renders the same dark-green gradient regardless of the app's theme, since it's an urgent promo dialog). It consumes `AppColors.dark.*` directly, not `context.colors`, to preserve that intentional always-dark look. Needs a new `import '../theme/app_colors.dart';` — currently missing.

- [ ] **Step 1: Run analyze to confirm the expected break**

Run: `flutter analyze lib/features/premium/presentation/premium_screen.dart lib/core/update/update_prompt.dart`
Expected: errors in `premium_screen.dart` for removed `AppColors` static members; `update_prompt.dart` currently has no `AppColors` reference at all (it only has raw hex), so it won't error yet — that's fine, we're adding the import as part of this task's improvement.

- [ ] **Step 2: Apply the migration — `premium_screen.dart`**

| Line(s) | Old | New | Rule |
|---|---|---|---|
| 122 | `TextStyle(color: AppColors.muted, fontSize: 12)` | `TextStyle(color: context.colors.textMuted, fontSize: 12)` | R3 |
| 145 | `gradient: LinearGradient(colors: [Color(0xFF07140D), Color(0xFF08743E)])` (plan card header) | `color: context.colors.surfaceElevated` — drop `gradient:` | R6 |
| 150 | `BoxShadow(color: Color(0x330F9D58), ...)` | `BoxShadow(color: context.colors.primary.withValues(alpha: .2), ...)` | R5 |
| 167 | `Icon(..., color: Color(0xFFFFD54F))` (crown/star icon) | `Icon(..., color: context.colors.warning)` — closest existing semantic token for a gold accent | R3 (extended) |
| 189 | `TextStyle(color: Color(0xFFC8EED8))` | `TextStyle(color: context.colors.textMuted)` | R6 |
| 219 | `BorderSide(color: AppColors.primary, width: 2)` | `BorderSide(color: context.colors.primary, width: 2)` | R2 |
| 250 | `TextStyle(color: AppColors.muted)` | `TextStyle(color: context.colors.textMuted)` | R3 |
| 293-294 | `backgroundColor: AppColors.primary.withValues(alpha: .14)`, `Icon(..., color: AppColors.primary)` | `backgroundColor: context.colors.primary.withValues(alpha: .14)`, `Icon(..., color: context.colors.primary)` | R2 |

- [ ] **Step 3: Apply the migration — `update_prompt.dart`**

Add near the top of the file: `import '../theme/app_colors.dart';`

| Line(s) | Old | New | Rule |
|---|---|---|---|
| 100 | `gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF07120D), Color(0xFF0B6B3A)])` | `colors: [AppColors.dark.background, AppColors.dark.primary]` — keep the two-stop gradient (this banner is meant to pop), just swap in the new brand colors; keep `const` (R7 exception — `AppColors.dark.*` field access is compile-time const) | fixed-dark exception |
| 133 | `TextStyle(color: Color(0xFFC8EED8))` ("Nova versão disponível") | `TextStyle(color: AppColors.dark.textMuted)` | fixed-dark exception |

Leave the `Colors.white`/`Colors.white70`-based translucent circle (`Colors.white.withValues(alpha: .12/.18)`) and the title `Text('Fluxo+ ${update.version}', style: TextStyle(color: Colors.white, ...))` as-is for this task — they sit near the top-left of the gradient (the darker end), so contrast is fine. **Manual QA note for Task 10:** if visual review shows the title text overlapping the brighter/lima end of the gradient, change that one `Colors.white` to `AppColors.dark.textPrimary` and/or cap the gradient's second stop at `AppColors.dark.primary.withValues(alpha: .6)` instead of full strength.

- [ ] **Step 4: Run analyze to verify both files are clean**

Run: `flutter analyze lib/features/premium/presentation/premium_screen.dart lib/core/update/update_prompt.dart`
Expected: `No issues found!`

- [ ] **Step 5: Run the full test suite**

Run: `flutter test`
Expected: PASS (note: `test/core/update/update_prompt_test.dart` and `update_service_test.dart` already exist — confirm they still pass since this file changed).

- [ ] **Step 6: Commit**

```bash
git add lib/features/premium/presentation/premium_screen.dart lib/core/update/update_prompt.dart
git commit -m "style: apply Grafite tokens to premium screen and update prompt"
```

---

### Task 7: Migrate transactions feature (`new_transaction_screen.dart`, `transactions_screen.dart`)

**Files:**
- Modify: `lib/features/transactions/presentation/new_transaction_screen.dart`
- Modify: `lib/features/transactions/presentation/transactions_screen.dart`

**Interfaces:**
- Consumes: `context.colors.*` from Task 1/2. Neither file has hardcoded hex or `dark ?` branching — both are pure `AppColors.*` static references, so this is a mechanical R2/R3 pass.

- [ ] **Step 1: Run analyze to confirm the expected break**

Run: `flutter analyze lib/features/transactions/presentation/new_transaction_screen.dart lib/features/transactions/presentation/transactions_screen.dart`
Expected: errors referencing removed `AppColors` static members.

- [ ] **Step 2: Apply the migration — `new_transaction_screen.dart`**

| Line(s) | Old | New | Rule |
|---|---|---|---|
| 340-341 | `? AppColors.primary : AppColors.warning` (a toggle/segment, context: paid vs pending) | `? context.colors.primary : context.colors.warning` | R2, R3 |
| 361-362 | `? AppColors.primary : AppColors.expense` (income vs expense type toggle) | `? context.colors.income : context.colors.expense` — this one specifically distinguishes receita from despesa, so use `.income` (not `.primary`) | R2, R3 |
| 406 | `color: AppColors.primary.withValues(alpha: .10)` | `color: context.colors.primary.withValues(alpha: .10)` | R2 |
| 411 | `Icon(Icons.calculate_outlined, color: AppColors.primary)` | `Icon(Icons.calculate_outlined, color: context.colors.primary)` | R2 |

- [ ] **Step 3: Apply the migration — `transactions_screen.dart`**

| Line(s) | Old | New | Rule |
|---|---|---|---|
| 97 | `FilledButton.styleFrom(backgroundColor: AppColors.expense)` | `FilledButton.styleFrom(backgroundColor: context.colors.expense)` | R3 |
| 338 | `final color = income ? AppColors.primary : AppColors.expense;` | `final color = income ? context.colors.income : context.colors.expense;` | R2, R3 |
| 392-395 | `? AppColors.primary : ? AppColors.expense : AppColors.warning` (3-way status color: paid/overdue/pending) | `? context.colors.income : ? context.colors.expense : context.colors.warning` | R2, R3 |
| 401 | `color: AppColors.muted` | `color: context.colors.textMuted` | R3 |

- [ ] **Step 4: Run analyze to verify both files are clean**

Run: `flutter analyze lib/features/transactions/presentation/new_transaction_screen.dart lib/features/transactions/presentation/transactions_screen.dart`
Expected: `No issues found!`

- [ ] **Step 5: Run the full test suite**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/transactions/presentation/new_transaction_screen.dart lib/features/transactions/presentation/transactions_screen.dart
git commit -m "style: apply Grafite tokens to transactions feature"
```

---

### Task 8: Migrate `accounts_screen.dart`, `goals_screen.dart`, `categories_screen.dart`, `notification_center_screen.dart`

**Files:**
- Modify: `lib/features/accounts/presentation/accounts_screen.dart`
- Modify: `lib/features/goals/presentation/goals_screen.dart`
- Modify: `lib/features/categories/presentation/categories_screen.dart`
- Modify: `lib/features/notifications/presentation/notification_center_screen.dart`

**Interfaces:**
- Consumes: `context.colors.*` from Task 1/2.

- [ ] **Step 1: Run analyze to confirm the expected break**

Run: `flutter analyze lib/features/accounts/presentation/accounts_screen.dart lib/features/goals/presentation/goals_screen.dart lib/features/categories/presentation/categories_screen.dart lib/features/notifications/presentation/notification_center_screen.dart`
Expected: errors referencing removed `AppColors` static members.

- [ ] **Step 2: Apply the migration**

`accounts_screen.dart` (line 173) and `goals_screen.dart` (line 225) both have the identical pattern — an account/goal list tile leading avatar:

Before:
```dart
leading: const CircleAvatar(
  backgroundColor: Color(0xFFE4F7EB),
  child: Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
),
```

After (drop `const` per R7):
```dart
leading: CircleAvatar(
  backgroundColor: context.colors.primary.withValues(alpha: .16),
  child: Icon(Icons.account_balance_wallet_rounded, color: context.colors.primary),
),
```

(`goals_screen.dart` uses `Icons.flag_rounded` instead of `Icons.account_balance_wallet_rounded` — same substitution otherwise.)

`categories_screen.dart` (lines 119-120):
```dart
? AppColors.primary.toARGB32()
: AppColors.expense.toARGB32()
```
→
```dart
? context.colors.primary.toARGB32()
: context.colors.expense.toARGB32()
```
(R2, R3 — `.toARGB32()` call is unaffected, just the receiver changes.)

`notification_center_screen.dart`:

| Line(s) | Old | New | Rule |
|---|---|---|---|
| 84 | `Icon(..., color: AppColors.primary)` | `Icon(..., color: context.colors.primary)` | R2 |
| 113 | `backgroundColor: AppColors.primary` | `backgroundColor: context.colors.primary` | R2 |
| 178 | `final statusColor = overdue ? AppColors.expense : AppColors.warning;` | `final statusColor = overdue ? context.colors.expense : context.colors.warning;` | R3 |

- [ ] **Step 3: Run analyze to verify all four files are clean**

Run: `flutter analyze lib/features/accounts/presentation/accounts_screen.dart lib/features/goals/presentation/goals_screen.dart lib/features/categories/presentation/categories_screen.dart lib/features/notifications/presentation/notification_center_screen.dart`
Expected: `No issues found!`

- [ ] **Step 4: Run the full test suite**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/features/accounts/presentation/accounts_screen.dart lib/features/goals/presentation/goals_screen.dart lib/features/categories/presentation/categories_screen.dart lib/features/notifications/presentation/notification_center_screen.dart
git commit -m "style: apply Grafite tokens to accounts, goals, categories, notifications"
```

---

### Task 9: Migrate `settings_screen.dart`, `onboarding_screen.dart`, `splash_screen.dart`

**Files:**
- Modify: `lib/features/settings/presentation/settings_screen.dart`
- Modify: `lib/features/onboarding/presentation/onboarding_screen.dart`
- Modify: `lib/features/splash/presentation/splash_screen.dart`

**Interfaces:**
- `settings_screen.dart` and `onboarding_screen.dart` consume `context.colors.*`.
- `splash_screen.dart` is the other **fixed dark chrome** screen (renders before any theme preference is loaded) — consumes `AppColors.dark.*` directly, like `update_prompt.dart` in Task 6.

- [ ] **Step 1: Run analyze to confirm the expected break**

Run: `flutter analyze lib/features/settings/presentation/settings_screen.dart lib/features/onboarding/presentation/onboarding_screen.dart lib/features/splash/presentation/splash_screen.dart`
Expected: errors referencing removed `AppColors` static members in all three files.

- [ ] **Step 2: Apply the migration — `settings_screen.dart`**

All 6 usages are `AppColors.primary` for icons/switch colors (lines 57, 64, 154, 161, 185, 530) → `context.colors.primary` (R2). The existing `final dark = Theme.of(context).brightness == Brightness.dark;` (line 31) **stays** — it's legitimately used at line 184 to pick between `Icons.nightlight_round`/`Icons.wb_sunny_outlined`, unrelated to color (do not apply R9 here).

- [ ] **Step 3: Apply the migration — `onboarding_screen.dart`**

Before (lines 22-33):
```dart
Container(
  padding: const EdgeInsets.all(28),
  decoration: const BoxDecoration(
    shape: BoxShape.circle,
    color: Color(0xFFDDF5E8),
  ),
  child: const Icon(Icons.insights_rounded, size: 72, color: AppColors.primary),
),
```
After (drop `const` on the outer `Container`/`BoxDecoration`/`Icon` per R7):
```dart
Container(
  padding: const EdgeInsets.all(28),
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    color: context.colors.primary.withValues(alpha: .16),
  ),
  child: Icon(Icons.insights_rounded, size: 72, color: context.colors.primary),
),
```

- [ ] **Step 4: Apply the migration — `splash_screen.dart`**

Add `import` is already present (line 3: `import '../../../core/theme/app_colors.dart';`).

| Line(s) | Old | New | Rule |
|---|---|---|---|
| 11 | `Scaffold(backgroundColor: Color(0xFF050807), ...)` | `Scaffold(backgroundColor: AppColors.dark.background, ...)` | fixed-dark exception |
| 21 | `TextStyle(color: Colors.white, fontSize: 38, ...)` ('Fluxo+' title) | `TextStyle(color: AppColors.dark.textPrimary, fontSize: 38, ...)` | fixed-dark exception |
| 29 | `TextStyle(color: Color(0xFFB7C2BD), fontSize: 16)` (tagline) | `TextStyle(color: AppColors.dark.textMuted, fontSize: 16)` | fixed-dark exception |
| 35-36 | `LinearProgressIndicator(color: AppColors.primary, backgroundColor: Color(0xFF1A2420), ...)` | `LinearProgressIndicator(color: AppColors.dark.primary, backgroundColor: AppColors.dark.surfaceElevated, ...)` | fixed-dark exception |
| 56 | `Color(0xFF0D1712)` (`_SplashMark` bg) | `AppColors.dark.surface` | fixed-dark exception |
| 58 | `Border.all(color: const Color(0xFF1F3D2D))` | `Border.all(color: AppColors.dark.border)` | fixed-dark exception |
| 60 | `BoxShadow(color: Color(0x440F9D58), blurRadius: 30)` | `BoxShadow(color: AppColors.dark.primary.withValues(alpha: .27), blurRadius: 30)` | R5, fixed-dark exception |
| 66 | `Icon(Icons.show_chart_rounded, size: 45, color: AppColors.primary)` | `Icon(Icons.show_chart_rounded, size: 45, color: AppColors.dark.primary)` | fixed-dark exception |

All `const` modifiers in this file can stay exactly as they are today (R7 exception — `AppColors.dark.<field>` is a compile-time constant).

- [ ] **Step 5: Run analyze to verify all three files are clean**

Run: `flutter analyze lib/features/settings/presentation/settings_screen.dart lib/features/onboarding/presentation/onboarding_screen.dart lib/features/splash/presentation/splash_screen.dart`
Expected: `No issues found!`

- [ ] **Step 6: Run the full test suite**

Run: `flutter test`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/settings/presentation/settings_screen.dart lib/features/onboarding/presentation/onboarding_screen.dart lib/features/splash/presentation/splash_screen.dart
git commit -m "style: apply Grafite tokens to settings, onboarding, splash"
```

---

### Task 10: Whole-app verification pass

**Files:** none (verification only, possible small fixups if gaps are found)

**Interfaces:** none.

- [ ] **Step 1: Confirm no old references remain anywhere in `lib/`**

Run: `grep -rn "AppColors\.\(primary\|primaryDark\|background\|text\|muted\|expense\|warning\|income\)\b" lib/ --include=*.dart | grep -v "core/theme/app_colors.dart" | grep -v "core/theme/app_theme.dart"`
Expected: no output. (`AppColors.dark.<field>` and `AppColors.light.<field>` matches are fine and expected in `splash_screen.dart`/`update_prompt.dart`/`app_theme.dart`; this grep only flags the *old flat static* access pattern, which no longer compiles anyway — this is a belt-and-suspenders check on top of `flutter analyze`.)

- [ ] **Step 2: Confirm no stray hex literals remain outside the token files and the two fixed-dark-chrome files**

Run: `grep -rln "Color(0x" lib/ --include=*.dart | grep -v "core/theme/app_colors.dart\|core/theme/app_theme.dart\|features/splash/presentation/splash_screen.dart\|core/update/update_prompt.dart"`
Expected: no output.

- [ ] **Step 3: Full static analysis**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 4: Full test suite**

Run: `flutter test`
Expected: all tests pass.

- [ ] **Step 5: Manual visual QA**

Launch the app (`flutter run`, or the project's `scripts/run_dev.sh`) and walk through both themes (toggle in Configurações) on both a mobile-width and a desktop-width window (breakpoint is 980px in `MainShell`):
- Dashboard, Transações, Contas, Metas, Relatórios, Categorias, Configurações, Premium, notification center, onboarding (reset via app data or a debug flag if available), splash (cold start).
- Specifically check: FAB "+" icon legible in dark mode (Task 3's `onPrimary` fix), the two former gradient "hero" cards (dashboard expense card, reports result card) read clearly with no leftover gradient, and the `update_prompt.dart` title text has enough contrast against the gradient (per Task 6's note — adjust if needed).
- If any contrast or leftover-old-color issue is found, fix inline in the relevant file and re-run Steps 3-4.

- [ ] **Step 6: Commit any fixups found in Step 5**

Only if changes were made:
```bash
git add -A -- lib/
git commit -m "fix: address visual QA findings from Grafite reskin rollout"
```

If Step 5 required no changes, there is nothing to commit for this task — the plan is complete as of Task 9's commits.
