import 'dart:math';

/// Supported sorting algorithms.
enum SortAlgorithm {
  bubble('Bubble Sort', 'O(n²)', 'O(1)', 'Compares adjacent elements and swaps them if out of order.'),
  selection('Selection Sort', 'O(n²)', 'O(1)', 'Finds the minimum element and places it at the beginning.'),
  insertion('Insertion Sort', 'O(n²)', 'O(1)', 'Builds the sorted array one element at a time.'),
  merge('Merge Sort', 'O(n log n)', 'O(n)', 'Divides array in half, sorts each, then merges.'),
  quick('Quick Sort', 'O(n log n)*', 'O(log n)', 'Picks a pivot, partitions around it, recurses.');

  final String label;
  final String timeComplexity;
  final String spaceComplexity;
  final String description;
  const SortAlgorithm(this.label, this.timeComplexity, this.spaceComplexity, this.description);
}

/// A single step in the sorting visualization.
class SortStep {
  final List<int> array;
  final int? comparing1;
  final int? comparing2;
  final Set<int> sorted;
  final String description;

  SortStep({
    required this.array,
    this.comparing1,
    this.comparing2,
    Set<int>? sorted,
    this.description = '',
  }) : sorted = sorted ?? {};
}

/// Generates step-by-step sorting visualizations.
class SortVisualizerService {
  final Random _random = Random();

  /// Generate a random array of the given size with values 1..maxVal.
  List<int> generateArray(int size, {int maxVal = 100}) {
    return List.generate(size, (_) => _random.nextInt(maxVal) + 1);
  }

  /// Generate all steps for the given algorithm.
  List<SortStep> generateSteps(List<int> input, SortAlgorithm algorithm) {
    final arr = List<int>.from(input);
    switch (algorithm) {
      case SortAlgorithm.bubble:
        return _bubbleSort(arr);
      case SortAlgorithm.selection:
        return _selectionSort(arr);
      case SortAlgorithm.insertion:
        return _insertionSort(arr);
      case SortAlgorithm.merge:
        return _mergeSort(arr);
      case SortAlgorithm.quick:
        return _quickSort(arr);
    }
  }

  List<SortStep> _bubbleSort(List<int> arr) {
    final steps = <SortStep>[];
    final sorted = <int>{};
    final n = arr.length;
    steps.add(SortStep(array: List.from(arr), description: 'Initial array'));
    for (var i = 0; i < n - 1; i++) {
      for (var j = 0; j < n - i - 1; j++) {
        steps.add(SortStep(
          array: List.from(arr),
          comparing1: j,
          comparing2: j + 1,
          sorted: Set.from(sorted),
          description: 'Compare ${arr[j]} and ${arr[j + 1]}',
        ));
        if (arr[j] > arr[j + 1]) {
          final tmp = arr[j];
          arr[j] = arr[j + 1];
          arr[j + 1] = tmp;
          steps.add(SortStep(
            array: List.from(arr),
            comparing1: j,
            comparing2: j + 1,
            sorted: Set.from(sorted),
            description: 'Swap ${arr[j + 1]} and ${arr[j]}',
          ));
        }
      }
      sorted.add(n - i - 1);
    }
    sorted.add(0);
    steps.add(SortStep(array: List.from(arr), sorted: Set.from(sorted), description: 'Sorted!'));
    return steps;
  }

  List<SortStep> _selectionSort(List<int> arr) {
    final steps = <SortStep>[];
    final sorted = <int>{};
    final n = arr.length;
    steps.add(SortStep(array: List.from(arr), description: 'Initial array'));
    for (var i = 0; i < n - 1; i++) {
      var minIdx = i;
      for (var j = i + 1; j < n; j++) {
        steps.add(SortStep(
          array: List.from(arr),
          comparing1: minIdx,
          comparing2: j,
          sorted: Set.from(sorted),
          description: 'Find minimum: comparing ${arr[minIdx]} and ${arr[j]}',
        ));
        if (arr[j] < arr[minIdx]) minIdx = j;
      }
      if (minIdx != i) {
        final tmp = arr[i];
        arr[i] = arr[minIdx];
        arr[minIdx] = tmp;
        steps.add(SortStep(
          array: List.from(arr),
          comparing1: i,
          comparing2: minIdx,
          sorted: Set.from(sorted),
          description: 'Swap ${arr[minIdx]} to position $i',
        ));
      }
      sorted.add(i);
    }
    sorted.add(n - 1);
    steps.add(SortStep(array: List.from(arr), sorted: Set.from(sorted), description: 'Sorted!'));
    return steps;
  }

