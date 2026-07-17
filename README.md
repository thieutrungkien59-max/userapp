```text
lib/
│
├── main.dart                   # File chạy chính của App. (Khởi tạo Firebase, routes).
│
├── core/                       # CẤU HÌNH DÙNG CHUNG (UI & UTILS)
│   ├── constants/app_colors.dart 
│   ├── utils/format_utils.dart   
│   └── routes/app_routes.dart  # Chứa code chuyển trang.
│
├── models/                     # CLASS DỮ LIỆU (Giống với Database SQL)
│   ├── khach_hang_model.dart   
│   └── don_hang_model.dart     
│
├── services/                   # NƠI GỌI API & FIREBASE (Tuyệt đối KHÔNG chứa UI)
│   ├── api_service.dart        # Chứa hàm gọi C# Backend (Tạo đơn, tính giá).
│   └── tracking_service.dart   # Chứa hàm lắng nghe Firebase để lấy tọa độ Shipper.
│
└── features/                   # NƠI VẼ GIAO DIỆN (UI SCREENS)
    │
    ├── auth/                   # Tính năng Đăng nhập & Đăng ký
    │   ├── screens/login_screen.dart
    │   └── screens/register_screen.dart
    │
    ├── home/                   # Màn hình chính
    │   └── screens/user_home_screen.dart
    │
    ├── create_order/           # Tính năng Tạo Đơn Hàng (Biểu mẫu BM01)
    │   ├── screens/step1_sender.dart     # Form thông tin người gửi
    │   ├── screens/step2_receiver.dart   # Form người nhận & nhập tiền COD
    │   └── screens/step3_confirm.dart    # Xác nhận & Hiển thị cước phí
    │
    ├── tracking/               # Tính năng Bản đồ theo dõi đơn
    │   └── screens/live_tracking_screen.dart # Nhúng Google Maps, hiện xe máy chạy.
    │
    └── history/                # Lịch sử đơn hàng
        └── screens/order_history_screen.dart