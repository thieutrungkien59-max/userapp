# Project Status - LogiRoute Customer App

Last reviewed: 2026-08-04

## Purpose and scope

This repository contains the customer-facing Flutter application for **LogiRoute**, a delivery and order-management service. It targets Android, iOS, web, Windows, Linux, and macOS from one Flutter codebase. The active implementation is in `lib/features/**/presentation`, `lib/features/**/data`, `lib/core`, `lib/shared`, and `lib/theme`.

This file is the project status record. Update its **Last reviewed**, completed functionality, limitations, and verification notes whenever future work changes the application.

## Current architecture

- Flutter / Dart SDK constraint: Dart `^3.11.5`.
- Navigation: `go_router` with routes composed in `lib/features/customer/presentation/customer_app.dart`.
- App state: global `ValueNotifier<AppState>` plus `SharedPreferences` session persistence.
- HTTP: shared JSON `ApiClient`, configured by `API_BASE_URL` and defaulting to a public ngrok URL.
- UI: Material Design, Google Fonts (`Be Vietnam Pro`, `Space Grotesk`, `IBM Plex Mono`), shared controls in `lib/shared/widgets/app_widgets.dart`.
- State package: `flutter_riverpod` is initialized through `ProviderScope`, but no Riverpod providers are currently used.

## Implemented functionality

### Application and navigation

- Restores a saved customer session on launch.
- Opens `/login` when no customer ID is saved; otherwise opens `/home`.
- Provides routes for login, registration, home, create order, confirmation, orders, order status, tracking, proof of delivery, notifications, and profile.
- Provides a four-tab bottom navigation bar: Home, Orders, Notifications, Profile.

### Authentication and customer profile

- Customer registration with name, 10-digit phone number, optional email, password validation, and terms acceptance.
- Customer login using phone number and password.
- Parses several plausible backend response field names for customer/account IDs, including a profile lookup fallback when login/register returns only an account ID.
- Saves customer ID, name, phone, email, and default address locally after login or registration.
- Displays the stored profile and supports updating name, phone, email, and default address through the backend.
- Supports logout and clears the local session.

### Order creation and management

- Creates an order with pickup/delivery addresses, receiver name and phone number, weight, COD amount, and shipping fee.
- Validates required fields, positive weight, non-negative COD/shipping fee, and a 10-digit receiver phone number.
- Shows a post-creation confirmation screen.
- Loads the current customer's orders, with pull-to-refresh on home and order-list screens.
- Shows active/completed order counts and up to three active orders on the home screen.
- Shows an order list with status, delivery address, COD, and shipping fee.
- Shows order detail plus status history when the backend provides it.
- Caches loaded/created orders in memory as a fallback for detail views.

### Delivery evidence and UI foundation

- Provides a proof-of-delivery screen that displays a backend image URL, OTP/signature, and timestamp when supplied.
- Provides shared headers, buttons, inputs, cards, status badges, branding, colors, and navigation widgets.
- Enables Android internet access and cleartext traffic for HTTP development endpoints.

## Backend integration currently expected

The app currently calls the following endpoints. The backend contract must remain compatible with these paths and request fields.

| Area | Endpoint | Method |
| --- | --- | --- |
| Register customer | `/api/Auth/register-khach-hang` | `POST` |
| Login | `/api/Auth/login` | `POST` (`tenDangNhap`, `matKhau`) |
| Get customer profile | `/api/Auth/profile/{accountId}` | `GET` |
| Update customer | `/api/Auth/update-khach-hang/{customerId}` | `PUT` |
| Create order | `/api/DonHang/tao-don-moi` | `POST` |
| List orders | `/api/DonHang/danh-sach-toan-bo` | `GET` |
| Get order detail | `/api/DonHang/chi-tiet/{orderId}` | `GET` |

`API_BASE_URL` can be overridden without source changes:

```powershell
flutter run --dart-define=API_BASE_URL=http://<host>:5262
```

## Incomplete, placeholder, or unverified areas

- **Live tracking:** the tracking route exists, but only states that the backend has no shipper-location endpoint. `flutter_map` and `latlong2` are dependencies but are not used by the active app.
- **Notifications:** the screen is a placeholder because no notification API is integrated.
- **Order proof access:** a proof route exists, but the current order cards/detail view do not expose navigation to tracking or proof screens.
- **Order status classification:** the home screen identifies completed orders by matching the literal Vietnamese phrase `hoan tat` after lowercasing; it should be aligned with actual backend status codes such as `HOAN_THANH` if those are returned.
- **Authentication protection:** routing chooses the initial screen from persisted session state, but there is no route redirect guard preventing manual navigation to authenticated pages after logout.
- **API security/session:** `ApiClient` can attach an access token, but authentication responses do not currently extract/store a token or call `setAccessToken`.
- **Error handling:** network timeouts are set to 15 seconds; user-facing server errors are shown, but there is no offline state, retry policy, or structured error mapping.
- **Tests:** no application unit, widget, integration, or API-contract tests are present.
- **Build verification:** source-level inspection is complete. `flutter analyze` was started during this review but did not finish within 120 seconds, so static analysis and target-platform builds remain unverified.

## Legacy or unused files

The following files are empty legacy placeholders and are not imported by the active implementation:

- `lib/core/constans/app_colors.dart` (note the misspelled directory name)
- `lib/core/routes/app_routes.dart`
- `lib/core/utils/format_utils.dart`
- `lib/features/auth/screens/login_screen.dart`
- `lib/features/auth/screens/register_screen.dart`
- `lib/features/create_order/screens/step1_sender.dart.dart`
- `lib/features/create_order/screens/step2_sender.dart.dart`
- `lib/features/create_order/screens/step3_sender.dart.dart`
- `lib/features/history/screens/order_history_screen.dart.dart`
- `lib/features/home/screens/home_screen.dart`
- `lib/features/tracking/screens/live_tracking_screen.dart.dart`
- `lib/models/don_hang_model.dart`
- `lib/models/khach_hang_model.dart.dart`
- `lib/services/api_service.dart`
- `lib/services/tracking_service.dart.dart`

`README.md` also documents an earlier project structure and Firebase/Google Maps plans; it does not match the active source layout or dependencies.

## Maintenance rule

For every future change in this repository, update this document in the same change set when it affects:

- implemented user functionality or route availability;
- backend endpoints, request/response contract, or configuration;
- known limitations, placeholders, security concerns, or technical debt;
- dependencies, platforms, architecture, or test/build verification.
