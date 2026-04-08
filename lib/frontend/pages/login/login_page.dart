import 'package:flutter/material.dart';
import '../../utils/colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),

            // 🔷 LOGO
            Center(
              child: Image.asset(
                'assets/images/logo.png',
                width: 120,
              ),
            ),

            const SizedBox(height: 40),

            // 🔷 CARD LOGIN
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // 🔷 TITLE
                    const Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      "Selamat datang, silahkan login!",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // 🔷 USERNAME
                    const CustomTextField(hint: "Username"),

                    const SizedBox(height: 15),

                    // 🔷 PASSWORD
                    const CustomTextField(
                      hint: "Password",
                      isPassword: true,
                    ),

                    const SizedBox(height: 25),

                    // 🔷 BUTTON
                    CustomButton(
                      text: "Login",
                      onPressed: () {
                        print("Login ditekan");
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}