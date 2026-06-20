# Product Requirement Document (PRD)

# My Barbershop

**Versi:** 1.0
**Platform:** Mobile App (Pelanggan & Barber) + Web Admin/Desktop
**Backend:** Firebase Ecosystem
**Arsitektur:** Clean Architecture + Clean Code Principles

---

# 1. Project Overview & Objectives

## 1.1 Latar Belakang

My Barbershop adalah aplikasi reservasi layanan barbershop yang memungkinkan pelanggan melakukan booking secara online tanpa harus datang langsung ke lokasi untuk antre.

Masalah utama yang ingin diselesaikan:

* Antrean pelanggan yang tidak teratur.
* Reservasi fiktif yang menyebabkan slot barber kosong.
* Sulitnya admin mengatur jadwal barber.
* Tidak adanya sistem notifikasi otomatis.
* Sulitnya monitoring transaksi dan histori layanan.

Untuk mengatasi hal tersebut, sistem menerapkan **reservasi online dengan pembayaran DP (Down Payment)** sebagai bentuk komitmen pelanggan terhadap jadwal yang dipilih.

---

## 1.2 Tujuan Bisnis

### Tujuan Utama

* Meningkatkan efisiensi operasional barbershop.
* Mengurangi reservasi palsu (fake booking).
* Meningkatkan pengalaman pelanggan.
* Mempermudah pengelolaan jadwal barber.
* Menyediakan laporan transaksi yang terpusat.

### Key Success Metrics (KPI)

| KPI                     | Target    |
| ----------------------- | --------- |
| Booking berhasil        | > 90%     |
| Fake Reservation        | < 5%      |
| Waktu respon aplikasi   | < 3 detik |
| Keberhasilan notifikasi | > 95%     |
| Uptime sistem           | 99.9%     |

---

# 2. User Persona & Roles Matrix

---

## 2.1 Persona Pelanggan

### Nama

Andi (22 Tahun)

### Kebutuhan

* Booking cepat lewat HP
* Tidak perlu antre
* Bisa memilih barber favorit
* Mendapat pengingat jadwal

### Pain Point

* Harus datang dulu untuk antre
* Tidak tahu barber tersedia atau tidak

---

## 2.2 Persona Barber

### Nama

Budi (28 Tahun)

### Kebutuhan

* Melihat jadwal pelanggan
* Mengatur jam kerja
* Mengetahui detail layanan yang dipilih pelanggan

---

## 2.3 Persona Admin

### Nama

Rina (32 Tahun)

### Kebutuhan

* Mengelola seluruh data
* Melihat transaksi
* Memvalidasi DP
* Mengatur jadwal barber

---

# Roles Matrix

| Fitur               | Pelanggan | Barber | Admin |
| ------------------- | --------- | ------ | ----- |
| Registrasi          | ✅         | ❌      | ❌     |
| Login               | ✅         | ✅      | ✅     |
| Lihat layanan       | ✅         | ✅      | ✅     |
| CRUD layanan        | ❌         | ❌      | ✅     |
| Lihat jadwal barber | ✅         | ✅      | ✅     |
| Atur jadwal barber  | ❌         | ✅      | ✅     |
| Reservasi           | ✅         | ❌      | ❌     |
| Upload bukti DP     | ✅         | ❌      | ❌     |
| Konfirmasi DP       | ❌         | ❌      | ✅     |
| Ubah status layanan | ❌         | ✅      | ✅     |
| Notifikasi          | ✅         | ✅      | ✅     |
| Kelola User         | ❌         | ❌      | ✅     |
| Laporan transaksi   | ❌         | ❌      | ✅     |

---

# 3. Functional Requirements (FR)

---

# FR-01 Authentication & Authorization

---

### User Story

Sebagai pelanggan, saya ingin membuat akun sehingga saya dapat menggunakan layanan reservasi.

### Acceptance Criteria

* Registrasi menggunakan:

  * Nama
  * Email
  * Nomor HP
  * Password
* Verifikasi email.
* Login menggunakan email dan password.
* Logout.
* Reset password.

### Firebase

* Firebase Authentication

---

# FR-02 Profile Management

---

### User Story

Sebagai pengguna, saya ingin mengelola profil sehingga data saya selalu terbaru.

### Acceptance Criteria

* Edit nama.
* Edit nomor HP.
* Upload foto profil.
* Ganti password.

### Firebase

* Firestore
* Cloud Storage

---

# FR-03 Service Management

---

### User Story

Sebagai admin, saya ingin mengelola layanan sehingga daftar layanan selalu akurat.

### Acceptance Criteria

Admin dapat:

* Menambah layanan
* Mengubah layanan
* Menghapus layanan
* Mengaktifkan/nonaktifkan layanan

