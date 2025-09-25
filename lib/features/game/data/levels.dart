import '../domain/level.dart';

const _level1bg = 'assets/images/game/level1bg.png';
const _level1star = 'assets/images/game/level1star.png';
const _level2bg = 'assets/images/game/level2bg.png';
const _level2star = 'assets/images/game/level2star.png';
const _level3bg = 'assets/images/game/level3bg.png';
const _level3star = 'assets/images/game/level3star.png';
const _level4bg = 'assets/images/game/level4bg.png';
const _level4star = 'assets/images/game/level4star.png';

final levels = [
  Level(
    bg: _level1bg,
    star: _level1star,
    title: 'Aurora Star',
    desc:
        'Mythical fact: “They say that every Aurora Star can show you a forgotten dream.”',
    objective: 'Catch 15 stars',
    timeSeconds: 10,
  ),
  Level(
    bg: _level2bg,
    star: _level2star,
    title: 'Celestia Pearl',
    desc: 'Mythical fact: “It preserves the voices of ancient star travelers.”',
    objective: 'Catch 20 stars',
    timeSeconds: 15,
  ),
  Level(
    bg: _level3bg,
    star: _level3star,
    title: 'Obsidian Flame',
    desc: 'Mythical fact: “Whoever touches its light will see the future.”',
    objective: 'Catch 35 stars',
    timeSeconds: 25,
  ),
  Level(
    bg: _level4bg,
    star: _level4star,
    title: 'Ethereal Crown',
    desc: 'Mythical fact: “Its light chooses a new guardian of the heavens.”',
    objective: 'Catch 45 stars',
    timeSeconds: 30,
  ),
];
