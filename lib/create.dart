import 'package:flutter/material.dart';

class CreateAccountPage extends StatefulWidget {
  @override
  _CreateAccountPageState createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1C2431),
      appBar: AppBar(
        title: Text(
          'Buat Akun',
          style: TextStyle(color: Color(0xFFD9DADE)),
        ),
        backgroundColor: Color(0xFF1C2431),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Color(
                0xFFD9DADE), // Set warna panah kembali sama dengan teks 'Buat Akun'
          ),
          onPressed: () {
            // Handle fungsi kembali di sini
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: TextStyle(color: Color(0xFFD9DADE)),
              ),
              style: TextStyle(color: Color(0xFFD9DADE)),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: Color(0xFFD9DADE)),
              ),
              style: TextStyle(color: Color(0xFFD9DADE)),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Color(0xFFD9DADE)),
              ),
              style: TextStyle(color: Color(0xFFD9DADE)),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Panggil fungsi untuk membuat akun di sini
                _createAccount();
              },
              child: Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }

  void _createAccount() {
    // Implementasikan logika untuk membuat akun di sini
    // Gunakan nilai dari _nameController.text, _emailController.text, dan _passwordController.text
    // untuk mengirim data ke backend atau melakukan otentikasi.

    // Contoh sederhana:
    String name = _nameController.text;
    String email = _emailController.text;
    String password = _passwordController.text;

    // Lakukan validasi input dan kirim data ke backend atau autentikasi
    // ...

    // Setelah berhasil membuat akun, mungkin Anda ingin
    // melakukan navigasi ke halaman lain atau memberikan feedback.
  }
}
