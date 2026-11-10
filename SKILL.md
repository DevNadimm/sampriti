---
name: flutter-nadim-codegen
description: >
  Generate Flutter code matching Nadim's exact project style for VaraKhata / WhisperBD.
  Use this skill whenever Nadim asks to generate, scaffold, or write any Flutter code:
  new features, pages, blocs, repos, models, widgets, or anything code-related in Flutter.
  Even for small snippets — always follow this style guide.
---

# Flutter Code Generation — Nadim's Style

## Project Structure

```
lib/
├── main.dart                    # navigatorKey + init() + DevicePreview(enabled:false)
├── app.dart                     # MyApp with navigatorKey, theme, home: SplashPage
├── core/
│   ├── config/
│   │   ├── colors.dart          # AppColors
│   │   ├── assets.dart          # Assets
│   │   ├── messages.dart        # AppMessages
│   │   ├── api_endpoints.dart   # ApiEndpoints
│   │   └── app_config.dart
│   ├── exceptions/
│   │   └── api_exception.dart
│   ├── services/
│   │   ├── dio_service.dart
│   │   ├── app_preferences.dart
│   │   └── service_locator.dart  # GetIt init()
│   ├── utils/enums/
│   │   ├── error_type.dart       # ErrorType enum
│   │   └── message_type.dart
│   ├── components/               # App-wide reusable UI
│   │   ├── custom_text_field.dart
│   │   ├── spring_button.dart
│   │   └── ...
│   └── shared/
│       ├── themes/theme.dart
│       └── widgets/
│           ├── gradient_background.dart
│           ├── inline_error_widget.dart
│           ├── error_state_widget.dart
│           ├── empty_state_widget.dart
│           ├── loader.dart
│           └── app_notifier.dart
└── features/
    └── {feature}/
        ├── data/
        │   ├── models/           # Pure Dart models, fromJson only
        │   └── repos/            # Static methods, uses GetIt DioService
        └── presentation/
            ├── bloc/             # Bloc + Event + State (parts), Cubits
            ├── pages/            # StatefulWidget pages
            └── widgets/          # Feature-specific widgets
```

---

## 1. Models

- Pure Dart class — no json_serializable, no freezed
- `factory fromJson(Map<String, dynamic> json)` only (no toJson unless needed)
- Cast explicitly: `json['field'] as Type`
- Nested models call their own `fromJson`

```dart
class XModel {
  final int id;
  final String name;

  XModel({required this.id, required this.name});

  factory XModel.fromJson(Map<String, dynamic> json) {
    return XModel(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
```

---

## 2. Repos

- `static` methods only — no constructor, no instance
- `static final _dio = GetIt.instance<DioService>()`
- `static final _apiEndpoint = GetIt.instance<ApiEndpoints>()`
- Returns the model directly from `response.data`
- No try/catch — exceptions bubble up to Bloc

```dart
class XRepo {
  static final _dio = GetIt.instance<DioService>();
  static final _apiEndpoint = GetIt.instance<ApiEndpoints>();

  static Future<XModel> getX(int id) async {
    final response = await _dio.getRequest(_apiEndpoint.getX(id));
    return XModel.fromJson(response.data);
  }

  static Future<XModel> createX(String name) async {
    final response = await _dio.postRequest(
      _apiEndpoint.createX,
      data: {'name': name},
    );
    return XModel.fromJson(response.data);
  }
}
```

---

## 3. Bloc / Event / State

### File layout
- One file each: `x_bloc.dart`, `x_event.dart`, `x_state.dart`
- Event and State files use `part of 'x_bloc.dart'`

### Event
```dart
part of 'x_bloc.dart';

sealed class XEvent {}

class XFetchRequested extends XEvent {
  final int id;
  XFetchRequested(this.id);
}

class XSubmitRequested extends XEvent {
  final String name;
  XSubmitRequested({required this.name});
}
```

### State
```dart
part of 'x_bloc.dart';

sealed class XState {}

class XInitial extends XState {}
class XLoading extends XState {}

class XSuccess extends XState {
  final XModel model;
  XSuccess(this.model);
}

class XFailure extends XState {
  final ErrorType? errorType;
  final String? message;
  XFailure(this.errorType, this.message);
}
```

### Bloc
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vara_khata/core/exceptions/api_exception.dart';
import 'package:vara_khata/core/utils/enums/error_type.dart';

part 'x_event.dart';
part 'x_state.dart';

class XBloc extends Bloc<XEvent, XState> {
  XBloc() : super(XInitial()) {
    on<XFetchRequested>(_onFetch);
    on<XSubmitRequested>(_onSubmit);
  }

