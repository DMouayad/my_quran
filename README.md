#  My Quran | قرآني

<div align="center">

  <!-- LOGO -->
  <img src="fastlane/metadata/android/en-US/images/icon.png" alt="Logo" width="120" height="120" style="border-radius: 24px">

  <br><br>

  <!-- BADGES -->
  ![Flutter](https://img.shields.io/badge/Built%20with-Flutter-02569B?style=flat-square&logo=flutter)
  ![License](https://img.shields.io/github/license/dmouayad/my_quran?style=flat-square&color=blue)
  ![Version](https://img.shields.io/github/v/release/dmouayad/my_quran?style=flat-square&color=0F766E&label=Latest%20Version)

  <br>

  **A distraction-free, privacy-focused, and high-performance Quran application.**
  
  **تطبيق قرآن كريم خفيف، مفتوح المصدر، يركز على سهولة الاستخدام والأداء العالي.**

  <br>

  <!-- DOWNLOAD BUTTONS -->
  <a href="https://github.com/dmouayad/my_quran/releases/latest">
    <img src="https://img.shields.io/badge/Download-APK-0F766E?style=for-the-badge&logo=android&logoColor=white" height="50">
  </a>
  &nbsp;
  <a href="https://f-droid.org/packages/com.dmouayad.my_quran/">
    <img src="https://img.shields.io/badge/Get%20it%20on-F--Droid-3498DB?style=for-the-badge&logo=f-droid&logoColor=white" height="50">
  </a>

</div>

---

## 📱 Screenshots / لقطات الشاشة

<div align="center">
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/home-light.png" width="200" />
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/search.png" width="200" />
  <img src="fastlane/metadata/android/en-US/images/phoneScreenshots/navigation.png" width="200" />
</div>

---

## ✨ Features | المميزات

| English | العربية |
| :--- | :--- |
| **🚀 Ultra Lightweight**<br> optimized size (~13MB) using JSON assets and code splitting. | **🚀 خفيف جداً**<br> حجم صغير بفضل تقنيات ضغط البيانات، لا يستهلك مساحة الهاتف. |
| **📴 100% Offline**<br> No internet required. No tracking. No analytics. | **📴 يعمل بدون إنترنت**<br> خصوصية تامة، لا يوجد تتبع، ولا يحتاج اتصال بالشبكة. |
| **🔍 Smart Search**<br> Advanced search that ignores Diacritics (Tashkeel) and supports multi-word queries. | **🔍 بحث ذكي**<br> محرك بحث فوري يتجاهل التشكيل ويدعم البحث المتعدد للآيات. |
| **📜 Seamless Reading**<br> Vertical scrolling (Mushaf style) with high-performance rendering. | **📜 قراءة انسيابية**<br> تمرير عمودي مستمر بدلاً من تقليب الصفحات لمحاكاة المصحف. |
| **🎨 Modern Design**<br> Glassmorphism headers, Dark Mode, and dynamic font sizing. | **🎨 واجهة عصرية**<br> تصميم زجاجي أنيق، دعم للوضع الليلي، وتحكم بحجم الخط. |

---

## 🛠 Technical Highlights

For developers interested in the architecture:

*   **Architecture:** Pure Flutter (No heavy state management libraries), using `ValueNotifier` and `ScrollablePositionedList` for maximum performance.
*   **Data:** The Quran text is stored as compressed JSON (`assets/quran.json`) loaded into memory via Isolates, reducing the binary size by ~40% compared to hardcoded Dart Maps.
*   **Search:** Custom-built Inverted Index with Prefix Matching and Diacritic Normalization.

## 🔧 Building from Source

To build this app locally:

1.  **Clone the repo**
    ```bash
    git clone https://github.com/dmouayad/my_quran.git
    ```
2.  **Get dependencies**
    ```bash
    flutter pub get
    ```
3.  **Run the app**
    ```bash
    flutter run
    ```
4.  **Build Release APK** (Optimized)
    ```bash
    flutter build apk --release --obfuscate --split-debug-info=./debug-info
    ```

---

## 🤝 Contributing

Contributions are welcome! If you find a bug or want to improve the search algorithm:

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## 📄 License

Distributed under the **GPL-3.0 License**. See `LICENSE` for more information.

## تمّ بفضل الله