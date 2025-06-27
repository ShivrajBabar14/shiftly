import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.deepPurple.shade700,
                        Colors.deepPurple.shade400,
                        Colors.purple.shade300,
                      ],
                      stops: [0.1, 0.6, 1.0],
                    ),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/shift.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                _buildDrawerItem(Icons.share, 'Share App'),
                _buildDrawerItem(Icons.star, 'Rate Us'),
                _buildDrawerItem(Icons.feedback, 'Write Feedback'),
                _buildDrawerItem(Icons.public, 'Follow Us'),
                _buildDrawerItem(Icons.ads_click, 'Advertise with us'),
                _buildDrawerItem(Icons.apps, 'Try More Apps!'),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Version (4.13)',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title, style: TextStyle(color: Colors.black87)),
      onTap: () {
        // Handle item tap
      },
    );
  }
}