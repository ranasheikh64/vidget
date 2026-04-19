class VaultFile {
  final String name;
  final String size;
  final String thumb;
  final String path;
  final bool isEncrypted;

  VaultFile({
    required this.name,
    required this.size,
    required this.thumb,
    required this.path,
    this.isEncrypted = true,
  });
}
