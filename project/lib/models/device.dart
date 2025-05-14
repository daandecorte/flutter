

class Device {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final String image;
  final String user;
  final double lat;
  final double long;
  final String locationStringFull;
  final String locationStringShort;

  Device({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.image,
    required this.user,
    required this.lat,
    required this.long,
    required this.locationStringFull,
    required this.locationStringShort
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'price': price,
        'category': category,
        'image': image,
        'user': user,
        'lat': lat,
        'long': long,
        'locationStringFull': locationStringFull,
        'locationStringShort': locationStringShort
      };

  factory Device.fromMap(String id, Map<String, dynamic> map) {
    return Device(
      id: id,
      name: map['name'],
      description: map['description'],
      price: (map['price'] as num).toDouble(),
      category: map['category'],
      image: map['image'],
      user: map['user'],
      lat: map['lat'],
      long: map['long'],
      locationStringFull: map['locationStringFull'],
      locationStringShort: map['locationStringShort']
    );
  }
}
