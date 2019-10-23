import 'package:flutter_test/flutter_test.dart';

import 'package:geodetic_converter/geodetic_converter.dart';
import 'package:geodetic_converter/src/geodetic_point.dart';

void main() {
  test('adds one to input values', () {
    final geodeticConverter = GeodeticConverter();
    // 서울 시청
    final seoulCityHallLatLng = GeodeticPoint(x: 37.5666805, y: 126.9784147);
    final seoulCityHallPoint = geodeticConverter.wgs84ToTM(x: seoulCityHallLatLng.x, y: seoulCityHallLatLng.y);

    // 중구 정동 5-1 (덕수궁내)
    final deoksugungPoint = GeodeticPoint(x: 197868, y: 451606);
    final deoksugungLatLnt = geodeticConverter.tmToWgs84(x: deoksugungPoint.x, y: deoksugungPoint.y);

    // 동작구 사당 4동 300-8
    final sadangPoint = GeodeticPoint(x: 197670, y: 443050);
    final sadangLatLnt = geodeticConverter.tmToWgs84(point: sadangPoint);

    // 검증
    final recoverySeoulCityHallLatLng = geodeticConverter.tmToWgs84(x: seoulCityHallPoint.x, y: seoulCityHallPoint.y);
    final recoveryDeoksugungPoint = geodeticConverter.wgs84ToTM(x: deoksugungLatLnt.x, y: deoksugungLatLnt.y);
    final recoverySadangPoint = geodeticConverter.wgs84ToTM(point: sadangLatLnt);

    // 결과
    print("${seoulCityHallLatLng.toShortString()} -> ${seoulCityHallPoint.toShortString()} -> ${recoverySeoulCityHallLatLng.toShortString()}");
    print("${deoksugungPoint.toShortString()} -> ${deoksugungLatLnt.toShortString()} -> ${recoveryDeoksugungPoint.toShortString()}");
    print("${sadangPoint.toShortString()} -> ${sadangLatLnt.toShortString()} -> ${recoverySadangPoint.toShortString()}");

//    expect(() => calculator.addOne(null), throwsNoSuchMethodError);
  });
}
