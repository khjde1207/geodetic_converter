import 'dart:math';

import 'package:geodetic_converter/src/geodetic_point.dart';
import 'package:geodetic_converter/src/geodetic_type.dart';

///
/// @author Eugene
///
/// The code based on hyosang(http://hyosang.kr/tc/96) and aero's blog ((http://aero.sarang.net/map/analysis.html)
/// License:  LGPL : http://www.gnu.org/copyleft/lesser.html
///

class GeodeticConverterLibrary {
  static const EPSLN = 0.0000000001;

  final _datumParams = GeodeticPoint(x: -146.43, y: 507.89, z: 681.46);

  final _scaleFactor = {
    GeodeticType.WGS84: 1.0,
    GeodeticType.KATEC: 0.9996,
    GeodeticType.TM_N: 1.0,
  };

  final _majorMap = {
    GeodeticType.WGS84: 6378137.0,
    GeodeticType.KATEC: 6377397.155,
    GeodeticType.TM_N: 6377397.155,
  };

  final _minorMap = {
    GeodeticType.WGS84: 6356752.3142,
    GeodeticType.KATEC: 6356078.9633422494,
    GeodeticType.TM_N: 6356078.9633422494,
  };

  final _latitudeCenterMap = {
    GeodeticType.WGS84: 0.0,
    GeodeticType.KATEC: 0.663225115757845,
    GeodeticType.TM_N: 0.663225115757845,
  };

  final _longitudeCenterMap = {
    GeodeticType.WGS84: 0.0,
    GeodeticType.KATEC: 2.22529479629277,
    GeodeticType.TM_N: 2.21661859489671,
  };

  final _falseEastingMap = {
    GeodeticType.WGS84: 0.0,
    GeodeticType.KATEC: 400000.0,
    GeodeticType.TM_N: 200000.0,
  };

  final _falseNorthingMap = {
    GeodeticType.WGS84: 0.0,
    GeodeticType.KATEC: 600000.0,
    GeodeticType.TM_N: 500000.0,
  };

  _minorDividedMajor(GeodeticType type) => _minorMap[type] / _majorMap[type];
  _es(GeodeticType type) => 1.0 - _minorDividedMajor(type) * _minorDividedMajor(type);
  _esp(GeodeticType type) => _es(type) / (1.0 - _es(type));
  _ind(GeodeticType type) => _es(type) < 0.00001 ? 1.0 : 0.0;
  _src(GeodeticType type) => _majorMap[type] * mlFn(e0Fn(_es(type)), e1Fn(_es(type)), e2Fn(_es(type)), e3Fn(_es(type)), _latitudeCenterMap[type]);
  _dst(GeodeticType type) => _src(type);


  static double degree2radian(double degree) => degree * pi / 180.0;
  static double radian2degree(double radian) => radian * 180.0 / pi;

  static double e0Fn(double x) => 1.0 - 0.25 * x * (1.0 + x / 16.0 * (3.0 + 1.25 * x));
  static double e1Fn(double x) => 0.375 * x * (1.0 + 0.25 * x * (1.0 + 0.46875 * x));
  static double e2Fn(double x) => 0.05859375 * x * x * (1.0 + 0.75 * x);
  static double e3Fn(double x) => x * x * x * (35.0 / 3072.0);

  static double mlFn(double e0, double e1, double e2, double e3, double phi) => e0 * phi - e1 * sin(2.0 * phi) + e2 * sin(4.0 * phi) - e3 * sin(6.0 * phi);
  static double asinZ(double value) => asin((value > 0) ? min(1, value) : max(-1, value));

  GeodeticPoint run({GeodeticType srcType, GeodeticType dstType, GeodeticPoint inputPoint}) {
    final temporaryPoint = GeodeticPoint();
    final outputPoint = GeodeticPoint();

    if (srcType == GeodeticType.WGS84) {
      temporaryPoint.x = degree2radian(inputPoint.x);
      temporaryPoint.y = degree2radian(inputPoint.y);
    } else {
      _tmToWgs84(srcType: srcType, inputPoint: inputPoint, outputPoint: temporaryPoint);
    }

    if (dstType == GeodeticType.WGS84) {
      outputPoint.x = radian2degree(temporaryPoint.x);
      outputPoint.y = radian2degree(temporaryPoint.y);
    } else {
      _wgs84ToTm(dstType: dstType, inputPoint: temporaryPoint, outputPoint: outputPoint);
    }

    return outputPoint;
  }

