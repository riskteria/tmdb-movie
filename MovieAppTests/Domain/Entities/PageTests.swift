@testable import MovieApp
import Testing

struct PageTests {
    @Test
    func hasNextPageBeforeTheLastPage() {
        // Given
        let page = Page<Movie>(number: 1, items: [], totalPages: 3, totalResults: 60)

        // Assert
        #expect(page.hasNextPage)
    }

    @Test
    func hasNoNextPageOnTheLastPage() {
        // Given
        let page = Page<Movie>(number: 3, items: [], totalPages: 3, totalResults: 60)

        // Assert
        #expect(!page.hasNextPage)
    }
}
