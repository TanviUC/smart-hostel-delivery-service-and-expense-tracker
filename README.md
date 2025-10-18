# 🏨 Smart Hostel Delivery Service & Expense Tracker

[![Flutter](https://img.shields.io/badge/Flutter-3.13.0-blue)](https://flutter.dev/)
[![Laravel](https://img.shields.io/badge/Laravel-10-red)](https://laravel.com/)
[![MySQL](https://img.shields.io/badge/MySQL-8.0-blue)](https://www.mysql.com/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

A **hybrid web & mobile application** that streamlines **hostel delivery coordination** and **daily expense tracking** for students. It integrates **Flutter**, **Laravel**, **MySQL**, and **Razorpay API** to automate campus deliveries, secure payments, and provide transparent tracking between **students**, **delivery agents**, and **administrators**.

---

## 📑 Table of Contents

1. [Features](#-features)
2. [Tech Stack](#-tech-stack)
3. [System Architecture](#-system-architecture)
4. [Installation Guide](#-installation-guide)
5. [Results](#-results)
6. [Future Enhancements](#-future-enhancements)
7. [References](#-references)
8. [Author](#-author)
9. [License](#-license)

---

## 🚀 Features

### 🧑‍🎓 Student Module

* Raise **gate-to-hostel delivery requests**
* **Track deliveries** in real time
* **Log daily expenses** (voice or manual entry)
* Make **secure online payments** via Razorpay
* Receive **email notifications** on delivery status

### 🚴 Agent Module

* Accept or manage assigned deliveries
* Update delivery status in real time
* View assigned requests and completion logs

### 🧑‍💼 Admin Module

* Manage delivery requests and **reassign agents**
* Monitor **agent performance**
* View **payment logs** & **expense summaries**
* Access **real-time analytics dashboard**

---

## 🧩 Tech Stack

**Frontend (Mobile):** Flutter (Dart) – Cross-platform student & agent app
**Backend:** Laravel (PHP) – RESTful APIs & business logic
**Database:** MySQL – Relational data storage
**Payment Gateway:** Razorpay API – UPI, cards, net banking integration
**Notifications:** Gmail SMTP – Automated email alerts
**Version Control:** Git & GitHub – Repository management

---

## ⚙️ System Architecture

```
Flutter App → Laravel Backend → MySQL Database
       ↘ Razorpay API → Gmail SMTP → Admin Dashboard
```

**Core Modules:**

* Authentication (Student, Agent, Admin)
* Delivery Management
* Expense Tracker
* Razorpay Payment Integration
* Email Notifications

---

## 💻 Installation Guide

### 1️⃣ Clone Repository

```bash
git clone https://github.com/TanviUC/smart-hostel-delivery-service-and-expense-tracker.git
cd smart-hostel-delivery-service-and-expense-tracker
```

### 2️⃣ Backend Setup (Laravel)

```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate
php artisan serve
```

**Update `.env` with your credentials:**

```env
DB_DATABASE=smart_hostel
DB_USERNAME=root
DB_PASSWORD=
RAZORPAY_KEY=your_key_here
RAZORPAY_SECRET=your_secret_here
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your_email@gmail.com
MAIL_PASSWORD=your_app_password
MAIL_ENCRYPTION=tls
```

### 3️⃣ Mobile App Setup (Flutter)

```bash
cd flutter_app
flutter pub get
flutter run
```

---

## 📊 Results

* ✅ Reduced delivery delays by 50%
* ✅ Improved real-time transparency in hostel logistics
* ✅ Automated notifications for students and agents
* ✅ Centralized expense tracking and analytics

---

## 🌱 Future Enhancements

* 📢 Push notifications & in-app alerts for students and agents
* 🧠 AI-based delivery optimization for faster assignments
* 🎙️ Multilingual voice-enabled expense logging
* 📈 Smart budget analytics with visual graphs
* 🧩 Integration with Hostel Warden Systems for better coordination
* 🏅 Gamification and reward system for timely deliveries
* 📊 Advanced reporting & dashboard enhancements
* 🔒 Enhanced security features and role-based access control

---

## 🧾 References

* [Laravel Documentation](https://laravel.com/docs)
* [Flutter Documentation](https://docs.flutter.dev)
* [Razorpay API Docs](https://razorpay.com/docs)
* [MySQL Reference Manual](https://dev.mysql.com/doc)
* [Render Deployment Docs](https://render.com/docs)

---

## 👩‍💻 Author

**Tanvi Ashok Kadge**
B.Sc. Computer Science – SIES College of Arts, Science & Commerce
Project Guide: *Mrs. Maya Nair*

---

## 📜 License

This project is open-sourced under the **MIT License**.
Feel free to fork, modify, and contribute!