  _wgs84ToTm({GeodeticType dstType, GeodeticPoint inputPoint, GeodeticPoint outputPoint}) {
    _transform(srcType: GeodeticType.WGS84, dstType: dstType, inputPoint: inputPoint);
    final deltaLongitude = inputPoint.x - _longitudeCenterMap[dstType];
    final sinPhi = sin(inputPoint.y);
    final cosPhi = cos(inputPoint.y);

    // TODO(any): I don't know why need this code.
//    if (_indMap[dstType] != 0) {
//      final b = cosPhi * sin(deltaLongitude);
//
//      if ((b.abs() - 1.0).abs() < EPSLN) {
//        // infinite error
//      }
//    } else {
//      final b = 0;
//      final x = 0.5 * _majorMap[dstType] * scaleFactor * log((1.0 + b) / (1.0 - b));
//      double con = acos(cosPhi * cos(deltaLongitude) / sqrt(1.0 - b * b));
//
//      if (inputPoint.y < 0) {
//        con *= -1;
//        final y = _majorMap[dstType] * scaleFactor * (con - _latitudeCenterMap[dstType]);
//      }
//    }

    final al = cosPhi * deltaLongitude;
    final als = al * al;
    final c = _esp(dstType) * cosPhi * cosPhi;
    final tq = tan(inputPoint.y);
    final t = tq * tq;
    final con = 1.0 - _es(dstType) * sinPhi * sinPhi;
    final n = _majorMap[dstType] / sqrt(con);
    final ml = _majorMap[dstType] * mlFn(e0Fn(_es(dstType)), e1Fn(_es(dstType)), e2Fn(_es(dstType)), e3Fn(_es(dstType)), inputPoint.y);

    outputPoint.x = _scaleFactor[dstType] * n * al * (1.0 + als / 6.0 * (1.0 - t + c + als / 20.0 * (5.0 - 18.0 * t + t * t + 72.0 * c - 58.0 * _esp(dstType)))) + _falseEastingMap[dstType];
    outputPoint.y = _scaleFactor[dstType] * (ml - _dst(dstType) + n * tq * (als * (0.5 + als / 24.0 * (5.0 - t + 9.0 * c + 4.0 * c * c + als / 30.0 * (61.0 - 58.0 * t + t * t + 600.0 * c - 330.0 * _esp(dstType)))))) + _falseNorthingMap[dstType];
  }

  _tmToWgs84({GeodeticType srcType, GeodeticPoint inputPoint, GeodeticPoint outputPoint}) {
    final temporaryPoint = GeodeticPoint(x: inputPoint.x, y: inputPoint.y);

    if (_ind(srcType) != 0) {
      final f = exp(inputPoint.x / (_majorMap[srcType] * _scaleFactor[srcType]));
      final g = 0.5 * (f - 1.0 / f);
      final temporary = _latitudeCenterMap[srcType] + temporaryPoint.y / (_majorMap[srcType] * _scaleFactor[srcType]);
      final h = cos(temporary);
      final con = sqrt((1.0 - h * h) / (1.0 + g * g));
      outputPoint.y = asinZ(con);

      if (temporary < 0) {
        outputPoint.y *= -1;
      }

      outputPoint.x = (g == 0) && (h == 0) ? _longitudeCenterMap[srcType] : (atan(g / h) + _longitudeCenterMap[srcType]);
    }

    temporaryPoint.x -= _falseEastingMap[srcType];
    temporaryPoint.y -= _falseNorthingMap[srcType];

    final con = (_src(srcType) + temporaryPoint.y / _scaleFactor[srcType]) / _majorMap[srcType];

    double phi = con;
    double deltaPhi;
    var i = 0;
    do {
      deltaPhi = ((con + e1Fn(_es(srcType)) * sin(2.0 * phi) - e2Fn(_es(srcType)) * sin(4.0 * phi) + e3Fn(_es(srcType)) * sin(6.0 * phi)) / e0Fn(_es(srcType))) - phi;
      phi += deltaPhi;
      i ++;
    } while(i < 6 && deltaPhi.abs() > EPSLN);

    if (phi.abs() < (pi / 2)) {
      final sinPhi = sin(phi);
      final cosPhi = cos(phi);
      final tanPhi = tan(phi);
      final c = _esp(srcType) * cosPhi * cosPhi;
      final cs = c * c;
      final t = tanPhi * tanPhi;
      final ts = t * t;
      final cont = 1.0 - _es(srcType) * sinPhi * sinPhi;
      final n = _majorMap[srcType] / sqrt(cont);
      final r = n * (1.0 - _es(srcType)) / cont;
      final d = temporaryPoint.x / (n * _scaleFactor[srcType]);
      final ds = d * d;
      outputPoint.y = phi - (n * tanPhi * ds / r) * (0.5 - ds / 24.0 * (5.0 + 3.0 * t + 10.0 * c - 4.0 * cs - 9.0 * _esp(srcType) - ds / 30.0 * (61.0 + 90.0 * t + 298.0 * c + 45.0 * ts - 252.0 * _esp(srcType) - 3.0 * cs)));
      outputPoint.x = _longitudeCenterMap[srcType] + (d * (1.0 - ds / 6.0 * (1.0 + 2.0 * t + c - ds / 20.0 * (5.0 - 2.0 * c + 28.0 * t - 3.0 * cs + 8.0 * _esp(srcType) + 24.0 * ts))) / cosPhi);
    } else {
      outputPoint.y = pi * 0.5 * sin(temporaryPoint.y);
      outputPoint.x = _longitudeCenterMap[srcType];
    }

    _transform(srcType: srcType, dstType: GeodeticType.WGS84, inputPoint: outputPoint);
  }

