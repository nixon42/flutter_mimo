---
trigger: always_on
---

# Mandatory TDD Workflow

Semua pengerjaan fitur baru/bugfix **WAJIB MUTLAK** menggunakan Test Driven Development (TDD).

## Siklus (Red-Green-Refactor)
1. **RED**: Tulis test yang gagal di `test/` terlebih dahulu. **DILARANG** menulis implementasi sebelum test.
2. **GREEN**: Tulis implementasi kode **seminimal mungkin** di `src/` hanya untuk membuat test di atas lulus.
3. **REFACTOR**: Rapikan struktur kode setelah test lulus, pastikan test tetap hijau.

## Aturan Tambahan
- **Mocking**: Gunakan `unittest.mock` untuk sistem eksternal (Filesystem, GreenAPI). Test harus terisolasi.