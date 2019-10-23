library geodetic_converter;

import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:geodetic_converter/src/geodetic_point.dart';
import 'package:geodetic_converter/src/geodetic_type.dart';

///
/// https://github.com/wan2land/python-geo-converter/blob/master/GeoConverter.py
/// 


/// A Calculator.
class Calculator {
//  /// Returns [value] plus 1.
//  int addOne(int value) => value + 1;
  static const EPSLN = 0.0000000001;
  static const scaleFactor = 1.0;

  final _majorMap = {
    GeodeticType.WGS84: 6378137.0,
    GeodeticType.TM_N: 6377397.155,
  };

  final _minorMap = {
    GeodeticType.WGS84: 6356752.3142,
    GeodeticType.TM_N: 6356078.9633422494,
  };

  final _latitudeCenterMap = {
    GeodeticType.WGS84: 0.0,
    GeodeticType.TM_N: 0.663225115757845,
  };

  final _longitudeCenterMap = {
    GeodeticType.WGS84: 0.0,
    GeodeticType.TM_N: 2.21661859489671,
  };

  final _falseEastingMap = {
    GeodeticType.WGS84: 0.0,
    GeodeticType.TM_N: 200000.0,
  };

  final _falseNorthingMap = {
    GeodeticType.WGS84: 0.0,
    GeodeticType.TM_N: 500000.0,
  };

  Map<GeodeticType, double> _minorDividedMajorMap;
  Map<GeodeticType, double> _esMap;
  Map<GeodeticType, double> _espMap;
  Map<GeodeticType, double> _indMap;
  Map<GeodeticType, double> _srcMap;
  Map<GeodeticType, double> _dstMap;

  Calculator() {
    _minorDividedMajorMap = {
      GeodeticType.WGS84: _minorMap[GeodeticType.WGS84] / _majorMap[GeodeticType.WGS84],
      GeodeticType.TM_N: _minorMap[GeodeticType.TM_N] / _majorMap[GeodeticType.TM_N],
    };

    _esMap = {
      GeodeticType.WGS84: (1.0 - (_minorDividedMajorMap[GeodeticType.WGS84] * _minorDividedMajorMap[GeodeticType.WGS84])),
      GeodeticType.TM_N: (1.0 - (_minorDividedMajorMap[GeodeticType.TM_N] * _minorDividedMajorMap[GeodeticType.TM_N])),
    };

    _espMap = {
      GeodeticType.WGS84: (_esMap[GeodeticType.WGS84] / (1.0 - _esMap[GeodeticType.WGS84])),
      GeodeticType.TM_N: (_esMap[GeodeticType.TM_N] / (1.0 - _esMap[GeodeticType.TM_N])),
    };

    _indMap = {
      GeodeticType.WGS84: (_esMap[GeodeticType.WGS84] < 0.00001 ? 1.0 : 0.0),
      GeodeticType.TM_N: (_esMap[GeodeticType.TM_N] < 0.00001 ? 1.0 : 0.0),
    };

    // TODO(any): I don't know why same between values.
    _dstMap = _srcMap = {
      GeodeticType.WGS84: _generatorSrcDst(GeodeticType.WGS84),
      GeodeticType.TM_N: _generatorSrcDst(GeodeticType.TM_N),
    };
  }

  _generatorSrcDst(GeodeticType type) => _majorMap[type] * mlFn(e0Fn(_esMap[type]), e1Fn(_esMap[type]), e2Fn(_esMap[type]), e3Fn(_esMap[type]), _latitudeCenterMap[type]);

  static double degree2radian(double degree) => degree * pi / 180.0;
  static double radian2degree(double radian) => radian * 180.0 / pi;

  static double e0Fn(double x) => 1.0 - 0.25 * x * (1.0 + x / 16.0 * (3.0 + 1.25 * x));
  static double e1Fn(double x) => 0.375 * x * (1.0 + 0.25 * x * (1.0 + 0.46875 * x));
  static double e2Fn(double x) => 0.05859375 * x * x * (1.0 + 0.75 * x);
  static double e3Fn(double x) => x * x * x * (35.0 / 3072.0);

  static double mlFn(double e0, double e1, double e2, double e3, double phi) => e0 * phi - e1 * sin(2.0 * phi) + e2 * sin(4.0 * phi) - e3 * sin(6.0 * phi);
  static double asinZ(double value) => asin((value > 0) ? min(1, value) : max(-1, value));

