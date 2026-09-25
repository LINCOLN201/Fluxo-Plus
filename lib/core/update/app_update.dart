class AppUpdate {
  const AppUpdate({
    required this.version,
    required this.releaseUrl,
    required this.downloadUrl,
    required this.notes,
    required this.mandatory,
    this.checksumUrl,
  });

  final String version;
  final Uri releaseUrl;
  final Uri downloadUrl;
  final String notes;
  final bool mandatory;

  /// Arquivo `.sha256` publicado junto com o instalador, quando existe.
  final Uri? checksumUrl;
}
