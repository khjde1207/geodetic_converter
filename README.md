# geodetic_converter
[![Codemagic build status](https://api.codemagic.io/apps/5daf0f5dbea20b0018036c22/5daf0f5dbea20b0018036c21/status_badge.svg)](https://codemagic.io/apps/5daf0f5dbea20b0018036c22/5daf0f5dbea20b0018036c21/latest_build)

전 세계적으로 좌표계는 너무 다양합니다.
특히 개발을 위해서는 변환하는 라이브러리가 필수입니다.

구글은 WGS84 좌표계를 사용하고,
기타 한국에서는 TM, KETEC 등의 좌표계를 사용합니다.

이를 극복하기 위해 많은 라이브러리가 있습니다.
대표적으로 JS 에는 Proj4js 가 있습니다.

Flutter 에는 UTM <-> WGS84 라이브러리가 있더군요.
하지만, TM 좌표계가 필요한 분들을 위해 다시 만들었습니다.

소스는 창작보다는 포팅위주의 코드입니다.
기타 버그 및 오류는 일부 수정하였지만, 사용하시는 여러분들의 도움이 필요합니다.

장기적으로 사용자가 많아지면, Proj4js.js 를 포팅하는 방향으로 진행하려 합니다.
감사합니다. 

## Example

```dart
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
```

## References

도움이 많이 된 글의 원본을 남깁니다. 원작자 분들에게 감사의 말을 전하고 싶네요.

- [도움이 된 글 1](https://www.androidpub.com/1318647)
- [도움이 된 글 2](http://www.androidpub.com/1043970)
- [도움이 된 글 3](https://writefoot.tistory.com/entry/MapView-%EA%B2%BD%EC%9C%84%EB%8F%84-tm-%EC%B9%B4%ED%85%8D-%EB%B3%80%ED%99%98-%EC%95%8C%EA%B3%A0%EB%A6%AC%EC%A6%98)
