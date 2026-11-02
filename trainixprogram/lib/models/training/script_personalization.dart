import 'package:trainixprogram/screens/page/profile.dart';

class ScriptPersonalization {
  static const companyName = 'Trainix Support';

  static String get agentFullName {
    final name = ProfileData.displayName.trim();
    if (name.isEmpty) return 'Agent';
    return name;
  }

  static String get agentFirstName {
    final parts = agentFullName.split(RegExp(r'\s+'));
    return parts.isEmpty ? 'Agent' : parts.first;
  }

  static String? get agentHonorific {
    switch (ProfileData.gender) {
      case 'Female':
        return 'Ms.';
      case 'Male':
        return 'Mr.';
      default:
        return null;
    }
  }

  static String get agentIntroName {
    final honorific = agentHonorific;
    if (honorific == null) return agentFullName;
    return '$honorific $agentFullName';
  }

  static String resolve(String raw) {
    if (raw.isEmpty) return raw;
    var t = raw;
    t = t.replaceAll('[Company Name]', companyName);
    t = t.replaceAll('[Your Name]', agentFullName);
    t = t.replaceAll('[your name]', agentFullName);
    t = t.replaceAll('[Your name]', agentFullName);
    t = t.replaceAll('[name]', agentFirstName);
    t = t.replaceAll('[Name]', agentFirstName);
    t = t.replaceAll('[Company]', companyName);
    t = t.replaceAll('Alex Rivera', agentFullName);
    t = t.replaceAll('Alex', agentFirstName);
    t = t.replaceAll('Horizon Telco Support', companyName);
    t = t.replaceAll('Horizon Health Support', companyName);
    t = t.replaceAll('Horizon Finance Support', companyName);
    t = t.replaceAll('Horizon Support', companyName);
    t = t.replaceAll('Horizon Mobile', companyName);
    t = t.replaceAll('Horizon Finance', companyName);
    t = t.replaceAll('Horizon Health', companyName);
    t = t.replaceAll('Horizon', 'Trainix');
    return t;
  }
}