Data layanan:

* Nama layanan
* Deskripsi
* Harga
* Durasi
* Foto layanan

---

# FR-04 Barber Management

---

### User Story

Sebagai admin, saya ingin mengelola barber sehingga barber aktif dapat melayani pelanggan.

### Acceptance Criteria

Admin dapat:

* Tambah barber
* Edit barber
* Nonaktifkan barber
* Lihat performa barber

Data:

* Nama
* Foto
* Status aktif
* Jam kerja

---

# FR-05 Schedule Management

---

### User Story

Sebagai barber, saya ingin mengatur jadwal kerja sehingga pelanggan hanya dapat memesan pada slot yang tersedia.

### Acceptance Criteria

Barber dapat:

* Menentukan hari kerja
* Menentukan jam kerja
* Menentukan slot libur

Admin dapat override jadwal.

---

# FR-06 Reservation Management

---

### User Story

Sebagai pelanggan, saya ingin melakukan reservasi sehingga saya mendapat jadwal layanan tanpa harus antre.

### Flow

1. Pilih layanan.
2. Pilih barber.
3. Pilih tanggal.
4. Pilih jam.
5. Sistem cek slot tersedia.
6. Reservasi dibuat.
7. Menunggu pembayaran DP.

### Status Reservasi

* Pending Payment
* Waiting Confirmation
* Confirmed
* In Progress
* Completed
* Cancelled
* Rejected

---

# FR-07 Down Payment (DP)

---

### User Story

Sebagai pelanggan, saya ingin membayar DP sehingga reservasi saya dikonfirmasi.

### Acceptance Criteria

* Upload bukti transfer.
* Sistem menyimpan bukti pembayaran.
* Admin melakukan verifikasi.

### Status Pembayaran

* Pending
* Verified
* Rejected

---

# FR-08 Reservation Cancellation

---

### User Story

Sebagai pelanggan, saya ingin membatalkan reservasi sehingga slot dapat digunakan orang lain.

### Rules

* Boleh dibatalkan maksimal H-1.
* Setelah lewat batas waktu tidak bisa dibatalkan.
* Slot otomatis dibuka kembali.

---

# FR-09 Barber Work Progress

---

### User Story

Sebagai barber, saya ingin mengubah status layanan sehingga pelanggan mengetahui progres layanan.

### Status

* Waiting Customer
* In Progress
* Completed

---

# FR-10 Notification System

---

### User Story

Sebagai pengguna, saya ingin menerima notifikasi sehingga tidak melewatkan informasi penting.

### Trigger

#### Pelanggan

* Reservasi berhasil
* DP diterima
* DP ditolak
* Pengingat H-1
* Layanan selesai

#### Barber

* Ada reservasi baru
* Jadwal berubah

#### Admin

* Bukti DP baru

### Firebase

* Firebase Cloud Messaging

---

# FR-11 Reports & Dashboard

---

### User Story

Sebagai admin, saya ingin melihat laporan sehingga dapat memantau bisnis.

### Dashboard

Menampilkan:

* Total pelanggan
* Total barber
* Reservasi hari ini
* Pendapatan
* Reservasi selesai

### Filter

* Harian
* Mingguan
* Bulanan
* Tahunan

---

# 4. Non Functional Requirements (NFR)

---

## NFR-01 Performance

### Target

* Response Time < 3 detik
* Query Firestore < 1 detik
* Sinkronisasi real-time

### Implementasi

* Firestore indexing
* Pagination
* Lazy loading

---

## NFR-02 Security

### Authentication

* Firebase Authentication

### Authorization

Role Based Access Control (RBAC)

Role:

* Admin
* Barber
* Customer

### Data Security

* HTTPS only
* Firestore Security Rules
* Password tidak disimpan manual

### Storage Security

* Bukti transfer hanya dapat diakses:

  * Admin
  * Pemilik reservasi

---

## NFR-03 Reliability

### Target

* Uptime 99.9%
* Backup otomatis Firebase

### Error Handling

* Global exception handling
* Retry mechanism

---

## NFR-04 Scalability

Sistem harus mampu menangani:

* 10.000+ pengguna
* 50.000+ reservasi
* 100+ barber

Tanpa perubahan arsitektur besar.

---

## NFR-05 Usability

### Mobile

Responsive:

* Android
* iOS

### Admin Panel

Responsive:

* Desktop
* Laptop
* Tablet

---

# 5. Firebase Database Schema & Structure Proposal

## Collection: users

```json
users
 └── userId
      {
        "name": "Danial",
        "email": "danial@gmail.com",
        "phone": "08123456789",
        "photoUrl": "",
        "role": "customer",
        "status": "active",
        "createdAt": Timestamp
      }
```

---

## Collection: services

