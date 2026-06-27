class AppUpdate {
  const AppUpdate({
    required this.version,
    required this.releaseUrl,
    required this.downloadUrl,
    required this.notes,
    required this.mandatory,
  });

  final String version;
  final Uri releaseUrl;
  final Uri downloadUrl;
  final String notes;
  final bool mandatory;
}
