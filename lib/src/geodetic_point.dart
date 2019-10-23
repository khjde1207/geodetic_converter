class GeodeticPoint {
  GeodeticPoint({this.x, this.y, this.z = 0.0});

  double x;
  double y;
  double z;

  clone() => new GeodeticPoint(x: x, y: y, z: z);

  toString() => "x=$x, y=$y";

  toShortString() => "$x, $y";
}
