import 'package:flutter/material.dart';
import 'chat_screen.dart';
import 'signup_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 80, color: Colors.blueAccent),
                SizedBox(height: 20),
                Text("AURA Suite", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)), // Changed "Welcome Back" to "AURA Suite"
                SizedBox(height: 40),
                _buildTextField(Icons.email, "Email"),
                SizedBox(height: 20),
                _buildTextField(Icons.lock, "Password", obscureText: true),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => DashboardScreen())),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  ),
                  child: Text("Login", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
                TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SignupScreen())),
                  child: Text("Don't have an account? Sign Up", style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(IconData icon, String label, {bool obscureText = false}) {
    return TextField(
      obscureText: obscureText,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white54),
        labelText: label,
        labelStyle: TextStyle(color: Colors.white54),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(25)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent), borderRadius: BorderRadius.circular(25)),
      ),
    );
  }
}
