/// Service for IPv4 subnet calculations.
class SubnetCalculatorService {
  SubnetCalculatorService._();

  /// Common CIDR prefix lengths with labels.
  static const Map<int, String> commonPrefixes = {
    8: '/8  — Class A (16M hosts)',
    16: '/16 — Class B (65K hosts)',
    24: '/24 — Class C (254 hosts)',
    25: '/25 — 126 hosts',
    26: '/26 — 62 hosts',
    27: '/27 — 30 hosts',
    28: '/28 — 14 hosts',
    29: '/29 — 6 hosts',
    30: '/30 — 2 hosts (point-to-point)',
    31: '/31 — 2 addresses (RFC 3021)',
    32: '/32 — single host',
  };

  /// Parse an IPv4 address string to a 32-bit integer.
  static int? parseIp(String input) {
    final parts = input.trim().split('.');
    if (parts.length != 4) return null;
    int result = 0;
    for (final p in parts) {
      final v = int.tryParse(p);
      if (v == null || v < 0 || v > 255) return null;
      result = (result << 8) | v;
    }
    return result;
  }

  /// Format a 32-bit integer as dotted-quad.
  static String formatIp(int ip) {
    return '${(ip >> 24) & 0xFF}.${(ip >> 16) & 0xFF}.${(ip >> 8) & 0xFF}.${ip & 0xFF}';
  }

  /// Convert a prefix length (0-32) to a subnet mask integer.
  static int prefixToMask(int prefix) {
    if (prefix <= 0) return 0;
    if (prefix >= 32) return 0xFFFFFFFF;
    return (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF;
  }

  /// Convert a subnet mask integer to prefix length, or null if invalid.
  static int? maskToPrefix(int mask) {
    // Validate it's a contiguous mask
    int prefix = 0;
    bool seenZero = false;
    for (int i = 31; i >= 0; i--) {
      final bit = (mask >> i) & 1;
      if (bit == 1) {
        if (seenZero) return null; // non-contiguous
        prefix++;
      } else {
        seenZero = true;
      }
    }
    return prefix;
  }

  /// Calculate full subnet details from IP + prefix length.
  static SubnetResult? calculate(String ipStr, int prefix) {
    final ip = parseIp(ipStr);
    if (ip == null || prefix < 0 || prefix > 32) return null;

    final mask = prefixToMask(prefix);
    final network = ip & mask;
    final broadcast = network | (~mask & 0xFFFFFFFF);
    final totalAddresses = 1 << (32 - prefix);
    final usableHosts = prefix >= 31 ? totalAddresses : totalAddresses - 2;
    final firstHost = prefix >= 31 ? network : network + 1;
    final lastHost = prefix >= 31 ? broadcast : broadcast - 1;
    final wildcardMask = ~mask & 0xFFFFFFFF;

    // Determine class
    String ipClass;
    final firstOctet = (ip >> 24) & 0xFF;
    if (firstOctet < 128) {
      ipClass = 'A';
    } else if (firstOctet < 192) {
      ipClass = 'B';
    } else if (firstOctet < 224) {
      ipClass = 'C';
    } else if (firstOctet < 240) {
      ipClass = 'D (Multicast)';
    } else {
      ipClass = 'E (Reserved)';
    }

    // Check if private
    bool isPrivate = false;
    if ((ip & 0xFF000000) == 0x0A000000) {
      isPrivate = true; // 10.0.0.0/8
    } else if ((ip & 0xFFF00000) == 0xAC100000) {
      isPrivate = true; // 172.16.0.0/12
    } else if ((ip & 0xFFFF0000) == 0xC0A80000) {
      isPrivate = true; // 192.168.0.0/16
    }

    return SubnetResult(
      ipAddress: formatIp(ip),
      networkAddress: formatIp(network),
      broadcastAddress: formatIp(broadcast),
      subnetMask: formatIp(mask),
      wildcardMask: formatIp(wildcardMask),
      prefix: prefix,
      totalAddresses: totalAddresses,
      usableHosts: usableHosts < 0 ? 0 : usableHosts,
      firstHost: formatIp(firstHost),
      lastHost: formatIp(lastHost),
      ipClass: ipClass,
      isPrivate: isPrivate,
      binaryMask: mask
          .toRadixString(2)
          .padLeft(32, '0')
          .replaceAllMapped(RegExp(r'.{8}'), (m) => '${m[0]} ')
          .trim(),
    );
  }

  /// Split a network into N equal subnets.
  static List<SubnetResult> subdivide(String ipStr, int prefix, int count) {
    if (count < 2 || prefix >= 30) return [];
    // Find how many extra bits needed
    int extraBits = 0;
    int subnets = 1;
    while (subnets < count) {
      extraBits++;
      subnets *= 2;
    }
    final newPrefix = prefix + extraBits;
    if (newPrefix > 30) return [];

    final ip = parseIp(ipStr);
    if (ip == null) return [];
    final mask = prefixToMask(prefix);
    final network = ip & mask;

    final results = <SubnetResult>[];
    final subnetSize = 1 << (32 - newPrefix);
    for (int i = 0; i < subnets && i < 256; i++) {
      final subNet = network + (i * subnetSize);
      final r = calculate(formatIp(subNet), newPrefix);
      if (r != null) results.add(r);
    }
    return results;
  }
}

class SubnetResult {
  final String ipAddress;
  final String networkAddress;
  final String broadcastAddress;
  final String subnetMask;
  final String wildcardMask;
  final int prefix;
  final int totalAddresses;
  final int usableHosts;
  final String firstHost;
  final String lastHost;
  final String ipClass;
  final bool isPrivate;
  final String binaryMask;

  const SubnetResult({
    required this.ipAddress,
    required this.networkAddress,
    required this.broadcastAddress,
    required this.subnetMask,
    required this.wildcardMask,
    required this.prefix,
    required this.totalAddresses,
    required this.usableHosts,
    required this.firstHost,
    required this.lastHost,
    required this.ipClass,
    required this.isPrivate,
    required this.binaryMask,
  });
}