  Future<void> _onFetch(XFetchRequested event, Emitter<XState> emit) async {
    emit(XLoading());
    try {
      final result = await XRepo.getX(event.id);
      emit(XSuccess(result));
    } on ApiException catch (e) {
      emit(XFailure(e.type, e.message));
    }
  }

  Future<void> _onSubmit(XSubmitRequested event, Emitter<XState> emit) async {
    emit(XLoading());
    try {
      final result = await XRepo.createX(event.name);
      emit(XSuccess(result));
    } on ApiException catch (e) {
      emit(XFailure(e.type, e.message));
    }
  }
}
```

### Simple Cubit (for toggle/local state)
```dart
class ToggleCubit extends Cubit<bool> {
  ToggleCubit() : super(false);
  void toggle() => emit(!state);
  void reset() => emit(false);
}
```

---

## 4. Pages

- `StatefulWidget` always (even if currently stateless — controllers needed)
- `static Route route() => MaterialPageRoute(builder: (_) => const XPage())`
- `BlocProvider` wraps `BlocConsumer` at top level
- Loading overlay: `Stack` with `Container(color: black.withValues(alpha:0.6), child: Loader())`
- **POST errors** → `InlineErrorWidget` rendered inside form when `state is XFailure`
- **GET errors** → `ErrorStateWidget` rendered in body replacing content
- Form uses `GlobalKey<FormState>` + validate before dispatching event
- Dispose all controllers + cubits in `dispose()`
- Body always wrapped in `GradientBackground` > `SingleChildScrollView` > `Padding(fromLTRB(16,0,16,16))`

```dart
class XPage extends StatefulWidget {
  static Route route() => MaterialPageRoute(builder: (_) => const XPage());
  const XPage({super.key});

  @override
  State<XPage> createState() => _XPageState();
}

