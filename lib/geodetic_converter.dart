library geodetic_converter;

import 'package:geodetic_converter/src/geodetic_converter_library.dart';
import 'package:geodetic_converter/src/geodetic_point.dart';
import 'package:geodetic_converter/src/geodetic_type.dart';


class GeodeticConverter {
  GeodeticConverterLibrary _geodeticConverterLibrary = GeodeticConverterLibrary();

  GeodeticPoint tmToWgs84({double x, double y, GeodeticPoint point}) {
    if (point != null) { x = point.x; y = point.y; }
    final wgs84Point = _geodeticConverterLibrary.run(srcType: GeodeticType.TM_N, dstType: GeodeticType.WGS84, inputPoint: GeodeticPoint(x: x, y: y));
    return GeodeticPoint(x: wgs84Point.y, y: wgs84Point.x, z: wgs84Point.z);
  }
  GeodeticPoint wgs84ToTM({double x, double y, GeodeticPoint point}) {
    if (point != null) { x = point.x; y = point.y; }
    final katecPoint = _geodeticConverterLibrary.run(srcType: GeodeticType.WGS84, dstType: GeodeticType.KATEC, inputPoint: GeodeticPoint(x: y, y: x));
    return _geodeticConverterLibrary.run(srcType: GeodeticType.KATEC, dstType: GeodeticType.TM_N, inputPoint: katecPoint);
  }
}
