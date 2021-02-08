class IntelliPot {
  final int id;
  final String deviceID;
  String imagePath;
  String name;
  String lastWater;
  String mode;
  String plantSpecies;
  int waterPeriod; // In days
  int humidityThreshold;
  // Sensor data variables
  int temperature = 0;
  int airHumidity = 0;
  double soilMoisture = 0;
  bool recievingLight = false;

  IntelliPot(
      {this.id,
      this.deviceID,
      this.name,
      this.imagePath,
      this.lastWater,
      this.plantSpecies,
      this.mode,
      this.waterPeriod,
      this.humidityThreshold});

  factory IntelliPot.fromJson(Map<String, dynamic> json) {
    return IntelliPot(
      id: json['id'],
      deviceID: json['deviceID'],
      name: json['deviceName'],
      imagePath: json['imagePath'],
      lastWater: json['lastWater'],
      plantSpecies: json['plantSpecies'],
      mode: json['mode'],
      waterPeriod: json['waterPeriod'],
      humidityThreshold: json['humidityThreshold'],
    );
  }
}