  /// Convert
  convert({GeodeticType srcType, GeodeticType dstType, GeodeticPoint inputPoint}) {
    final temporaryPoint = GeodeticPoint();
    final outputPoint = GeodeticPoint();

    if (srcType == GeodeticType.WGS84) {
      temporaryPoint.x = degree2radian(inputPoint.x);
      temporaryPoint.y = degree2radian(inputPoint.y);
    } else {
      _tmToWgs84(srcType: srcType, inputPoint: inputPoint, outputPoint: temporaryPoint);
    }

    // TODO: ...
  }

  // TODO(any): Need refactoring.
  _tmToWgs84({GeodeticType srcType, GeodeticPoint inputPoint, GeodeticPoint outputPoint}) {
    final temporaryPoint = GeodeticPoint(x: inputPoint.x, y: inputPoint.y);

    if (_indMap[srcType] != 0) {
      final f = exp(inputPoint.x / (_majorMap[srcType] * scaleFactor));
      final g = 0.5 * (f - (1.0 / f));
      final temporary = _latitudeCenterMap[srcType] + (temporaryPoint.y / (_majorMap[srcType] * scaleFactor));
      final h = cos(temporary);
      final con = sqrt((1.0 - (h * h)) / (1.0 + (g * g)));
      outputPoint.y = asinZ(con);

      if (temporary < 0) {
        outputPoint.y *= -1;
      }

      outputPoint.x = (g == 0) && (h == 0) ? _longitudeCenterMap[srcType] : atan(g / h) + _longitudeCenterMap[srcType];
    }

    temporaryPoint.x -= _falseEastingMap[srcType];
    temporaryPoint.y -= _falseNorthingMap[srcType];

    final con = _srcMap[srcType] + (temporaryPoint.y / scaleFactor / _majorMap[srcType]);

    double phi = con;
    double deltaPhi;
    var i = 0;
    do {
      deltaPhi = ((con + e1Fn(_esMap[srcType]) * sin(2.0 * phi) - e2Fn(_esMap[srcType]) * sin(4.0 * phi) + e3Fn(_esMap[srcType]) * sin(6.0 * phi)) / e0Fn(_esMap[srcType])) - phi;
      phi += deltaPhi;
      i ++;
    } while(i < 6 && deltaPhi.abs() > EPSLN);

    if (phi.abs() < (pi / 2)) {
      final sinPhi = sin(phi);
      final cosPhi = cos(phi);
      final tanPhi = tan(phi);
      final c = _espMap[srcType] * cosPhi * cosPhi;
      final cs = c * c;
      final t = tanPhi * tanPhi;
      final ts = t * t;
      final cont = 1.0 - _esMap[srcType] * sinPhi * sinPhi;
      final n = _majorMap[srcType] / sqrt(cont);
      final r = n * (1.0 - _esMap[srcType]) / cont;
      final d = temporaryPoint.x / (n * scaleFactor);
      final ds = d * d;
      outputPoint.y = phi - (n * tanPhi * ds / r) * (0.5 - ds / 24.0 * (5.0 + 3.0 * t + 10.0 * c - 4.0 * cs - 9.0 * _espMap[srcType] - ds / 30.0 * (61.0 + 90.0 * t + 298.0 * c + 45.0 * ts - 252.0 * _espMap[srcType] - 3.0 * cs)));
      outputPoint.x = _longitudeCenterMap[srcType] + (d * (1.0 - ds / 6.0 * (1.0 + 2.0 * t + c - ds / 20.0 * (5.0 - 2.0 * c + 28.0 * t - 3.0 * cs + 8.0 * _espMap[srcType] + 24.0 * ts))) / cosPhi);
    } else {
      outputPoint.y = pi * 0.5 * sin(temporaryPoint.y);
      outputPoint.x = _longitudeCenterMap[srcType];
    }

    _transform(srcType: srcType, dstType: GeodeticType.WGS84, inputPoint: outputPoint);
  }


  /// Author:       Richard Greenwood rich@greenwoodmap.com
  /// License:      LGPL as per: http://www.gnu.org/copyleft/lesser.html
  ///
  /// * convert between geodetic coordinates (longitude, latitude, height)
  /// * and gecentric coordinates (X, Y, Z)
  /// * ported from Proj 4.9.9 geocent.c
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
    final rn = _majorMap[srcType] / (sqrt(1.0e0 - _esMap[srcType] * sin2Latitude));
    final x = (rn + height) * cosLatitude * cos(longitude);
    final y = (rn + height) * cosLatitude * sin(longitude);
    final z = ((rn * (1 - _esMap[srcType])) + height) * sinLatitude;

    inputPoint.x =
  }

  _geocentricToWgs84({GeodeticPoint inputPoint}) {

  }

  _geocentricFromWgs84({GeodeticPoint inputPoint}) {

  }

  _geocentricToGeodetic({GeodeticType dstType, GeodeticPoint inputPoint}) {

  }
}
