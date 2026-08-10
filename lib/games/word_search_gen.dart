import 'dart:math';

/// Pure word-search board generator. Guaranteed to place every word:
///  1. Random placement (right / down / diagonal), 200 attempts per word.
///  2. If any word fails, the whole board is regenerated (up to 25 boards).
///  3. If randomness still hasn't cooperated, a deterministic fallback lays
///     every word horizontally in its own row — which always succeeds for
///     up to [size] words of length ≤ [size].
/// The returned [words] list is exactly what's on the board, so the win
/// condition can never demand an unplaced word.
class WordSearchBoard {
  final List<List<String>> grid;
  final List<String> words;
  final Map<String, List<int>> placements; // word -> flat cell indices
  WordSearchBoard(this.grid, this.words, this.placements);
}

WordSearchBoard generateWordSearch(List<String> input, int size, Random rng) {
  final words = input
      .map((w) => w.toUpperCase())
      .where((w) => w.length <= size && w.isNotEmpty)
      .toList();
  const dirs = [(0, 1), (1, 0), (1, 1)];

  ({List<List<String>> grid, Map<String, List<int>> place})? attemptBoard() {
    final grid = List.generate(size, (_) => List.generate(size, (_) => ''));
    final place = <String, List<int>>{};
    for (final word in words) {
      var ok = false;
      for (var attempt = 0; attempt < 200 && !ok; attempt++) {
        final d = dirs[rng.nextInt(dirs.length)];
        final maxR = size - (word.length - 1) * d.$1;
        final maxC = size - (word.length - 1) * d.$2;
        if (maxR <= 0 || maxC <= 0) continue;
        final r0 = rng.nextInt(maxR), c0 = rng.nextInt(maxC);
        var fits = true;
        for (var i = 0; i < word.length; i++) {
          final cell = grid[r0 + i * d.$1][c0 + i * d.$2];
          if (cell.isNotEmpty && cell != word[i]) {
            fits = false;
            break;
          }
        }
        if (!fits) continue;
        final cells = <int>[];
        for (var i = 0; i < word.length; i++) {
          grid[r0 + i * d.$1][c0 + i * d.$2] = word[i];
          cells.add((r0 + i * d.$1) * size + (c0 + i * d.$2));
        }
        place[word] = cells;
        ok = true;
      }
      if (!ok) return null; // regenerate the whole board
    }
    return (grid: grid, place: place);
  }

  var board = attemptBoard();
  for (var tries = 0; tries < 25 && board == null; tries++) {
    board = attemptBoard();
  }

  // Deterministic fallback: one word per row, horizontal. Always succeeds.
  if (board == null) {
    final grid = List.generate(size, (_) => List.generate(size, (_) => ''));
    final place = <String, List<int>>{};
    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      final c0 = rng.nextInt(size - word.length + 1);
      final cells = <int>[];
      for (var k = 0; k < word.length; k++) {
        grid[i][c0 + k] = word[k];
        cells.add(i * size + c0 + k);
      }
      place[word] = cells;
    }
    board = (grid: grid, place: place);
  }

  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  for (var r = 0; r < size; r++) {
    for (var c = 0; c < size; c++) {
      if (board.grid[r][c].isEmpty) {
        board.grid[r][c] = alphabet[rng.nextInt(26)];
      }
    }
  }
  return WordSearchBoard(board.grid, words, board.place);
}

/// Snaps a drag from cell [a] toward cell [b] to the nearest straight line
/// (horizontal / vertical / diagonal), clamped to the grid. Pure.
List<int> snapRun(int a, int b, int size) {
  final r0 = a ~/ size, c0 = a % size, r1 = b ~/ size, c1 = b % size;
  var dr = r1 - r0, dc = c1 - c0;
  if (dr.abs() >= 2 * dc.abs()) {
    dc = 0;
  } else if (dc.abs() >= 2 * dr.abs()) {
    dr = 0;
  }
  final sr = dr.sign, sc = dc.sign;
  var len = dr.abs() > dc.abs() ? dr.abs() : dc.abs();
  while (len > 0) {
    final r = r0 + len * sr, c = c0 + len * sc;
    if (r >= 0 && r < size && c >= 0 && c < size) break;
    len--;
  }
  return [for (var k = 0; k <= len; k++) (r0 + k * sr) * size + (c0 + k * sc)];
}