  List<SortStep> _insertionSort(List<int> arr) {
    final steps = <SortStep>[];
    final sorted = <int>{0};
    final n = arr.length;
    steps.add(SortStep(array: List.from(arr), sorted: {0}, description: 'Initial array'));
    for (var i = 1; i < n; i++) {
      final key = arr[i];
      var j = i - 1;
      steps.add(SortStep(
        array: List.from(arr),
        comparing1: i,
        sorted: Set.from(sorted),
        description: 'Insert $key into sorted portion',
      ));
      while (j >= 0 && arr[j] > key) {
        arr[j + 1] = arr[j];
        steps.add(SortStep(
          array: List.from(arr),
          comparing1: j,
          comparing2: j + 1,
          sorted: Set.from(sorted),
          description: 'Shift ${arr[j]} right',
        ));
        j--;
      }
      arr[j + 1] = key;
      sorted.add(i);
      steps.add(SortStep(
        array: List.from(arr),
        comparing1: j + 1,
        sorted: Set.from(sorted),
        description: 'Place $key at position ${j + 1}',
      ));
    }
    steps.add(SortStep(array: List.from(arr), sorted: Set.from(sorted), description: 'Sorted!'));
    return steps;
  }

  List<SortStep> _mergeSort(List<int> arr) {
    final steps = <SortStep>[];
    steps.add(SortStep(array: List.from(arr), description: 'Initial array'));
    _mergeSortHelper(arr, 0, arr.length - 1, steps);
    steps.add(SortStep(
      array: List.from(arr),
      sorted: Set.from(List.generate(arr.length, (i) => i)),
      description: 'Sorted!',
    ));
    return steps;
  }

  void _mergeSortHelper(List<int> arr, int left, int right, List<SortStep> steps) {
    if (left >= right) return;
    final mid = (left + right) ~/ 2;
    steps.add(SortStep(
      array: List.from(arr),
      comparing1: left,
      comparing2: right,
      description: 'Divide: [$left..$right] at mid=$mid',
    ));
    _mergeSortHelper(arr, left, mid, steps);
    _mergeSortHelper(arr, mid + 1, right, steps);
    _merge(arr, left, mid, right, steps);
  }

  void _merge(List<int> arr, int left, int mid, int right, List<SortStep> steps) {
    final leftPart = arr.sublist(left, mid + 1);
    final rightPart = arr.sublist(mid + 1, right + 1);
    var i = 0, j = 0, k = left;
    while (i < leftPart.length && j < rightPart.length) {
      steps.add(SortStep(
        array: List.from(arr),
        comparing1: left + i,
        comparing2: mid + 1 + j,
        description: 'Merge: compare ${leftPart[i]} and ${rightPart[j]}',
      ));
      if (leftPart[i] <= rightPart[j]) {
        arr[k++] = leftPart[i++];
      } else {
        arr[k++] = rightPart[j++];
      }
    }
    while (i < leftPart.length) arr[k++] = leftPart[i++];
    while (j < rightPart.length) arr[k++] = rightPart[j++];
    steps.add(SortStep(array: List.from(arr), description: 'Merged [$left..$right]'));
  }

  List<SortStep> _quickSort(List<int> arr) {
    final steps = <SortStep>[];
    steps.add(SortStep(array: List.from(arr), description: 'Initial array'));
    _quickSortHelper(arr, 0, arr.length - 1, steps);
    steps.add(SortStep(
      array: List.from(arr),
      sorted: Set.from(List.generate(arr.length, (i) => i)),
      description: 'Sorted!',
    ));
    return steps;
  }

  void _quickSortHelper(List<int> arr, int low, int high, List<SortStep> steps) {
    if (low >= high) return;
    final pivot = arr[high];
    steps.add(SortStep(
      array: List.from(arr),
      comparing1: high,
      description: 'Pivot = $pivot at index $high',
    ));
    var i = low - 1;
    for (var j = low; j < high; j++) {
      steps.add(SortStep(
        array: List.from(arr),
        comparing1: j,
        comparing2: high,
        description: 'Compare ${arr[j]} with pivot $pivot',
      ));
      if (arr[j] < pivot) {
        i++;
        final tmp = arr[i];
        arr[i] = arr[j];
        arr[j] = tmp;
      }
    }
    i++;
    final tmp = arr[i];
    arr[i] = arr[high];
    arr[high] = tmp;
    steps.add(SortStep(
      array: List.from(arr),
      comparing1: i,
      description: 'Pivot placed at index $i',
    ));
    _quickSortHelper(arr, low, i - 1, steps);
    _quickSortHelper(arr, i + 1, high, steps);
  }
}