class _XPageState extends State<XPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => XBloc(),
      child: BlocConsumer<XBloc, XState>(
        listener: (context, state) {
          if (state is XSuccess) {
            // navigate or show notifier
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              _content(context, state),
              if (state is XLoading)
                Container(
                  color: AppColors.black.withValues(alpha: 0.6),
                  child: const Loader(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _content(BuildContext context, XState state) {
    return Scaffold(
      appBar: AppBar(title: const Text('X'), centerTitle: false),
      body: GradientBackground(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: 'Name',
                    controller: _nameController,
                    isRequired: true,
                    hintText: 'Enter name',
                    prefixIcon: HugeIcons.strokeRoundedUser03,
                  ),
                  if (state is XFailure) InlineErrorWidget(state.message),
                  const SizedBox(height: 24),
                  SpringButton(
                    width: double.infinity,
                    onPressed: () => _onSubmit(context),
                    child: const Text('SUBMIT'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onSubmit(BuildContext context) {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<XBloc>().add(XSubmitRequested(name: _nameController.text.trim()));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
```

---

## 5. GET / Fetch Pages (List / Detail)

For pages that fetch data on load, dispatch event in `create:`:

```dart
BlocProvider(
  create: (_) => XBloc()..add(XFetchRequested(id)),
  child: BlocBuilder<XBloc, XState>(
    builder: (context, state) {
      if (state is XLoading) return const Loader();
      if (state is XFailure) return ErrorStateWidget(
        errorType: state.errorType,
        message: state.message,
        onRetry: () => context.read<XBloc>().add(XFetchRequested(id)),
      );
      if (state is XSuccess) return _buildContent(state.model);
      return const SizedBox.shrink();
    },
  ),
)
```

Empty list case:
```dart
if (items.isEmpty) return const EmptyStateWidget();
```

---

## 6. Error Handling Rules

| Scenario | Widget |
|----------|--------|
| POST/form submit failure | `InlineErrorWidget(state.message)` — inside form, below last field |
| GET/fetch failure | `ErrorStateWidget(errorType: state.errorType, message: state.message, onRetry: ...)` — replaces body content |
| Empty list/no data | `EmptyStateWidget(title: '...', message: '...')` |
| Success feedback | `AppNotifier.showAwesomeSnackBar(context, title, message, type: MessageType.success)` |

---

## 7. Widgets

### CustomTextField
```dart
CustomTextField(
  label: 'Field Name',
  controller: _controller,
  isRequired: true,
  hintText: 'Enter ...',
  prefixIcon: HugeIcons.strokeRounded...,
  keyboardType: TextInputType.text,
  validationLabel: 'Field Name',  // optional, defaults to label
)
```

- `obscureText: true` for passwords
- `readOnly: true` + `onTap:` for picker fields
- `suffixText:` for unit labels (e.g. '৳')
- Custom `validator:` overrides default required check

### InlineErrorWidget
```dart
if (state is XFailure) InlineErrorWidget(state.message),
```
- Shows red container with alert icon + message
- Renders nothing if message is null/empty

### ErrorStateWidget
```dart
ErrorStateWidget(
  errorType: state.errorType,
  message: state.message,        // optional override
  onRetry: () => ...,            // shows Retry button
)
```

### EmptyStateWidget
```dart
EmptyStateWidget(
  title: 'No items',
  message: 'Description...',
  icon: Image.asset(Assets.noContent, height: 90),  // optional
  isCenter: true,  // default
)
```

### AppConfirmationDialog
```dart
AppConfirmationDialog.show(
  context,
  title: 'Delete Item',
  message: 'Are you sure?',
  confirmText: 'Delete',
  isDestructive: true,
  onConfirm: () => ...,
);
```

### AppNotifier
```dart
AppNotifier.showAwesomeSnackBar(context, 'Success', 'Item saved', type: MessageType.success);
AppNotifier.showSnackBar(context, 'Message', type: MessageType.error);
```

---

## 8. Theme & Colors

Always use `AppColors.*` — never hardcode hex values.

Key tokens:
- `AppColors.primary` — Navy Blue `#1E3A5F`
- `AppColors.primaryDark` — Deep Navy `#132640` (button shadows/borders)
- `AppColors.background` — `#F8FAFC`
- `AppColors.card` — `#FFFFFF`
- `AppColors.textPrimary` — `#1F2937`
- `AppColors.textSecondary` — `#6B7280`
- `AppColors.error` — `#E8192C`
- `AppColors.success` — `#10B981`
- `AppColors.inputBorder` — `#E2E8F0`

---

## 9. Typography

Always `GoogleFonts.poppins(textStyle: TextStyle(...))`.

Common patterns:
```dart
// Heading
GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)

// Body / Label
GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)

// Secondary / Hint
GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary)

// Small
GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight)
```

---

## 10. Icons

Always `HugeIcons.strokeRounded*` from `hugeicons` package.

```dart
HugeIcon(icon: HugeIcons.strokeRoundedUser03, color: AppColors.textSecondary, size: 20)
```

In `CustomTextField`, pass icon as `prefixIcon:` or `suffixIcon:`.

---

## 11. Navigation

```dart
// Push
Navigator.push(context, XPage.route());

// Replace
Navigator.pushReplacement(context, XPage.route());

// Clear stack
Navigator.pushAndRemoveUntil(context, XPage.route(), (_) => false);
```

Every page has `static Route route()`.

---

## 12. Network (DioService)

Injected via GetIt. Repo calls only — never call DioService directly from Bloc.

Methods: `getRequest`, `postRequest`, `putRequest`, `patchRequest`, `deleteRequest`, `postMultipart`, `putMultipart`.

Error throws `ApiException` with `type: ErrorType` and `message: String`.

---

## 13. Spacing & Layout Conventions

- Screen padding: `EdgeInsets.fromLTRB(16, 0, 16, 16)`
- Between fields: `SizedBox(height: 16)`
- Section gaps: `SizedBox(height: 24)` or `32`
- Card/container border radius: `12` (items), `16` (cards/logos), `24` (dialogs)
- Button border radius: `32` (pill shape)
- Input border radius: `12`
- Logo container: `100×100`, `borderRadius: 16`, bottom border `4px primaryDark`

---

## 14. Splash / Session Check Pattern

```dart
Future<void> _checkSession() async {
  await Future.delayed(const Duration(milliseconds: 1500));
  final token = await AppPreferences.getAccessToken();
  final rememberMe = await AppPreferences.isRememberMe();
  if (!mounted) return;
  if (token.isNotEmpty && rememberMe) {
    Navigator.pushReplacement(context, DashboardPage.route());
  } else {
    Navigator.pushReplacement(context, LoginPage.route());
  }
}
```

Loading indicator: `CupertinoActivityIndicator(radius: 16, color: AppColors.textPrimary)`.

---

## Quick Checklist

Before generating any code, confirm:
- [ ] Model: pure Dart, `fromJson`, explicit casts
- [ ] Repo: static methods, GetIt DioService, no try/catch
- [ ] Bloc: `sealed` event/state, `on ApiException catch`, emit `XFailure(e.type, e.message)`
- [ ] Page: StatefulWidget, BlocProvider+BlocConsumer, Stack loading overlay
- [ ] POST error: `InlineErrorWidget` inside form
- [ ] GET error: `ErrorStateWidget` replaces content
- [ ] Empty: `EmptyStateWidget`
- [ ] Colors: AppColors only
- [ ] Fonts: GoogleFonts.poppins only
- [ ] Icons: HugeIcons.strokeRounded only
- [ ] Navigation: `static Route route()` on every page
