@testable import MovieApp
import Testing

struct WatchProgressTests {
    @Test
    func progressIsPositionOverDuration() {
        // Given
        let progress = WatchProgress.fixture(position: .seconds(30), duration: .seconds(120))

        // Assert
        #expect(progress.progress == 0.25)
    }

    @Test
    func remainingIsDurationMinusPosition() {
        // Given
        let progress = WatchProgress.fixture(position: .seconds(30), duration: .seconds(120))

        // Assert
        #expect(progress.remaining == .seconds(90))
    }

    @Test
    func progressIsZeroWithoutDuration() {
        // Given
        let progress = WatchProgress.fixture(position: .seconds(30), duration: .zero)

        // Assert
        #expect(progress.progress == 0)
    }

    @Test
    func progressIsClampedWhenPositionPassesDuration() {
        // Given
        let progress = WatchProgress.fixture(position: .seconds(130), duration: .seconds(120))

        // Assert
        #expect(progress.progress == 1)
    }

    @Test
    func remainingIsZeroWhenPositionPassesDuration() {
        // Given
        let progress = WatchProgress.fixture(position: .seconds(130), duration: .seconds(120))

        // Assert
        #expect(progress.remaining == .zero)
    }

    @Test(arguments: [(94, false), (95, true), (100, true)])
    func isFinishedFromNinetyFivePercent(positionSeconds: Int, isFinished: Bool) {
        // Given
        let progress = WatchProgress.fixture(position: .seconds(positionSeconds), duration: .seconds(100))

        // Assert
        #expect(progress.isFinished == isFinished)
    }
}
