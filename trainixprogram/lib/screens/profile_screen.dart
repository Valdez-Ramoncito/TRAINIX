import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Account'),
          const ListTile(
            leading: Icon(Icons.person),
            title: Text('Name'),
            subtitle: Text('[User name]'),
          ),
          const ListTile(
            leading: Icon(Icons.email),
            title: Text('Email'),
            subtitle: Text('[User email]'),
          ),
          const ListTile(
            leading: Icon(Icons.badge),
            title: Text('Role'),
            subtitle: Text('[User role]'),
          ),
          _buildSectionHeader('Statistics'),
          const ListTile(
            leading: Icon(Icons.phone_in_talk),
            title: Text('Sessions Completed'),
            subtitle: Text('[0]'),
          ),
          const ListTile(
            leading: Icon(Icons.bar_chart),
            title: Text('Average Score'),
            subtitle: Text('[0]'),
          ),
          const ListTile(
            leading: Icon(Icons.star),
            title: Text('Best Score'),
            subtitle: Text('[0]'),
          ),
          _buildSectionHeader(''),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign Out'),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}