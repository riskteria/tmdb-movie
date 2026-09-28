import UIKit

// Adopted by a screen that can act as the source of a zoom transition into Movie Detail.
protocol ZoomTransitionSourceProviding: AnyObject {
    func zoomTransitionSourceView(for movieID: Movie.ID) -> UIView?
}
