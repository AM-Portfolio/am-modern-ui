import 'package:am_design_system/am_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrowserZoomMath', () {
    test('clamps 50% and 250% to 67–200', () {
      expect(BrowserZoomMath.clampZoom(0.5), BrowserZoomMath.minZoom);
      expect(BrowserZoomMath.clampZoom(2.5), BrowserZoomMath.maxZoom);
    });

    test('next and prev steps', () {
      expect(BrowserZoomMath.nextStep(1.0), 1.10);
      expect(BrowserZoomMath.nextStep(2.0), 2.0);
      expect(BrowserZoomMath.prevStep(1.0), 0.90);
      expect(BrowserZoomMath.prevStep(0.67), 0.67);
    });

    test('nearestStep', () {
      expect(BrowserZoomMath.nearestStep(1.24), 1.25);
      expect(BrowserZoomMath.nearestStep(1.0), 1.0);
    });

    test('150% chrome on 1280 css keeps desktop layout width 1920', () {
      final chrome = BrowserZoomMath.detectChromeZoom(
        innerWidth: 1280,
        outerWidth: 1920,
        devicePixelRatio: 1.5,
        baselineDpr: 1.0,
      );
      expect(chrome, closeTo(1.5, 0.02));
      expect(BrowserZoomMath.layoutWidth(1280, chrome), closeTo(1920, 1));
      expect(BrowserZoomMath.layoutWidth(1280, chrome), greaterThan(1100));
    });

    test('80% zoom uses unzoomed width for chrome', () {
      final chrome = BrowserZoomMath.detectChromeZoom(
        innerWidth: 1600,
        outerWidth: 1280,
        devicePixelRatio: 0.8,
        baselineDpr: 1.0,
      );
      expect(chrome, closeTo(0.8, 0.05));
      expect(BrowserZoomMath.layoutWidth(1600, 0.8), closeTo(1280, 1));
    });

    test('OS 125% scale at Chrome 100% is not chrome zoom', () {
      final chrome = BrowserZoomMath.detectChromeZoom(
        innerWidth: 1920,
        outerWidth: 1920,
        devicePixelRatio: 1.25,
        baselineDpr: 1.25,
      );
      expect(chrome, closeTo(1.0, 0.02));
    });

    test('OS 125% + Chrome 110% uses dpr ratio when outer/inner is in 100% band',
        () {
      final chrome = BrowserZoomMath.detectChromeZoom(
        innerWidth: 1920,
        outerWidth: 2000,
        devicePixelRatio: 1.375,
        baselineDpr: 1.25,
      );
      expect(chrome, closeTo(1.10, 0.03));
    });

    test('innerWidth 0 returns 1.0', () {
      expect(
        BrowserZoomMath.detectChromeZoom(
          innerWidth: 0,
          outerWidth: 1920,
          devicePixelRatio: 1,
          baselineDpr: 1,
        ),
        1.0,
      );
    });

    test('textScale is 1 when app and chrome match', () {
      expect(
        BrowserZoomMath.textScale(appZoom: 1.5, chromeZoom: 1.5),
        1.0,
      );
    });

    test('pageLayoutSize at 80% is larger so FittedBox can shrink the whole page',
        () {
      final layout = BrowserZoomMath.pageLayoutSize(const Size(1280, 720), 0.8);
      expect(layout.width, closeTo(1600, 0.5));
      expect(layout.height, closeTo(900, 0.5));
    });

    test('parseStored', () {
      expect(BrowserZoomMath.parseStored(null), isNull);
      expect(BrowserZoomMath.parseStored('nope'), isNull);
      expect(BrowserZoomMath.parseStored('1.25'), 1.25);
      expect(BrowserZoomMath.parseStored('9'), BrowserZoomMath.maxZoom);
    });

    test('percent', () {
      expect(BrowserZoomMath.percent(1.25), 125);
    });
  });
}
