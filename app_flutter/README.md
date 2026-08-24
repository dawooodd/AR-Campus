# 🛒 Tokokita - Flutter Application 

Tokokita adalah aplikasi mobile berbasis **Flutter** yang dirancang untuk manajemen data produk pada sebuah toko. Aplikasi ini mengimplementasikan arsitektur **BLoC (Business Logic Component)** sebagai state management dan terintegrasi dengan backend layanan RESTful API untuk memproses data secara real-time.

## ✨ Fitur Utama


- **Autentikasi & Keamanan:**
  - **Registrasi Akun:** Pendaftaran pengguna baru.
  - **Login / Masuk:** Autentikasi akun pengguna untuk masuk ke sistem.
  - **Manajemen Sesi:** Menyimpan token sesi secara lokal agar pengguna tidak perlu login kembali saat membuka ulang aplikasi.
- **Manajemen Produk (CRUD Lengkap):**
  - **Daftar Produk:** Menampilkan katalog seluruh produk yang tersedia di toko.
  - **Detail Produk:** Melihat deskripsi, harga, dan kode produk secara rinci.
  - **Tambah Produk:** Menambahkan item produk baru ke dalam database toko.
  - **Ubah Produk:** Mengedit informasi data produk yang sudah ada.
  - **Hapus Produk:** Menghapus data produk dari sistem.

## 💻 Teknologi & Package yang Digunakan

Aplikasi ini dibangun menggunakan ekosistem Dart & Flutter modern dengan dependensi berikut:
- **Framework:** Flutter (Dart SDK `^3.5.2`)
- **State Management:** BLoC (Business Logic Component) Pattern
- **Networking:** `http: ^0.13.4` (Untuk melakukan HTTP request ke REST API)
- **Local Storage:** `shared_preferences: ^2.0.11` (Untuk menyimpan data sesi/token lokal)
- **UI Icons:** `cupertino_icons: ^1.0.2` (Desain ikon iOS-style tambahan)

## 📂 Struktur Direktori Kerja (`lib/`)

Logika bisnis dan antarmuka aplikasi dipisahkan secara modular untuk mempermudah pemeliharaan kode:

```text
lib/
├── bloc/                  # Komponen logika bisnis aplikasi (State Management)
│   ├── login_bloc.dart
│   ├── logout_bloc.dart
│   ├── produk_bloc.dart
│   └── registrasi_bloc.dart
├── helpers/               # Utilitas pembantu dan konfigurasi global
│   ├── api.dart           # Interseptor dan konfigurasi HTTP client
│   ├── api_url.dart       # Endpoint URL REST API backend
│   ├── app_exception.dart # Manajemen penanganan error/exception jaringan
│   └── user_info.dart     # Manajemen shared preferences (Sesi User)
├── model/                 # Cetak biru data (Data Modeling)
│   ├── login.dart
│   ├── produk.dart
│   └── registrasi.dart
├── ui/                    # Komponen visual / Antarmuka Pengguna (Views)
│   ├── login_page.dart
│   ├── produk_detail.dart
│   ├── produk_form.dart
│   ├── produk_page.dart
│   └── registrasi_page.dart
├── widget/                # Komponen UI modular yang dapat digunakan kembali
│   ├── success_dialog.dart
│   └── warning_dialog.dart
└── main.dart              # Titik masuk utama (Entry point) aplikasi Flutter

```

## 🌐 Konfigurasi REST API Backend

Seluruh endpoint API dikonfigurasi secara terpusat pada file `lib/helpers/api_url.dart`. Secara default, URL diatur menuju ke IP localhost milik Android Emulator:

```dart
class ApiUrl {
  static const String baseUrl = '[http://10.0.2.2/toko-api/public](http://10.0.2.2/toko-api/public)';

  static const String registrasi = '$baseUrl/registrasi';
  static const String login = '$baseUrl/login';
  static const String listProduk = '$baseUrl/produk';
  static const String createProduk = '$baseUrl/produk';

  static String updateProduk(int id) { return '$baseUrl/produk/$id/update'; }
  static String showProduk(int id) { return '$baseUrl/produk/$id'; }
  static String deleteProduk(int id) { return '$baseUrl/produk/$id'; }
}

```

> ⚠️ **PENTING (Catatan Emulator & Real Device):**
> * Alamat IP `10.0.2.2` digunakan khusus untuk **Android Emulator** agar dapat mengakses localhost komputer host.
> * Jika Anda menggunakan **iOS Simulator**, ubahlah alamat tersebut menjadi `http://localhost/toko-api/public`.
> * Jika Anda melakukan *debugging* langsung ke **Perangkat Fisik (Real Device)**, pastikan HP dan laptop berada dalam satu jaringan Wi-Fi yang sama, lalu ganti IP tersebut dengan alamat IPv4 komputer host Anda (contoh: `http://192.168.1.x/...`).
> 
> 

## 🚀 Panduan Menjalankan Aplikasi

Pastikan Anda telah memasang [Flutter SDK](https://docs.flutter.dev/get-started/install) dengan benar di lingkungan Anda.

1. **Unduh atau Clone Repository**
```bash
git clone <url-repository-tokokita>
cd tokokita

```


2. **Dapatkan Semua Dependensi Package**
Jalankan perintah ini di direktori akar proyek untuk mengunduh package yang tercantum di `pubspec.yaml`:
```bash
flutter pub get

```


3. **Periksa Perangkat Terhubung**
Pastikan emulator Anda menyala atau perangkat fisik sudah terhubung dengan fitur USB Debugging aktif:
```bash
flutter devices

```


4. **Jalankan Aplikasi**
Kompilasi dan jalankan aplikasi ke perangkat target:
```bash
flutter run

```



---

*Dikembangkan menggunakan Flutter dengan pola arsitektur BLoC.*

```

```