```json
services
 └── serviceId
      {
        "name": "Haircut Premium",
        "description": "Potong rambut + styling",
        "price": 50000,
        "duration": 60,
        "imageUrl": "",
        "isActive": true,
        "createdAt": Timestamp
      }
```

---

## Collection: barbers

```json
barbers
 └── barberId
      {
        "userId": "uid",
        "specialization": "Fade Cut",
        "experience": 5,
        "rating": 4.8,
        "isAvailable": true
      }
```

---

## Collection: schedules

```json
schedules
 └── scheduleId
      {
        "barberId": "barber001",
        "date": "2026-06-15",
        "startTime": "09:00",
        "endTime": "17:00",
        "status": "available"
      }
```

---

## Collection: reservations

```json
reservations
 └── reservationId
      {
        "customerId": "uid",
        "barberId": "barber001",
        "serviceId": "service001",
        "scheduleId": "schedule001",
        "bookingDate": Timestamp,
        "reservationDate": Timestamp,
        "status": "confirmed",
        "totalPrice": 50000,
        "dpAmount": 20000
      }
```

---

## Collection: payments

```json
payments
 └── paymentId
      {
        "reservationId": "reserve001",
        "customerId": "uid",
        "amount": 20000,
        "paymentProofUrl": "",
        "status": "pending",
        "verifiedBy": "adminId",
        "verifiedAt": Timestamp
      }
```

---

## Collection: notifications

```json
notifications
 └── notificationId
      {
        "userId": "uid",
        "title": "Reservasi Diterima",
        "message": "Reservasi Anda berhasil",
        "isRead": false,
        "createdAt": Timestamp
      }
```

---

# 6. Clean Code & Architecture Guidelines

## Arsitektur

Gunakan Clean Architecture:

```text
Presentation Layer
        ↓
Domain Layer
        ↓
Data Layer
```

Dependency hanya boleh mengarah ke dalam.

---

# Struktur Folder

```text
lib/
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── services/
│   ├── utils/
│
├── features/
│
│   ├── auth/
│   │
│   ├── profile/
│   │
│   ├── services/
│   │
│   ├── barber/
│   │
│   ├── schedule/
│   │
│   ├── reservation/
│   │
│   ├── payment/
│   │
│   ├── notification/
│
│   └── dashboard/
│
└── shared/
```

---

## Struktur Tiap Feature

```text
reservation/

├── data/
│   ├── datasource/
│   ├── models/
│   ├── repositories/
│
├── domain/
│   ├── entities/
│   ├── repositories/
│   ├── usecases/
│
├── presentation/
│   ├── pages/
│   ├── widgets/
│   ├── controllers/
│
└── dependency_injection/
```

---

# Layer Responsibility

## Presentation Layer

Tugas:

* UI
* State Management
* Form Validation

Contoh:

```dart
ReservationPage
ReservationController
ReservationState
```

---

## Domain Layer

Tugas:

* Business Rules
* Use Cases
* Entities

Contoh:

```dart
CreateReservationUseCase
CancelReservationUseCase
VerifyPaymentUseCase
```

---

## Data Layer

Tugas:

* Firebase API
* Firestore Query
* DTO Mapping

Contoh:

```dart
ReservationRepositoryImpl
ReservationRemoteDataSource
ReservationModel
```

---

# Naming Convention

### Class

```dart
ReservationRepository
CreateReservationUseCase
ReservationController
```

### Method

```dart
createReservation()
cancelReservation()
verifyPayment()
```

### Boolean

```dart
isActive
isVerified
isAvailable
```

---

# Firestore Security Rules (Rekomendasi)

```javascript
match /users/{userId} {
  allow read, write: if request.auth.uid == userId;
}

match /reservations/{reservationId} {
  allow read: if request.auth != null;

  allow create:
    if request.auth != null;

  allow update:
    if request.auth.token.role == "admin";
}

match /payments/{paymentId} {
  allow read, write:
    if request.auth != null;
}
```

---

# Kesimpulan

My Barbershop dirancang sebagai sistem reservasi barbershop modern berbasis Firebase dengan tiga aktor utama (Pelanggan, Barber, dan Admin). Arsitektur yang digunakan mengutamakan:

* Clean Architecture
* Clean Code
* Real-Time Firebase
* Role-Based Access Control (RBAC)
* Reservasi dengan DP untuk mencegah booking fiktif
* Notifikasi real-time menggunakan FCM
* Skalabilitas hingga puluhan ribu pengguna

Dokumen PRD ini sudah cukup detail untuk dijadikan acuan desain UI/UX, pembuatan ERD, LRS, Use Case Diagram, Activity Diagram, Sequence Diagram, Class Diagram, hingga implementasi coding oleh tim developer.
