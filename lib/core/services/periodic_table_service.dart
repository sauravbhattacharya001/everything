/// Data and logic for an interactive periodic table of elements.

class Element {
  final int atomicNumber;
  final String symbol;
  final String name;
  final double atomicMass;
  final String category;
  final int group;
  final int period;
  final String electronConfig;
  final double? electronegativity;
  final double? density; // g/cm³
  final double? meltingPoint; // K
  final double? boilingPoint; // K
  final int? yearDiscovered;

  const Element({
    required this.atomicNumber,
    required this.symbol,
    required this.name,
    required this.atomicMass,
    required this.category,
    required this.group,
    required this.period,
    required this.electronConfig,
    this.electronegativity,
    this.density,
    this.meltingPoint,
    this.boilingPoint,
    this.yearDiscovered,
  });

  String get massFormatted => atomicMass.toStringAsFixed(
      atomicMass == atomicMass.roundToDouble() ? 0 : 3);
}

class PeriodicTableService {
  static const categories = [
    'Alkali Metal',
    'Alkaline Earth Metal',
    'Transition Metal',
    'Post-Transition Metal',
    'Metalloid',
    'Nonmetal',
    'Halogen',
    'Noble Gas',
    'Lanthanide',
    'Actinide',
  ];

  static List<Element> search(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return elements;
    return elements.where((e) {
      return e.name.toLowerCase().contains(q) ||
          e.symbol.toLowerCase() == q ||
          e.atomicNumber.toString() == q ||
          e.category.toLowerCase().contains(q);
    }).toList();
  }

  static Element? byNumber(int n) {
    try {
      return elements.firstWhere((e) => e.atomicNumber == n);
    } catch (_) {
      return null;
    }
  }

