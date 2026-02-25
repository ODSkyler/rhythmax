enum JioSaavnQuality {
  low,     // 48 kbps
  normal,  // 96 kbps (default)
  high,    // 160 kbps
  max,     // 320 kbps
}
const Map<JioSaavnQuality, String> _qualityLabel = {
  JioSaavnQuality.low: 'Low',
  JioSaavnQuality.normal: 'Normal',
  JioSaavnQuality.high: 'High',
  JioSaavnQuality.max: 'MAX',
};
