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
        'Update your name, photo, and learning preferences before you start practice.',
  ),
  lottieAnimation(
    id: 2,
    name: 'assets/animations/trainer.json',
    background: 'assets/animations/background/card4.png',
    title: 'Trainer Session',
    subtitle:
        'Join a live session with your trainer for guided coaching and feedback.',
  ),
  lottieAnimation(
    id: 3,
    name: 'assets/animations/training.json',
    background: 'assets/animations/background/card1.png',
    title: 'Simulation Training',
    subtitle:
        'Practice full customer conversations in Non-Voice or Voice, then review your scores.',
  ),
  lottieAnimation(
    id: 4,
    name: 'assets/animations/mini.json',
    background: 'assets/animations/background/card3.png',
    title: 'Mini Training',
    subtitle:
        'Short lessons and practice drills that unlock the next part of your path.',
  ),
  lottieAnimation(
    id: 5,
    name: 'assets/animations/progress.json',
    background: 'assets/animations/background/card2.png',
    title: 'Progress Dashboard',
    subtitle:
        'See your recent scores, strengths, and what to improve after each practice.',
  ),
];

List<lottieAnimation> animationTrainer = [
  lottieAnimation(
    id: 1,
    name: 'assets/animations/account.json',
    background: 'assets/animations/background/card.png',
    title: 'Account Profile',
    subtitle: 'Update your name and preferences used across trainer tools.',
  ),
  lottieAnimation(
    id: 2,
    name: 'assets/animations/training.json',
    background: 'assets/animations/background/card4.png',
    title: 'Trainee Session',
    subtitle: 'Create or join a live room to coach a trainee in real time.',
  ),
  lottieAnimation(
    id: 3,
    name: 'assets/animations/progress.json',
    background: 'assets/animations/background/card2.png',
    title: 'Log Monitoring',
    subtitle: 'Review trainee activity, live rooms, and recent coaching notes.',
  ),
];