  /// First 118 elements — key properties included.
  static const elements = [
    Element(atomicNumber: 1, symbol: 'H', name: 'Hydrogen', atomicMass: 1.008, category: 'Nonmetal', group: 1, period: 1, electronConfig: '1s¹', electronegativity: 2.20, density: 0.00009, meltingPoint: 14.01, boilingPoint: 20.28, yearDiscovered: 1766),
    Element(atomicNumber: 2, symbol: 'He', name: 'Helium', atomicMass: 4.003, category: 'Noble Gas', group: 18, period: 1, electronConfig: '1s²', density: 0.000179, boilingPoint: 4.22, yearDiscovered: 1868),
    Element(atomicNumber: 3, symbol: 'Li', name: 'Lithium', atomicMass: 6.941, category: 'Alkali Metal', group: 1, period: 2, electronConfig: '[He] 2s¹', electronegativity: 0.98, density: 0.534, meltingPoint: 453.69, boilingPoint: 1615, yearDiscovered: 1817),
    Element(atomicNumber: 4, symbol: 'Be', name: 'Beryllium', atomicMass: 9.012, category: 'Alkaline Earth Metal', group: 2, period: 2, electronConfig: '[He] 2s²', electronegativity: 1.57, density: 1.85, meltingPoint: 1560, boilingPoint: 2744, yearDiscovered: 1798),
    Element(atomicNumber: 5, symbol: 'B', name: 'Boron', atomicMass: 10.81, category: 'Metalloid', group: 13, period: 2, electronConfig: '[He] 2s² 2p¹', electronegativity: 2.04, density: 2.34, meltingPoint: 2349, boilingPoint: 4200, yearDiscovered: 1808),
    Element(atomicNumber: 6, symbol: 'C', name: 'Carbon', atomicMass: 12.011, category: 'Nonmetal', group: 14, period: 2, electronConfig: '[He] 2s² 2p²', electronegativity: 2.55, density: 2.267, meltingPoint: 3823, boilingPoint: 4098, yearDiscovered: -3750),
    Element(atomicNumber: 7, symbol: 'N', name: 'Nitrogen', atomicMass: 14.007, category: 'Nonmetal', group: 15, period: 2, electronConfig: '[He] 2s² 2p³', electronegativity: 3.04, density: 0.0012506, meltingPoint: 63.15, boilingPoint: 77.36, yearDiscovered: 1772),
    Element(atomicNumber: 8, symbol: 'O', name: 'Oxygen', atomicMass: 15.999, category: 'Nonmetal', group: 16, period: 2, electronConfig: '[He] 2s² 2p⁴', electronegativity: 3.44, density: 0.001429, meltingPoint: 54.36, boilingPoint: 90.20, yearDiscovered: 1774),
    Element(atomicNumber: 9, symbol: 'F', name: 'Fluorine', atomicMass: 18.998, category: 'Halogen', group: 17, period: 2, electronConfig: '[He] 2s² 2p⁵', electronegativity: 3.98, density: 0.001696, meltingPoint: 53.53, boilingPoint: 85.03, yearDiscovered: 1886),
    Element(atomicNumber: 10, symbol: 'Ne', name: 'Neon', atomicMass: 20.180, category: 'Noble Gas', group: 18, period: 2, electronConfig: '[He] 2s² 2p⁶', density: 0.0008999, meltingPoint: 24.56, boilingPoint: 27.07, yearDiscovered: 1898),
    Element(atomicNumber: 11, symbol: 'Na', name: 'Sodium', atomicMass: 22.990, category: 'Alkali Metal', group: 1, period: 3, electronConfig: '[Ne] 3s¹', electronegativity: 0.93, density: 0.971, meltingPoint: 370.87, boilingPoint: 1156, yearDiscovered: 1807),
    Element(atomicNumber: 12, symbol: 'Mg', name: 'Magnesium', atomicMass: 24.305, category: 'Alkaline Earth Metal', group: 2, period: 3, electronConfig: '[Ne] 3s²', electronegativity: 1.31, density: 1.738, meltingPoint: 923, boilingPoint: 1363, yearDiscovered: 1755),
    Element(atomicNumber: 13, symbol: 'Al', name: 'Aluminium', atomicMass: 26.982, category: 'Post-Transition Metal', group: 13, period: 3, electronConfig: '[Ne] 3s² 3p¹', electronegativity: 1.61, density: 2.698, meltingPoint: 933.47, boilingPoint: 2792, yearDiscovered: 1825),
    Element(atomicNumber: 14, symbol: 'Si', name: 'Silicon', atomicMass: 28.086, category: 'Metalloid', group: 14, period: 3, electronConfig: '[Ne] 3s² 3p²', electronegativity: 1.90, density: 2.3296, meltingPoint: 1687, boilingPoint: 3538, yearDiscovered: 1824),
    Element(atomicNumber: 15, symbol: 'P', name: 'Phosphorus', atomicMass: 30.974, category: 'Nonmetal', group: 15, period: 3, electronConfig: '[Ne] 3s² 3p³', electronegativity: 2.19, density: 1.82, meltingPoint: 317.30, boilingPoint: 553.65, yearDiscovered: 1669),
    Element(atomicNumber: 16, symbol: 'S', name: 'Sulfur', atomicMass: 32.06, category: 'Nonmetal', group: 16, period: 3, electronConfig: '[Ne] 3s² 3p⁴', electronegativity: 2.58, density: 2.067, meltingPoint: 388.36, boilingPoint: 717.87, yearDiscovered: -2000),
    Element(atomicNumber: 17, symbol: 'Cl', name: 'Chlorine', atomicMass: 35.45, category: 'Halogen', group: 17, period: 3, electronConfig: '[Ne] 3s² 3p⁵', electronegativity: 3.16, density: 0.003214, meltingPoint: 171.6, boilingPoint: 239.11, yearDiscovered: 1774),
    Element(atomicNumber: 18, symbol: 'Ar', name: 'Argon', atomicMass: 39.948, category: 'Noble Gas', group: 18, period: 3, electronConfig: '[Ne] 3s² 3p⁶', density: 0.0017837, meltingPoint: 83.80, boilingPoint: 87.30, yearDiscovered: 1894),
    Element(atomicNumber: 19, symbol: 'K', name: 'Potassium', atomicMass: 39.098, category: 'Alkali Metal', group: 1, period: 4, electronConfig: '[Ar] 4s¹', electronegativity: 0.82, density: 0.862, meltingPoint: 336.53, boilingPoint: 1032, yearDiscovered: 1807),
    Element(atomicNumber: 20, symbol: 'Ca', name: 'Calcium', atomicMass: 40.078, category: 'Alkaline Earth Metal', group: 2, period: 4, electronConfig: '[Ar] 4s²', electronegativity: 1.00, density: 1.54, meltingPoint: 1115, boilingPoint: 1757, yearDiscovered: 1808),
    Element(atomicNumber: 21, symbol: 'Sc', name: 'Scandium', atomicMass: 44.956, category: 'Transition Metal', group: 3, period: 4, electronConfig: '[Ar] 3d¹ 4s²', electronegativity: 1.36, density: 2.989, meltingPoint: 1814, boilingPoint: 3109, yearDiscovered: 1879),
    Element(atomicNumber: 22, symbol: 'Ti', name: 'Titanium', atomicMass: 47.867, category: 'Transition Metal', group: 4, period: 4, electronConfig: '[Ar] 3d² 4s²', electronegativity: 1.54, density: 4.54, meltingPoint: 1941, boilingPoint: 3560, yearDiscovered: 1791),
    Element(atomicNumber: 23, symbol: 'V', name: 'Vanadium', atomicMass: 50.942, category: 'Transition Metal', group: 5, period: 4, electronConfig: '[Ar] 3d³ 4s²', electronegativity: 1.63, density: 6.11, meltingPoint: 2183, boilingPoint: 3680, yearDiscovered: 1801),
    Element(atomicNumber: 24, symbol: 'Cr', name: 'Chromium', atomicMass: 51.996, category: 'Transition Metal', group: 6, period: 4, electronConfig: '[Ar] 3d⁵ 4s¹', electronegativity: 1.66, density: 7.15, meltingPoint: 2180, boilingPoint: 2944, yearDiscovered: 1794),
    Element(atomicNumber: 25, symbol: 'Mn', name: 'Manganese', atomicMass: 54.938, category: 'Transition Metal', group: 7, period: 4, electronConfig: '[Ar] 3d⁵ 4s²', electronegativity: 1.55, density: 7.44, meltingPoint: 1519, boilingPoint: 2334, yearDiscovered: 1774),
    Element(atomicNumber: 26, symbol: 'Fe', name: 'Iron', atomicMass: 55.845, category: 'Transition Metal', group: 8, period: 4, electronConfig: '[Ar] 3d⁶ 4s²', electronegativity: 1.83, density: 7.874, meltingPoint: 1811, boilingPoint: 3134, yearDiscovered: -5000),
    Element(atomicNumber: 27, symbol: 'Co', name: 'Cobalt', atomicMass: 58.933, category: 'Transition Metal', group: 9, period: 4, electronConfig: '[Ar] 3d⁷ 4s²', electronegativity: 1.88, density: 8.86, meltingPoint: 1768, boilingPoint: 3200, yearDiscovered: 1735),
    Element(atomicNumber: 28, symbol: 'Ni', name: 'Nickel', atomicMass: 58.693, category: 'Transition Metal', group: 10, period: 4, electronConfig: '[Ar] 3d⁸ 4s²', electronegativity: 1.91, density: 8.912, meltingPoint: 1728, boilingPoint: 3186, yearDiscovered: 1751),
    Element(atomicNumber: 29, symbol: 'Cu', name: 'Copper', atomicMass: 63.546, category: 'Transition Metal', group: 11, period: 4, electronConfig: '[Ar] 3d¹⁰ 4s¹', electronegativity: 1.90, density: 8.96, meltingPoint: 1357.77, boilingPoint: 2835, yearDiscovered: -9000),
    Element(atomicNumber: 30, symbol: 'Zn', name: 'Zinc', atomicMass: 65.38, category: 'Transition Metal', group: 12, period: 4, electronConfig: '[Ar] 3d¹⁰ 4s²', electronegativity: 1.65, density: 7.134, meltingPoint: 692.68, boilingPoint: 1180, yearDiscovered: -1000),
    Element(atomicNumber: 31, symbol: 'Ga', name: 'Gallium', atomicMass: 69.723, category: 'Post-Transition Metal', group: 13, period: 4, electronConfig: '[Ar] 3d¹⁰ 4s² 4p¹', electronegativity: 1.81, density: 5.907, meltingPoint: 302.91, boilingPoint: 2477, yearDiscovered: 1875),
    Element(atomicNumber: 32, symbol: 'Ge', name: 'Germanium', atomicMass: 72.63, category: 'Metalloid', group: 14, period: 4, electronConfig: '[Ar] 3d¹⁰ 4s² 4p²', electronegativity: 2.01, density: 5.323, meltingPoint: 1211.40, boilingPoint: 3106, yearDiscovered: 1886),
    Element(atomicNumber: 33, symbol: 'As', name: 'Arsenic', atomicMass: 74.922, category: 'Metalloid', group: 15, period: 4, electronConfig: '[Ar] 3d¹⁰ 4s² 4p³', electronegativity: 2.18, density: 5.776, meltingPoint: 1090, boilingPoint: 887, yearDiscovered: 1250),
    Element(atomicNumber: 34, symbol: 'Se', name: 'Selenium', atomicMass: 78.971, category: 'Nonmetal', group: 16, period: 4, electronConfig: '[Ar] 3d¹⁰ 4s² 4p⁴', electronegativity: 2.55, density: 4.809, meltingPoint: 453, boilingPoint: 958, yearDiscovered: 1817),
    Element(atomicNumber: 35, symbol: 'Br', name: 'Bromine', atomicMass: 79.904, category: 'Halogen', group: 17, period: 4, electronConfig: '[Ar] 3d¹⁰ 4s² 4p⁵', electronegativity: 2.96, density: 3.122, meltingPoint: 265.8, boilingPoint: 332.0, yearDiscovered: 1826),
    Element(atomicNumber: 36, symbol: 'Kr', name: 'Krypton', atomicMass: 83.798, category: 'Noble Gas', group: 18, period: 4, electronConfig: '[Ar] 3d¹⁰ 4s² 4p⁶', density: 0.003733, meltingPoint: 115.79, boilingPoint: 119.93, yearDiscovered: 1898),
    // Period 5
    Element(atomicNumber: 37, symbol: 'Rb', name: 'Rubidium', atomicMass: 85.468, category: 'Alkali Metal', group: 1, period: 5, electronConfig: '[Kr] 5s¹', electronegativity: 0.82, density: 1.532, meltingPoint: 312.46, boilingPoint: 961, yearDiscovered: 1861),
    Element(atomicNumber: 38, symbol: 'Sr', name: 'Strontium', atomicMass: 87.62, category: 'Alkaline Earth Metal', group: 2, period: 5, electronConfig: '[Kr] 5s²', electronegativity: 0.95, density: 2.64, meltingPoint: 1050, boilingPoint: 1655, yearDiscovered: 1790),
    Element(atomicNumber: 39, symbol: 'Y', name: 'Yttrium', atomicMass: 88.906, category: 'Transition Metal', group: 3, period: 5, electronConfig: '[Kr] 4d¹ 5s²', electronegativity: 1.22, density: 4.469, meltingPoint: 1799, boilingPoint: 3609, yearDiscovered: 1794),
    Element(atomicNumber: 40, symbol: 'Zr', name: 'Zirconium', atomicMass: 91.224, category: 'Transition Metal', group: 4, period: 5, electronConfig: '[Kr] 4d² 5s²', electronegativity: 1.33, density: 6.506, meltingPoint: 2128, boilingPoint: 4682, yearDiscovered: 1789),
    Element(atomicNumber: 41, symbol: 'Nb', name: 'Niobium', atomicMass: 92.906, category: 'Transition Metal', group: 5, period: 5, electronConfig: '[Kr] 4d⁴ 5s¹', electronegativity: 1.6, density: 8.57, meltingPoint: 2750, boilingPoint: 5017, yearDiscovered: 1801),
    Element(atomicNumber: 42, symbol: 'Mo', name: 'Molybdenum', atomicMass: 95.95, category: 'Transition Metal', group: 6, period: 5, electronConfig: '[Kr] 4d⁵ 5s¹', electronegativity: 2.16, density: 10.22, meltingPoint: 2896, boilingPoint: 4912, yearDiscovered: 1781),
    Element(atomicNumber: 43, symbol: 'Tc', name: 'Technetium', atomicMass: 98.0, category: 'Transition Metal', group: 7, period: 5, electronConfig: '[Kr] 4d⁵ 5s²', electronegativity: 1.9, density: 11.5, meltingPoint: 2430, boilingPoint: 4538, yearDiscovered: 1937),
    Element(atomicNumber: 44, symbol: 'Ru', name: 'Ruthenium', atomicMass: 101.07, category: 'Transition Metal', group: 8, period: 5, electronConfig: '[Kr] 4d⁷ 5s¹', electronegativity: 2.2, density: 12.37, meltingPoint: 2607, boilingPoint: 4423, yearDiscovered: 1844),
    Element(atomicNumber: 45, symbol: 'Rh', name: 'Rhodium', atomicMass: 102.906, category: 'Transition Metal', group: 9, period: 5, electronConfig: '[Kr] 4d⁸ 5s¹', electronegativity: 2.28, density: 12.41, meltingPoint: 2237, boilingPoint: 3968, yearDiscovered: 1803),
    Element(atomicNumber: 46, symbol: 'Pd', name: 'Palladium', atomicMass: 106.42, category: 'Transition Metal', group: 10, period: 5, electronConfig: '[Kr] 4d¹⁰', electronegativity: 2.20, density: 12.02, meltingPoint: 1828.05, boilingPoint: 3236, yearDiscovered: 1803),
    Element(atomicNumber: 47, symbol: 'Ag', name: 'Silver', atomicMass: 107.868, category: 'Transition Metal', group: 11, period: 5, electronConfig: '[Kr] 4d¹⁰ 5s¹', electronegativity: 1.93, density: 10.501, meltingPoint: 1234.93, boilingPoint: 2435, yearDiscovered: -5000),
    Element(atomicNumber: 48, symbol: 'Cd', name: 'Cadmium', atomicMass: 112.414, category: 'Transition Metal', group: 12, period: 5, electronConfig: '[Kr] 4d¹⁰ 5s²', electronegativity: 1.69, density: 8.69, meltingPoint: 594.22, boilingPoint: 1040, yearDiscovered: 1817),
    Element(atomicNumber: 49, symbol: 'In', name: 'Indium', atomicMass: 114.818, category: 'Post-Transition Metal', group: 13, period: 5, electronConfig: '[Kr] 4d¹⁰ 5s² 5p¹', electronegativity: 1.78, density: 7.31, meltingPoint: 429.75, boilingPoint: 2345, yearDiscovered: 1863),
    Element(atomicNumber: 50, symbol: 'Sn', name: 'Tin', atomicMass: 118.710, category: 'Post-Transition Metal', group: 14, period: 5, electronConfig: '[Kr] 4d¹⁰ 5s² 5p²', electronegativity: 1.96, density: 7.287, meltingPoint: 505.08, boilingPoint: 2875, yearDiscovered: -3500),
    Element(atomicNumber: 51, symbol: 'Sb', name: 'Antimony', atomicMass: 121.760, category: 'Metalloid', group: 15, period: 5, electronConfig: '[Kr] 4d¹⁰ 5s² 5p³', electronegativity: 2.05, density: 6.685, meltingPoint: 903.78, boilingPoint: 1860, yearDiscovered: -3000),
    Element(atomicNumber: 52, symbol: 'Te', name: 'Tellurium', atomicMass: 127.60, category: 'Metalloid', group: 16, period: 5, electronConfig: '[Kr] 4d¹⁰ 5s² 5p⁴', electronegativity: 2.1, density: 6.232, meltingPoint: 722.66, boilingPoint: 1261, yearDiscovered: 1783),
    Element(atomicNumber: 53, symbol: 'I', name: 'Iodine', atomicMass: 126.904, category: 'Halogen', group: 17, period: 5, electronConfig: '[Kr] 4d¹⁰ 5s² 5p⁵', electronegativity: 2.66, density: 4.93, meltingPoint: 386.85, boilingPoint: 457.4, yearDiscovered: 1811),
    Element(atomicNumber: 54, symbol: 'Xe', name: 'Xenon', atomicMass: 131.293, category: 'Noble Gas', group: 18, period: 5, electronConfig: '[Kr] 4d¹⁰ 5s² 5p⁶', density: 0.005887, meltingPoint: 161.4, boilingPoint: 165.03, yearDiscovered: 1898),
    // Period 6
    Element(atomicNumber: 55, symbol: 'Cs', name: 'Caesium', atomicMass: 132.905, category: 'Alkali Metal', group: 1, period: 6, electronConfig: '[Xe] 6s¹', electronegativity: 0.79, density: 1.873, meltingPoint: 301.59, boilingPoint: 944, yearDiscovered: 1860),
    Element(atomicNumber: 56, symbol: 'Ba', name: 'Barium', atomicMass: 137.327, category: 'Alkaline Earth Metal', group: 2, period: 6, electronConfig: '[Xe] 6s²', electronegativity: 0.89, density: 3.594, meltingPoint: 1000, boilingPoint: 2170, yearDiscovered: 1808),
    // Lanthanides (57-71)
    Element(atomicNumber: 57, symbol: 'La', name: 'Lanthanum', atomicMass: 138.905, category: 'Lanthanide', group: 3, period: 6, electronConfig: '[Xe] 5d¹ 6s²', electronegativity: 1.10, density: 6.145, meltingPoint: 1193, boilingPoint: 3737, yearDiscovered: 1839),
    Element(atomicNumber: 58, symbol: 'Ce', name: 'Cerium', atomicMass: 140.116, category: 'Lanthanide', group: 3, period: 6, electronConfig: '[Xe] 4f¹ 5d¹ 6s²', electronegativity: 1.12, density: 6.77, meltingPoint: 1068, boilingPoint: 3716, yearDiscovered: 1803),
    Element(atomicNumber: 59, symbol: 'Pr', name: 'Praseodymium', atomicMass: 140.908, category: 'Lanthanide', group: 3, period: 6, electronConfig: '[Xe] 4f³ 6s²', electronegativity: 1.13, density: 6.773, meltingPoint: 1208, boilingPoint: 3793, yearDiscovered: 1885),
    Element(atomicNumber: 60, symbol: 'Nd', name: 'Neodymium', atomicMass: 144.242, category: 'Lanthanide', group: 3, period: 6, electronConfig: '[Xe] 4f⁴ 6s²', electronegativity: 1.14, density: 7.007, meltingPoint: 1297, boilingPoint: 3347, yearDiscovered: 1885),
    Element(atomicNumber: 61, symbol: 'Pm', name: 'Promethium', atomicMass: 145.0, category: 'Lanthanide', group: 3, period: 6, electronConfig: '[Xe] 4f⁵ 6s²', electronegativity: 1.13, density: 7.26, meltingPoint: 1315, boilingPoint: 3273, yearDiscovered: 1945),
    Element(atomicNumber: 62, symbol: 'Sm', name: 'Samarium', atomicMass: 150.36, category: 'Lanthanide', group: 3, period: 6, electronConfig: '[Xe] 4f⁶ 6s²', electronegativity: 1.17, density: 7.52, meltingPoint: 1345, boilingPoint: 2067, yearDiscovered: 1879),
    Element(atomicNumber: 63, symbol: 'Eu', name: 'Europium', atomicMass: 151.964, category: 'Lanthanide', group: 3, period: 6, electronConfig: '[Xe] 4f⁷ 6s²', electronegativity: 1.2, density: 5.243, meltingPoint: 1099, boilingPoint: 1802, yearDiscovered: 1901),
    Element(atomicNumber: 64, symbol: 'Gd', name: 'Gadolinium', atomicMass: 157.25, category: 'Lanthanide', group: 3, period: 6, electronConfig: '[Xe] 4f⁷ 5d¹ 6s²', electronegativity: 1.20, density: 7.895, meltingPoint: 1585, boilingPoint: 3546, yearDiscovered: 1880),
    Element(atomicNumber: 65, symbol: 'Tb', name: 'Terbium', atomicMass: 158.925, category: 'Lanthanide', group: 3, period: 6, electronConfig: '[Xe] 4f⁹ 6s²', electronegativity: 1.2, density: 8.229, meltingPoint: 1629, boilingPoint: 3503, yearDiscovered: 1843),
    Element(atomicNumber: 66, symbol: 'Dy', name: 'Dysprosium', atomicMass: 162.500, category: 'Lanthanide', group: 3, period: 6, electronConfig: '[Xe] 4f¹⁰ 6s²', electronegativity: 1.22, density: 8.55, meltingPoint: 1680, boilingPoint: 2840, yearDiscovered: 1886),
    Element(atomicNumber: 67, symbol: 'Ho', name: 'Holmium', atomicMass: 164.930, category: 'Lanthanide', group: 3, period: 6, electronConfig: '[Xe] 4f¹¹ 6s²', electronegativity: 1.23, density: 8.795, meltingPoint: 1734, boilingPoint: 2993, yearDiscovered: 1878),
    Element(atomicNumber: 68, symbol: 'Er', name: 'Erbium', atomicMass: 167.259, category: 'Lanthanide', group: 3, period: 6, electronConfig: '[Xe] 4f¹² 6s²', electronegativity: 1.24, density: 9.066, meltingPoint: 1802, boilingPoint: 3141, yearDiscovered: 1843),
    Element(atomicNumber: 69, symbol: 'Tm', name: 'Thulium', atomicMass: 168.934, category: 'Lanthanide', group: 3, period: 6, electronConfig: '[Xe] 4f¹³ 6s²', electronegativity: 1.25, density: 9.321, meltingPoint: 1818, boilingPoint: 2223, yearDiscovered: 1879),
    Element(atomicNumber: 70, symbol: 'Yb', name: 'Ytterbium', atomicMass: 173.045, category: 'Lanthanide', group: 3, period: 6, electronConfig: '[Xe] 4f¹⁴ 6s²', electronegativity: 1.1, density: 6.965, meltingPoint: 1097, boilingPoint: 1469, yearDiscovered: 1878),
    Element(atomicNumber: 71, symbol: 'Lu', name: 'Lutetium', atomicMass: 174.967, category: 'Lanthanide', group: 3, period: 6, electronConfig: '[Xe] 4f¹⁴ 5d¹ 6s²', electronegativity: 1.27, density: 9.84, meltingPoint: 1925, boilingPoint: 3675, yearDiscovered: 1907),
    Element(atomicNumber: 72, symbol: 'Hf', name: 'Hafnium', atomicMass: 178.49, category: 'Transition Metal', group: 4, period: 6, electronConfig: '[Xe] 4f¹⁴ 5d² 6s²', electronegativity: 1.3, density: 13.31, meltingPoint: 2506, boilingPoint: 4876, yearDiscovered: 1923),
    Element(atomicNumber: 73, symbol: 'Ta', name: 'Tantalum', atomicMass: 180.948, category: 'Transition Metal', group: 5, period: 6, electronConfig: '[Xe] 4f¹⁴ 5d³ 6s²', electronegativity: 1.5, density: 16.654, meltingPoint: 3290, boilingPoint: 5731, yearDiscovered: 1802),
    Element(atomicNumber: 74, symbol: 'W', name: 'Tungsten', atomicMass: 183.84, category: 'Transition Metal', group: 6, period: 6, electronConfig: '[Xe] 4f¹⁴ 5d⁴ 6s²', electronegativity: 2.36, density: 19.25, meltingPoint: 3695, boilingPoint: 5828, yearDiscovered: 1783),
    Element(atomicNumber: 75, symbol: 'Re', name: 'Rhenium', atomicMass: 186.207, category: 'Transition Metal', group: 7, period: 6, electronConfig: '[Xe] 4f¹⁴ 5d⁵ 6s²', electronegativity: 1.9, density: 21.02, meltingPoint: 3459, boilingPoint: 5869, yearDiscovered: 1925),
    Element(atomicNumber: 76, symbol: 'Os', name: 'Osmium', atomicMass: 190.23, category: 'Transition Metal', group: 8, period: 6, electronConfig: '[Xe] 4f¹⁴ 5d⁶ 6s²', electronegativity: 2.2, density: 22.587, meltingPoint: 3306, boilingPoint: 5285, yearDiscovered: 1803),
    Element(atomicNumber: 77, symbol: 'Ir', name: 'Iridium', atomicMass: 192.217, category: 'Transition Metal', group: 9, period: 6, electronConfig: '[Xe] 4f¹⁴ 5d⁷ 6s²', electronegativity: 2.20, density: 22.56, meltingPoint: 2719, boilingPoint: 4701, yearDiscovered: 1803),
    Element(atomicNumber: 78, symbol: 'Pt', name: 'Platinum', atomicMass: 195.084, category: 'Transition Metal', group: 10, period: 6, electronConfig: '[Xe] 4f¹⁴ 5d⁹ 6s¹', electronegativity: 2.28, density: 21.46, meltingPoint: 2041.4, boilingPoint: 4098, yearDiscovered: 1735),
    Element(atomicNumber: 79, symbol: 'Au', name: 'Gold', atomicMass: 196.967, category: 'Transition Metal', group: 11, period: 6, electronConfig: '[Xe] 4f¹⁴ 5d¹⁰ 6s¹', electronegativity: 2.54, density: 19.282, meltingPoint: 1337.33, boilingPoint: 3129, yearDiscovered: -6000),
    Element(atomicNumber: 80, symbol: 'Hg', name: 'Mercury', atomicMass: 200.592, category: 'Transition Metal', group: 12, period: 6, electronConfig: '[Xe] 4f¹⁴ 5d¹⁰ 6s²', electronegativity: 2.00, density: 13.5336, meltingPoint: 234.43, boilingPoint: 629.88, yearDiscovered: -1500),
    Element(atomicNumber: 81, symbol: 'Tl', name: 'Thallium', atomicMass: 204.38, category: 'Post-Transition Metal', group: 13, period: 6, electronConfig: '[Xe] 4f¹⁴ 5d¹⁰ 6s² 6p¹', electronegativity: 1.62, density: 11.85, meltingPoint: 577, boilingPoint: 1746, yearDiscovered: 1861),
    Element(atomicNumber: 82, symbol: 'Pb', name: 'Lead', atomicMass: 207.2, category: 'Post-Transition Metal', group: 14, period: 6, electronConfig: '[Xe] 4f¹⁴ 5d¹⁰ 6s² 6p²', electronegativity: 1.87, density: 11.342, meltingPoint: 600.61, boilingPoint: 2022, yearDiscovered: -7000),
    Element(atomicNumber: 83, symbol: 'Bi', name: 'Bismuth', atomicMass: 208.980, category: 'Post-Transition Metal', group: 15, period: 6, electronConfig: '[Xe] 4f¹⁴ 5d¹⁰ 6s² 6p³', electronegativity: 2.02, density: 9.807, meltingPoint: 544.7, boilingPoint: 1837, yearDiscovered: 1753),
    Element(atomicNumber: 84, symbol: 'Po', name: 'Polonium', atomicMass: 209.0, category: 'Post-Transition Metal', group: 16, period: 6, electronConfig: '[Xe] 4f¹⁴ 5d¹⁰ 6s² 6p⁴', electronegativity: 2.0, density: 9.32, meltingPoint: 527, boilingPoint: 1235, yearDiscovered: 1898),
    Element(atomicNumber: 85, symbol: 'At', name: 'Astatine', atomicMass: 210.0, category: 'Halogen', group: 17, period: 6, electronConfig: '[Xe] 4f¹⁴ 5d¹⁰ 6s² 6p⁵', electronegativity: 2.2, density: 7.0, meltingPoint: 575, boilingPoint: 610, yearDiscovered: 1940),
    Element(atomicNumber: 86, symbol: 'Rn', name: 'Radon', atomicMass: 222.0, category: 'Noble Gas', group: 18, period: 6, electronConfig: '[Xe] 4f¹⁴ 5d¹⁰ 6s² 6p⁶', density: 0.00973, meltingPoint: 202, boilingPoint: 211.3, yearDiscovered: 1900),
    // Period 7
    Element(atomicNumber: 87, symbol: 'Fr', name: 'Francium', atomicMass: 223.0, category: 'Alkali Metal', group: 1, period: 7, electronConfig: '[Rn] 7s¹', electronegativity: 0.7, density: 1.87, meltingPoint: 300, boilingPoint: 950, yearDiscovered: 1939),
    Element(atomicNumber: 88, symbol: 'Ra', name: 'Radium', atomicMass: 226.0, category: 'Alkaline Earth Metal', group: 2, period: 7, electronConfig: '[Rn] 7s²', electronegativity: 0.9, density: 5.5, meltingPoint: 973, boilingPoint: 2010, yearDiscovered: 1898),
    // Actinides (89-103)
    Element(atomicNumber: 89, symbol: 'Ac', name: 'Actinium', atomicMass: 227.0, category: 'Actinide', group: 3, period: 7, electronConfig: '[Rn] 6d¹ 7s²', electronegativity: 1.1, density: 10.07, meltingPoint: 1323, boilingPoint: 3471, yearDiscovered: 1899),
    Element(atomicNumber: 90, symbol: 'Th', name: 'Thorium', atomicMass: 232.038, category: 'Actinide', group: 3, period: 7, electronConfig: '[Rn] 6d² 7s²', electronegativity: 1.3, density: 11.72, meltingPoint: 2115, boilingPoint: 5061, yearDiscovered: 1829),
    Element(atomicNumber: 91, symbol: 'Pa', name: 'Protactinium', atomicMass: 231.036, category: 'Actinide', group: 3, period: 7, electronConfig: '[Rn] 5f² 6d¹ 7s²', electronegativity: 1.5, density: 15.37, meltingPoint: 1841, boilingPoint: 4300, yearDiscovered: 1913),
    Element(atomicNumber: 92, symbol: 'U', name: 'Uranium', atomicMass: 238.029, category: 'Actinide', group: 3, period: 7, electronConfig: '[Rn] 5f³ 6d¹ 7s²', electronegativity: 1.38, density: 18.95, meltingPoint: 1405.3, boilingPoint: 4404, yearDiscovered: 1789),
    Element(atomicNumber: 93, symbol: 'Np', name: 'Neptunium', atomicMass: 237.0, category: 'Actinide', group: 3, period: 7, electronConfig: '[Rn] 5f⁴ 6d¹ 7s²', electronegativity: 1.36, density: 20.45, meltingPoint: 917, boilingPoint: 4273, yearDiscovered: 1940),
    Element(atomicNumber: 94, symbol: 'Pu', name: 'Plutonium', atomicMass: 244.0, category: 'Actinide', group: 3, period: 7, electronConfig: '[Rn] 5f⁶ 7s²', electronegativity: 1.28, density: 19.84, meltingPoint: 912.5, boilingPoint: 3501, yearDiscovered: 1940),
    Element(atomicNumber: 95, symbol: 'Am', name: 'Americium', atomicMass: 243.0, category: 'Actinide', group: 3, period: 7, electronConfig: '[Rn] 5f⁷ 7s²', electronegativity: 1.3, density: 13.69, meltingPoint: 1449, boilingPoint: 2880, yearDiscovered: 1944),
    Element(atomicNumber: 96, symbol: 'Cm', name: 'Curium', atomicMass: 247.0, category: 'Actinide', group: 3, period: 7, electronConfig: '[Rn] 5f⁷ 6d¹ 7s²', electronegativity: 1.3, density: 13.51, meltingPoint: 1613, boilingPoint: 3383, yearDiscovered: 1944),
    Element(atomicNumber: 97, symbol: 'Bk', name: 'Berkelium', atomicMass: 247.0, category: 'Actinide', group: 3, period: 7, electronConfig: '[Rn] 5f⁹ 7s²', electronegativity: 1.3, density: 14.79, meltingPoint: 1259, boilingPoint: 2900, yearDiscovered: 1949),
    Element(atomicNumber: 98, symbol: 'Cf', name: 'Californium', atomicMass: 251.0, category: 'Actinide', group: 3, period: 7, electronConfig: '[Rn] 5f¹⁰ 7s²', electronegativity: 1.3, density: 15.1, meltingPoint: 1173, boilingPoint: 1743, yearDiscovered: 1950),
    Element(atomicNumber: 99, symbol: 'Es', name: 'Einsteinium', atomicMass: 252.0, category: 'Actinide', group: 3, period: 7, electronConfig: '[Rn] 5f¹¹ 7s²', electronegativity: 1.3, density: 8.84, meltingPoint: 1133, yearDiscovered: 1952),
    Element(atomicNumber: 100, symbol: 'Fm', name: 'Fermium', atomicMass: 257.0, category: 'Actinide', group: 3, period: 7, electronConfig: '[Rn] 5f¹² 7s²', electronegativity: 1.3, meltingPoint: 1800, yearDiscovered: 1952),
    Element(atomicNumber: 101, symbol: 'Md', name: 'Mendelevium', atomicMass: 258.0, category: 'Actinide', group: 3, period: 7, electronConfig: '[Rn] 5f¹³ 7s²', electronegativity: 1.3, meltingPoint: 1100, yearDiscovered: 1955),
    Element(atomicNumber: 102, symbol: 'No', name: 'Nobelium', atomicMass: 259.0, category: 'Actinide', group: 3, period: 7, electronConfig: '[Rn] 5f¹⁴ 7s²', electronegativity: 1.3, meltingPoint: 1100, yearDiscovered: 1958),
    Element(atomicNumber: 103, symbol: 'Lr', name: 'Lawrencium', atomicMass: 266.0, category: 'Actinide', group: 3, period: 7, electronConfig: '[Rn] 5f¹⁴ 7s² 7p¹', electronegativity: 1.3, meltingPoint: 1900, yearDiscovered: 1961),
    Element(atomicNumber: 104, symbol: 'Rf', name: 'Rutherfordium', atomicMass: 267.0, category: 'Transition Metal', group: 4, period: 7, electronConfig: '[Rn] 5f¹⁴ 6d² 7s²', density: 23.2, yearDiscovered: 1964),
    Element(atomicNumber: 105, symbol: 'Db', name: 'Dubnium', atomicMass: 268.0, category: 'Transition Metal', group: 5, period: 7, electronConfig: '[Rn] 5f¹⁴ 6d³ 7s²', density: 29.3, yearDiscovered: 1967),
    Element(atomicNumber: 106, symbol: 'Sg', name: 'Seaborgium', atomicMass: 269.0, category: 'Transition Metal', group: 6, period: 7, electronConfig: '[Rn] 5f¹⁴ 6d⁴ 7s²', density: 35.0, yearDiscovered: 1974),
    Element(atomicNumber: 107, symbol: 'Bh', name: 'Bohrium', atomicMass: 270.0, category: 'Transition Metal', group: 7, period: 7, electronConfig: '[Rn] 5f¹⁴ 6d⁵ 7s²', density: 37.1, yearDiscovered: 1981),
    Element(atomicNumber: 108, symbol: 'Hs', name: 'Hassium', atomicMass: 277.0, category: 'Transition Metal', group: 8, period: 7, electronConfig: '[Rn] 5f¹⁴ 6d⁶ 7s²', density: 40.7, yearDiscovered: 1984),
    Element(atomicNumber: 109, symbol: 'Mt', name: 'Meitnerium', atomicMass: 278.0, category: 'Transition Metal', group: 9, period: 7, electronConfig: '[Rn] 5f¹⁴ 6d⁷ 7s²', density: 37.4, yearDiscovered: 1982),
    Element(atomicNumber: 110, symbol: 'Ds', name: 'Darmstadtium', atomicMass: 281.0, category: 'Transition Metal', group: 10, period: 7, electronConfig: '[Rn] 5f¹⁴ 6d⁸ 7s²', density: 34.8, yearDiscovered: 1994),
    Element(atomicNumber: 111, symbol: 'Rg', name: 'Roentgenium', atomicMass: 282.0, category: 'Transition Metal', group: 11, period: 7, electronConfig: '[Rn] 5f¹⁴ 6d⁹ 7s²', density: 28.7, yearDiscovered: 1994),
    Element(atomicNumber: 112, symbol: 'Cn', name: 'Copernicium', atomicMass: 285.0, category: 'Transition Metal', group: 12, period: 7, electronConfig: '[Rn] 5f¹⁴ 6d¹⁰ 7s²', density: 23.7, yearDiscovered: 1996),
    Element(atomicNumber: 113, symbol: 'Nh', name: 'Nihonium', atomicMass: 286.0, category: 'Post-Transition Metal', group: 13, period: 7, electronConfig: '[Rn] 5f¹⁴ 6d¹⁰ 7s² 7p¹', yearDiscovered: 2003),
    Element(atomicNumber: 114, symbol: 'Fl', name: 'Flerovium', atomicMass: 289.0, category: 'Post-Transition Metal', group: 14, period: 7, electronConfig: '[Rn] 5f¹⁴ 6d¹⁰ 7s² 7p²', yearDiscovered: 1998),
    Element(atomicNumber: 115, symbol: 'Mc', name: 'Moscovium', atomicMass: 290.0, category: 'Post-Transition Metal', group: 15, period: 7, electronConfig: '[Rn] 5f¹⁴ 6d¹⁰ 7s² 7p³', yearDiscovered: 2003),
    Element(atomicNumber: 116, symbol: 'Lv', name: 'Livermorium', atomicMass: 293.0, category: 'Post-Transition Metal', group: 16, period: 7, electronConfig: '[Rn] 5f¹⁴ 6d¹⁰ 7s² 7p⁴', yearDiscovered: 2000),
    Element(atomicNumber: 117, symbol: 'Ts', name: 'Tennessine', atomicMass: 294.0, category: 'Halogen', group: 17, period: 7, electronConfig: '[Rn] 5f¹⁴ 6d¹⁰ 7s² 7p⁵', yearDiscovered: 2010),
    Element(atomicNumber: 118, symbol: 'Og', name: 'Oganesson', atomicMass: 294.0, category: 'Noble Gas', group: 18, period: 7, electronConfig: '[Rn] 5f¹⁴ 6d¹⁰ 7s² 7p⁶', yearDiscovered: 2002),
  ];
}
