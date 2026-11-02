class lottieAnimation {
  final int id;
  final String name;
  final String background;
  final String title;
  final String subtitle;

  lottieAnimation({
    required this.id,
    required this.name,
    required this.background,
    required this.title,
    required this.subtitle,
  });
}

List<lottieAnimation> animation = [
  lottieAnimation(
    id: 1,
    name: 'assets/animations/account.json',
    background: 'assets/animations/background/card.png',
    title: 'Account Profile',
    subtitle:
        'View and manage your personal information, and learning details all in one place.',
  ),
  lottieAnimation(
    id: 2,
    name: 'assets/animations/trainer.json',
    background: 'assets/animations/background/card4.png',
    title: 'Trainer Session',
    subtitle:
        'Equips essential skills and knowledge needed to succeed in a BPO environment',
  ),
  lottieAnimation(
    id: 3,
    name: 'assets/animations/training.json',
    background: 'assets/animations/background/card1.png',
    title: 'Training Session',
    subtitle:
        'Equips essential skills and knowledge needed to succeed in a BPO environment',
  ),
  lottieAnimation(
    id: 4,
    name: 'assets/animations/mini.json',
    background: 'assets/animations/background/card3.png',
    title: 'Mini Training',
    subtitle:
        'Clear overview of your training journey by tracking assessment scores, and overall performance.',
  ),
  lottieAnimation(
    id: 5,
    name: 'assets/animations/progress.json',
    background: 'assets/animations/background/card2.png',
    title: 'Progress Dashboard',
    subtitle:
        'Clear overview of your training journey by tracking assessment scores, and overall performance.',
  ),
];

//trainer
List<lottieAnimation> animationTrainer = [
  lottieAnimation(
    id: 1,
    name: 'assets/animations/account.json',
    background: 'assets/animations/background/card.png',
    title: 'Account Profile',
    subtitle:
        'View and manage your personal information, and learning details all in one place.',
  ),
  lottieAnimation(
    id: 2,
    name: 'assets/animations/training.json',
    background: 'assets/animations/background/card4.png',
    title: 'Trainee Session',
    subtitle:
        'Equips essential skills and knowledge needed to succeed in a BPO environment',
  ),
  lottieAnimation(
    id: 3,
    name: 'assets/animations/progress.json',
    background: 'assets/animations/background/card2.png',
    title: 'Log Monitoring',
    subtitle:
        'Live session records, trainee activity logs, and coaching proof for trainers.',
  ),
];
