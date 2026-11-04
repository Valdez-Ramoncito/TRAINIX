import 'dart:math';
import 'package:trainixprogram/models/customer_account.dart';

class AccountGeneratorService {
  static const List<String> _names = [
    'Maria Santos',
    'Juan dela Cruz',
    'Ana Reyes',
    'Jose Garcia',
    'Rosa Mendoza',
    'Miguel Torres',
    'Carmen Villanueva',
    'Pedro Castillo',
    'Elena Bautista',
    'Roberto Hernandez',
    'Teresa Lopez',
    'Fernando Aquino',
    'Corazon Ramirez',
    'Ricardo Domingo',
    'Luz Fernandez',
    'Antonio Salvador',
    'Imelda Cruz',
    'Danilo Navarro',
    'Josefina Ocampo',
    'Eduardo Pascual',
    'Remedios Manalo',
    'Alberto Custodio',
    'Perla Aguilar',
    'Rodrigo Marquez',
    'Amelia Bernardo',
  ];

  static String _normalizeListAccountId(String raw, String ownerName) {
    final t = raw.trim();
    if (t.toUpperCase().startsWith('ACC-')) return t;
    final digits = t.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isNotEmpty) {
      final n = int.tryParse(digits) ?? ownerName.hashCode.abs();
      return 'ACC-${(n % 9000) + 1000}';
    }
    return 'ACC-${ownerName.hashCode.abs() % 9000 + 1000}';
  }

  static List<Account> generate({
    required String sector,
    required String targetAccountId,
    required String problem,
    required String targetOwnerName,
    Map<String, String> targetDetailExtras = const {},
  }) {
    final random = Random();
    final decoyPool =
        _names
            .where((n) => n.toLowerCase() != targetOwnerName.toLowerCase())
            .toList()
          ..shuffle(random);

    final targetDetails = {
      ..._targetDetails(sector, problem),
      ...targetDetailExtras,
    };
    final detailKeys = targetDetails.keys.toList();

    final accounts = <Account>[];
    for (int i = 0; i < 9; i++) {
      accounts.add(
        Account(
          accountId: 'ACC-${1000 + random.nextInt(8999)}',
          ownerName: decoyPool[i % decoyPool.length],
          details: _decoyDetailsMatching(sector, random, detailKeys),
          isTarget: false,
        ),
      );
    }

    accounts.add(
      Account(
        accountId: _normalizeListAccountId(targetAccountId, targetOwnerName),
        ownerName: targetOwnerName,
        details: targetDetails,
        isTarget: true,
      ),
    );

    accounts.shuffle(random);
    return accounts;
  }

  static Map<String, String> _decoyDetailsMatching(
    String sector,
    Random r,
    List<String> keys,
  ) {
    final base = _decoyDetails(sector, r);
    final out = <String, String>{};
    for (final key in keys) {
      if (base.containsKey(key)) {
        out[key] = base[key]!;
      } else if (key == 'Card Ending') {
        out[key] = (1000 + r.nextInt(9000)).toString();
      } else if (key == 'Member ID') {
        out[key] = 'ACC-${1000 + r.nextInt(8999)}';
      } else if (key == 'Mobile Ending') {
        out[key] = (1000 + r.nextInt(9000)).toString();
      } else if (key == 'Email') {
        out[key] = 'user${r.nextInt(9000)}@example.com';
      } else if (key == 'Pending Amount') {
        out[key] =
            '\$${r.nextInt(200) + 20}.${r.nextInt(100).toString().padLeft(2, '0')}';
      } else {
        out[key] = base[key] ?? 'N/A';
      }
    }
    if (out.isEmpty) return base;
    return out;
  }

  static Map<String, String> _decoyDetails(String sector, Random r) {
    switch (sector) {
      case 'Finance':
        return {
          'Account Type': ['Savings', 'Checking', 'Credit'][r.nextInt(3)],
          'Balance':
              '\$${r.nextInt(9500) + 500}.${r.nextInt(100).toString().padLeft(2, '0')}',
          'Card Status': 'Active',
          'Card Ending': (1000 + r.nextInt(9000)).toString(),
          'Pending Amount': '\$0.00',
          'Last Transaction': _randomDate(r),
          'Issue': 'None',
        };
      case 'Healthcare':
        return {
          'Provider': ['PhilHealth', 'Maxicare', 'Medicard'][r.nextInt(3)],
          'Policy No.': 'POL-${r.nextInt(90000) + 10000}',
          'Member ID': 'ACC-${1000 + r.nextInt(8999)}',
          'Coverage': 'Active',
          'Last Visit': _randomDate(r),
          'Issue': 'None',
        };
      case 'Telco':
        return {
          'Plan': [
            'Basic 50 Mbps',
            'Standard 100 Mbps',
            'Premium 200 Mbps',
          ][r.nextInt(3)],
          'Mobile Ending': (1000 + r.nextInt(9000)).toString(),
          'Data Used': '${r.nextInt(80)} GB / 100 GB',
          'Monthly Bill': '\$${r.nextInt(40) + 20}.00',
          'Service Status': 'Active',
          'Issue': 'None',
        };
      default:
        return {
          'Device': ['Laptop', 'Desktop', 'Phone'][r.nextInt(3)],
          'OS': ['Windows 11', 'Windows 10', 'macOS 14'][r.nextInt(3)],
          'Email': 'user${r.nextInt(9000)}@example.com',
          'Software': 'v${r.nextInt(5) + 1}.${r.nextInt(10)}.0',
          'Last Update': _randomDate(r),
          'Issue': 'None',
        };
    }
  }

  static Map<String, String> _targetDetails(String sector, String problem) {
    final issue = problem.isNotEmpty
        ? problem[0].toUpperCase() + problem.substring(1)
        : 'Unspecified';

    switch (sector) {
      case 'Finance':
        return {
          'Account Type': 'Savings',
          'Balance': '\$1,245.80',
          'Card Status':
              problem.toLowerCase().contains('card') ||
                  problem.toLowerCase().contains('pending')
              ? 'Pending review'
              : 'Active',
          'Card Ending': '0000',
          'Pending Amount': problem.toLowerCase().contains('pending')
              ? '\$48.50'
              : '\$0.00',
          'Last Transaction': 'May 20, 2026',
          'Issue': issue,
        };
      case 'Healthcare':
        return {
          'Provider': 'PhilHealth',
          'Policy No.': 'POL-48291',
          'Member ID': 'ACC-00000',
          'Coverage': problem.toLowerCase().contains('claim')
              ? 'Claim Pending'
              : 'Active',
          'Last Visit': 'Apr 15, 2026',
          'Issue': issue,
        };
      case 'Telco':
        return {
          'Plan':
              problem.toLowerCase().contains('upgrade') ||
                  problem.toLowerCase().contains('plan')
              ? 'Premium Plus (blocked)'
              : 'Standard 100 Mbps',
          'Mobile Ending': '0000',
          'Data Used': '78 GB / 100 GB',
          'Monthly Bill': '\$35.00',
          'Service Status':
              problem.toLowerCase().contains('outage') ||
                  problem.toLowerCase().contains('down')
              ? 'Outage'
              : problem.toLowerCase().contains('dropping')
              ? 'Intermittent'
              : 'Active',
          'Issue': issue,
        };
      default:
        return {
          'Device': 'Laptop',
          'OS': 'Windows 11',
          'Email': 'customer@example.com',
          'Software': 'v3.2.1',
          'Last Update': 'May 18, 2026',
          'Issue': issue,
        };
    }
  }

  static String _randomDate(Random r) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May'];
    return '${months[r.nextInt(months.length)]} ${r.nextInt(28) + 1}, 2026';
  }
}
