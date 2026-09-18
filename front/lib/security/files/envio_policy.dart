class EnvioPolicy {
  const EnvioPolicy._();

  // The backend accepts files strictly smaller than 250 MiB.
  static const maxMegabytes = 250;
  static const maxBytes = maxMegabytes * 1024 * 1024;

  static bool permiteTamanho(int bytes) => bytes > 0 && bytes < maxBytes;
}
