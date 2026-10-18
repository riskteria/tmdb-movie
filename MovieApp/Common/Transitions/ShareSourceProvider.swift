import UIKit

protocol ShareSourceProvider: AnyObject {
    var shareSourceItem: (any UIPopoverPresentationControllerSourceItem)? { get }
}
