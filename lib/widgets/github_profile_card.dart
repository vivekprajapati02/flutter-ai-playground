import 'package:flutter/material.dart';

class GithubProfileCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  const GithubProfileCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          backgroundImage: profile['avatar_url'] != null
              ? NetworkImage(profile['avatar_url'] as String)
              : null,
          radius: 24,
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                profile['name'] as String? ?? profile['login'] as String? ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (profile['bio'] != null)
                Text(profile['bio'] as String, style: const TextStyle(fontSize: 12)),
              Text(
                'Followers: ${profile['followers']}  •  Repos: ${profile['public_repos']}',
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
