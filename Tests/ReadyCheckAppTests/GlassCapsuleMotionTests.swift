import SwiftUI
import XCTest
@testable import ReadyCheckApp

final class GlassCapsuleMotionTests: XCTestCase {
    func testCapsuleStretchesAlongTheTravelAxisAndRebounds() {
        for axis: Axis in [.horizontal, .vertical] {
            let start = CGRect(x: 0, y: 0, width: 44, height: 55)
            let target = axis == .horizontal
                ? start.offsetBy(dx: 112, dy: 0) : start.offsetBy(dx: 0, dy: 112)
            var motion = GlassCapsuleMotion(frame: start, axis: axis)
            var greatestStretch: CGFloat = 0
            var overshoot: CGFloat = 0
            for _ in 0..<75 {
                motion.advance(toward: target, axis: axis, seconds: 1.0 / 60)
                let frame = motion.frame(fitting: target, axis: axis)
                XCTAssertEqual(axis == .horizontal ? frame.height : frame.width,
                               axis == .horizontal ? target.height : target.width)
                greatestStretch = max(greatestStretch, axis == .horizontal
                    ? frame.width - target.width : frame.height - target.height)
                overshoot = max(overshoot, motion.position - (axis == .horizontal ? target.midX : target.midY))
            }
            XCTAssertGreaterThan(greatestStretch, 5)
            XCTAssertGreaterThan(overshoot, 1)
            XCTAssertTrue(motion.isAtRest(at: target, axis: axis))
        }
    }

    func testReversingReusesTheCurrentVelocityAndSettlesAtTheNewTarget() {
        let start = CGRect(x: 0, y: 0, width: 100, height: 30)
        let first = start.offsetBy(dx: 200, dy: 0)
        var motion = GlassCapsuleMotion(frame: start, axis: .horizontal)
        for _ in 0..<6 {
            motion.advance(toward: first, axis: .horizontal, seconds: 1.0 / 60)
        }
        let movingCenter = motion.position
        XCTAssertGreaterThan(motion.velocity, 0)
        motion.advance(toward: start, axis: .horizontal, seconds: 1.0 / 1000)
        XCTAssertGreaterThan(motion.position, movingCenter)
        XCTAssertLessThan(motion.position - movingCenter, 4)

        for _ in 0..<75 {
            motion.advance(toward: start, axis: .horizontal, seconds: 1.0 / 60)
        }
        XCTAssertTrue(motion.isAtRest(at: start, axis: .horizontal))
    }
}
