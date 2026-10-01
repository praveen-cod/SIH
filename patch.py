import re
with open('lib/shared/widgets/app_navigation.dart', 'r', encoding='utf-8') as f:
    c = f.read()
c = re.sub(r"title: 'Profile',\s*icon: Icons.person_outline_rounded,\s*activeIcon: Icons.person_rounded,", "title: 'Profile', icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, route: AppRoutes.profile,", c)
c = re.sub(r"title: 'Settings',\s*icon: Icons.settings_outlined,\s*activeIcon: Icons.settings_rounded,", "title: 'Settings', icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, route: AppRoutes.settings,", c)
with open('lib/shared/widgets/app_navigation.dart', 'w', encoding='utf-8') as f:
    f.write(c)
