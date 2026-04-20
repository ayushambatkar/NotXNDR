class TransferFileEntity {
  final String id;
  final String name;
  final int size;
  final String hash;
  final String? localPath;
  final String? url;
  final String? objectPath;

  const TransferFileEntity({
    required this.id,
    required this.name,
    required this.size,
    required this.hash,
    this.localPath,
    this.url,
    this.objectPath,
  });
}
