import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text('About'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // 🔷 LOGO + NAME
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary,
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Container(
                  height: 150,
                  width: 150,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white12,
                  ),
                  child: const CircleAvatar(
                    radius: 42,
                    backgroundImage: AssetImage(
                      'assets/images/rhythmax/rhythmax_logo.jpg',
                    ),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Image.asset(
                'assets/images/rhythmax/transparent_fulltext.png',
                height: 30,
              ),
              const SizedBox(height: 8),
              Text(
                'Built by a music lover, for music lovers.',
                style: TextStyle(
                  fontFamily: "Poppins Medium",
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Made with ❤️ by OD SKYLER',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(); // or a small shimmer / placeholder
                  }

                  final info = snapshot.data!;

                  return Text(
                    'Version ${info.version} (${info.buildNumber})',
                    style: const TextStyle(color: Colors.white),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 32),

          _sectionTitle('About Rhythmax'),

          const SizedBox(height: 8),

          const Text(
            'Rhythmax is a source-based music player designed for users who '
                'want full control over their listening experience.\n\n'
                'Instead of locking you into a single streaming service, Rhythmax '
                'connects to multiple music sources through a unified interface.',
            style: TextStyle(
                height: 1.5,
                fontFamily: 'Poppins Medium'
            ),
          ),

          const SizedBox(height: 28),

          _sectionTitle('Core Features'),

          const SizedBox(height: 12),

          _feature('Source-agnostic player architecture'),
          _feature('Offline + online playback'),
          _feature('Queue management & smart controls'),
          _feature('High quality audio streaming'),
          _feature('Modern responsive UI'),

          const SizedBox(height: 28),

          _sectionTitle('Legal'),

          const SizedBox(height: 8),

          const Text(
            'Rhythmax does not host or distribute any music.\n'
                'All content is streamed directly from the selected source.\n\n'
                'This project is not affiliated with or endorsed by any '
                'music service.',
            style: TextStyle(
              fontFamily: 'Poppins Medium',
                color: Colors.white,
                height: 1.5
            ),
          ),

          const SizedBox(height: 28),

          _actionTile(
            icon: Icons.article_outlined,
            title: 'Open source licenses',
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Rhythmax',
            ),
          ),

          const SizedBox(height: 40),

        ],
      ),
    );
  }

  // 🔹 Widgets

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _feature(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 18, color: Colors.cyanAccent),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
