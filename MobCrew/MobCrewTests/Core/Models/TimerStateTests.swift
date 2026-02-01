import Testing
import Foundation
@testable import MobCrew

@Suite("TimerState Tests")
struct TimerStateTests {

    // MARK: - displayTime Formatting

    @Test("displayTime formats 125 seconds as 02:05")
    func displayTimeFormats125Seconds() {
        let timer = TimerState(secondsRemaining: 125)
        #expect(timer.displayTime == "02:05")
    }

    @Test("displayTime formats 0 seconds as 00:00")
    func displayTimeFormatsZeroSeconds() {
        let timer = TimerState(secondsRemaining: 0)
        #expect(timer.displayTime == "00:00")
    }

    @Test("displayTime formats 59 seconds as 00:59")
    func displayTimeFormats59Seconds() {
        let timer = TimerState(secondsRemaining: 59)
        #expect(timer.displayTime == "00:59")
    }

    @Test("displayTime formats 60 seconds as 01:00")
    func displayTimeFormats60Seconds() {
        let timer = TimerState(secondsRemaining: 60)
        #expect(timer.displayTime == "01:00")
    }

    @Test("displayTime formats 600 seconds as 10:00")
    func displayTimeFormats10Minutes() {
        let timer = TimerState(secondsRemaining: 600)
        #expect(timer.displayTime == "10:00")
    }

    // MARK: - progress Calculation

    @Test("progress returns 0.0 at start")
    func progressAtStart() {
        let timer = TimerState(secondsRemaining: 300, totalSeconds: 300)
        #expect(timer.progress == 0.0)
    }

    @Test("progress returns 0.5 at halfway")
    func progressAtHalfway() {
        let timer = TimerState(secondsRemaining: 150, totalSeconds: 300)
        #expect(timer.progress == 0.5)
    }

    @Test("progress returns 1.0 at end")
    func progressAtEnd() {
        let timer = TimerState(secondsRemaining: 0, totalSeconds: 300)
        #expect(timer.progress == 1.0)
    }

    // MARK: - Edge Cases

    @Test("progress returns 0.0 when totalSeconds is 0")
    func progressReturnsZeroWhenTotalIsZero() {
        let timer = TimerState(secondsRemaining: 0, totalSeconds: 0)
        #expect(timer.progress == 0.0)
    }

    @Test("progress handles negative remaining correctly")
    func progressHandlesNegativeRemaining() {
        let timer = TimerState(secondsRemaining: -10, totalSeconds: 100)
        #expect(timer.progress > 1.0)
    }

    @Test("displayTime handles large values")
    func displayTimeHandlesLargeValues() {
        let timer = TimerState(secondsRemaining: 3661)
        #expect(timer.displayTime == "61:01")
    }
}
