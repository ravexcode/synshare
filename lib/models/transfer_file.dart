/// A local file selected for sending.
class OutgoingFile {
  final String name;
  final int size;
  final String path;
  final DateTime modified;

  const OutgoingFile({
    required this.name,
    required this.size,
    required this.path,
    required this.modified,
  });
}

/// Sorting orders for the selected files list.
enum FileSort {
  latest('Latest'),
  oldest('Oldest'),
  aToZ('A - Z'),
  zToA('Z - A'),
  charNum('Char - Num'),
  numChar('Num - Char');

  final String label;

  const FileSort(this.label);
}

int compareFiles(FileSort sort, OutgoingFile a, OutgoingFile b) {
  switch (sort) {
    case FileSort.latest:
      return b.modified.compareTo(a.modified);
    case FileSort.oldest:
      return a.modified.compareTo(b.modified);
    case FileSort.aToZ:
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    case FileSort.zToA:
      return b.name.toLowerCase().compareTo(a.name.toLowerCase());
    case FileSort.charNum:
      return _categoryCompare(a, b, digitFirst: false);
    case FileSort.numChar:
      return _categoryCompare(a, b, digitFirst: true);
  }
}

/// Groups names by first character type: letters before digits (or the
/// reverse), then falls back to a plain lowercase name comparison.
int _categoryCompare(
  OutgoingFile a,
  OutgoingFile b, {
  required bool digitFirst,
}) {
  final catA = _categoryOf(a.name, digitFirst: digitFirst);
  final catB = _categoryOf(b.name, digitFirst: digitFirst);
  if (catA != catB) return catA.compareTo(catB);
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

int _categoryOf(String name, {required bool digitFirst}) {
  if (name.isEmpty) return 2;
  final code = name.codeUnitAt(0);
  final isLetter = _isLetter(code);
  final isDigit = _isDigit(code);
  if (digitFirst) {
    if (isDigit) return 0;
    if (isLetter) return 1;
    return 2;
  }
  if (isLetter) return 0;
  if (isDigit) return 1;
  return 2;
}

bool _isLetter(int code) =>
    (code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A);

bool _isDigit(int code) => code >= 0x30 && code <= 0x39;