  ///
  /// Author:       Richard Greenwood rich@greenwoodmap.com
  /// License:      LGPL as per: http://www.gnu.org/copyleft/lesser.html
  ///
  /// * convert between geodetic coordinates (longitude, latitude, height)
  /// * and gecentric coordinates (X, Y, Z)
  /// * ported from Proj 4.9.9 geocent.c
  ///

  static const HalfPi = 0.5 * pi;
  static const Cos67P5 = 0.38268343236508977;   // cosine of 67.5 degrees
  static const AdC = 1.0026000;

  _transform({GeodeticType srcType, GeodeticType dstType, GeodeticPoint inputPoint}) {
    if (srcType == dstType) return;

    if (srcType != GeodeticType.WGS84 || dstType != GeodeticType.WGS84) {
      // Convert to geocentric coordinates
      _geodeticToGeocentric(srcType: srcType, inputPoint: inputPoint);

      // Convert between datums
      if (srcType != GeodeticType.WGS84) {
        _geocentricToWgs84(inputPoint: inputPoint);
      }

      if (dstType != GeodeticType.WGS84) {
        _geocentricFromWgs84(inputPoint: inputPoint);
      }

      // Convert back to geodetic coordinates
      _geocentricToGeodetic(dstType: dstType, inputPoint: inputPoint);
    }
  }

  _geodeticToGeocentric({GeodeticType srcType, GeodeticPoint inputPoint}) {
    double latitude = inputPoint.y;
    double longitude = inputPoint.x;
    double height = inputPoint.z;

    if (latitude < -HalfPi && latitude > -1.001 * HalfPi) {
      latitude = -HalfPi;
    } else if (latitude > HalfPi && latitude < 1.001 * HalfPi) {
      latitude = HalfPi;
    } else if (latitude < -HalfPi || latitude > HalfPi) {
      // Latitude out of range
      return true;
    }

    if (longitude > pi) {
      longitude -= (2 * pi);
    }

    final sinLatitude = sin(latitude);
    final cosLatitude = cos(latitude);
    final sin2Latitude = sinLatitude * sinLatitude;
    final rn = _majorMap[srcType] / (sqrt(1.0e0 - _es(srcType) * sin2Latitude));
    final x = (rn + height) * cosLatitude * cos(longitude);
    final y = (rn + height) * cosLatitude * sin(longitude);
    final z = ((rn * (1 - _es(srcType))) + height) * sinLatitude;

    inputPoint.x = x;
    inputPoint.y = y;
    inputPoint.z = z;

    return false;
  }

  _geocentricToGeodetic({GeodeticType dstType, GeodeticPoint inputPoint}) {
    double x = inputPoint.x;
    double y = inputPoint.y;
    double z = inputPoint.z;

    double latitude = 0.0;
    double longitude = 0.0;
    double height = 0.0;

    bool isAtPole = false;

    if (x != 0.0) {
      longitude = atan2(y, x);
    } else if (y > 0.0) {
      longitude = HalfPi;
    } else if (y < 0.0) {
      longitude = -HalfPi;
    } else {
      // x == 0.0 && y == 0.0
      isAtPole = true;
      longitude = 0.0;

      if (z > 0.0) {
        // north pole
        latitude = 0.0;
      } else if (z < 0.0) {
        // south pole
        latitude = -HalfPi;
      } else {
        // center of earth
        latitude = HalfPi;
        height = -_minorMap[dstType];
        return;
      }
    }

    final w2 = x * x + y * y;
    final w = sqrt(w2);
    final t0 = z * AdC;
    final s0 = sqrt(t0 * t0 + w2);
    final sinB0 = t0 / s0;
    final cosB0 = w / s0;
    final sin3B0 = sinB0 * sinB0 * sinB0;
    final t1 = z + _minorMap[dstType] * _esp(dstType) * sin3B0;
    final sum = w - _majorMap[dstType] * _es(dstType) * cosB0 * cosB0 * cosB0;
    final s1 = sqrt(t1 * t1 + sum * sum);
    final sinP1 = t1 / s1;
    final cosP1 = sum /s1;
    final rn = _majorMap[dstType] / sqrt(1.0 - _es(dstType) * sinP1 * sinP1);

    if (cosP1 >= Cos67P5) {
      height = w / cosP1 - rn;
    } else if (cosP1 <= -Cos67P5) {
      height = z / sinP1 + rn * (_es(dstType) - 1.0);
    }

    if (!isAtPole) {
      latitude = atan(sinP1 / cosP1);
    }

    inputPoint.x = longitude;
    inputPoint.y = latitude;
    inputPoint.z = height;
  }

  _geocentricToWgs84({GeodeticPoint inputPoint}) {
    inputPoint.x += _datumParams.x;
    inputPoint.y += _datumParams.y;
    inputPoint.z += _datumParams.z;
  }

  _geocentricFromWgs84({GeodeticPoint inputPoint}) {
    inputPoint.x -= _datumParams.x;
    inputPoint.y -= _datumParams.y;
    inputPoint.z -= _datumParams.z;
  }
}