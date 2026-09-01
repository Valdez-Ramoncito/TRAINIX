import 'dart:math';
import 'package:trainixprogram/models/customer_account.dart';

class AccountGeneratorService {
  //predefined list of names
  //This pool is independent of the real customer names in OpenRouterAPIService
  //these are just filler accounts sitting alongside the real one.
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

  static List<Account> generate({
    required String sector,
    required String targetAccountId,
    required String problem,
    required String targetOwnerName,
  }) {
    final random = Random();

    //exclude the real customer's name from the decoy pool so we don't
    //end up with two accounts sharing the same name
    final decoyPool =
        _names
            .where((n) => n.toLowerCase() != targetOwnerName.toLowerCase())
            .toList()
          ..shuffle(random);

    //create a list of accounts
    final accounts = <Account>[];

    //create 9 decoy accounts
    for (int i = 0; i < 9; i++) {
      //and add each account to the created accounts list
      accounts.add(
        Account(
          accountId: 'ACCT-${1000 + random.nextInt(8999)}',
          ownerName: decoyPool[i % decoyPool.length],

          //this randomly chooses a detail for this particular account
          //we can create different details for this account
          //based on the chosen sector
          details: _decoyDetails(sector, random),

          //since these accounts are decoys, this is false
          isTarget: false,
        ),
      );
    }

    //the last account is the real target named after the actual
    //customer this call or chat is with, not a random decoy name, so the
    //account lookup always matches who the agent is actually talking to
    accounts.add(
      Account(
        //set the account id to the passed account id
        accountId: targetAccountId,
        ownerName: targetOwnerName,

        //this sets the details for the target account
        //by passing in the sector and problem, the details
        //of this account will contain the current sector
        //and the issue/problem that the customer has
        details: _targetDetails(sector, problem),

        //this is the target account, hence this is set to true
        isTarget: true,
      ),
    );

    //we shuffle the list of accounts first, then return those accounts
    accounts.shuffle(random);
    return accounts;
  }

  //this is where the details of the fake accounts are created
  static Map<String, String> _decoyDetails(String sector, Random r) {
    //based on the passed sector
    //Account type - choose a random account type based on the list
    //Balance - generate a random balance
    //Last '' - generate a random date
    //Issue - set to none
    switch (sector) {
      case 'Finance':
        return {
          'Account Type': ['Savings', 'Checking', 'Credit'][r.nextInt(3)],
          'Balance':
              '\$${r.nextInt(9500) + 500}.${r.nextInt(100).toString().padLeft(2, '0')}',
          'Card Status': 'Active',
          'Last Transaction': _randomDate(r),
          'Issue': 'None',
        };
      case 'Healthcare':
        return {
          'Provider': ['PhilHealth', 'Maxicare', 'Medicard'][r.nextInt(3)],
          'Policy No.': 'POL-${r.nextInt(90000) + 10000}',
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
          'Data Used': '${r.nextInt(80)} GB / 100 GB',
          'Monthly Bill': '\$${r.nextInt(40) + 20}.00',
          'Service Status': 'Active',
          'Issue': 'None',
        };
      default:
        return {
          'Device': ['Laptop', 'Desktop', 'Phone'][r.nextInt(3)],
          'OS': ['Windows 11', 'Windows 10', 'macOS 14'][r.nextInt(3)],
          'Software': 'v${r.nextInt(5) + 1}.${r.nextInt(10)}.0',
          'Last Update': _randomDate(r),
          'Issue': 'None',
        };
    }
  }

  //this is where the details of the real accounts are created
  static Map<String, String> _targetDetails(String sector, String problem) {
    //if the problem is specified, set it
    //otherwise, mark it as 'Unspecified'
    final issue = problem.isNotEmpty
        ? problem[0].toUpperCase() + problem.substring(1)
        : 'Unspecified';

    //based on the passed sector
    //Account type - if somewhere in the problem contains a certain word
    //set its status to a certain status, otherwise, the latter
    //Balance - fixed
    //Last '' - fixed
    //Issue - set to the issue above
    switch (sector) {
      case 'Finance':
        return {
          'Account Type': 'Savings',
          'Balance': '\$1,245.80',
          'Card Status': problem.contains('card') ? 'Blocked' : 'Active',
          'Last Transaction': 'May 20, 2026',
          'Issue': issue,
        };
      case 'Healthcare':
        return {
          'Provider': 'PhilHealth',
          'Policy No.': 'POL-48291',
          'Coverage': problem.contains('claim') ? 'Claim Pending' : 'Active',
          'Last Visit': 'Apr 15, 2026',
          'Issue': issue,
        };
      case 'Telco':
        return {
          'Plan': 'Standard 100 Mbps',
          'Data Used': '78 GB / 100 GB',
          'Monthly Bill': '\$35.00',
          'Service Status': problem.contains('outage')
              ? 'Outage'
              : problem.contains('dropping')
              ? 'Intermittent'
              : 'Active',
          'Issue': issue,
        };
      default:
        return {
          'Device': 'Laptop',
          'OS': 'Windows 11',
          'Software': 'v3.2.1',
          'Last Update': 'May 18, 2026',
          'Issue': issue,
        };
    }
  }

  //this generate a random date
  static String _randomDate(Random r) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May'];

    //return a random date
    return '${months[r.nextInt(months.length)]} ${r.nextInt(28) + 1}, 2026';
  }
}
