import MovieAppDS
import UIKit

struct MovieDetailCellRegistrations {
    let imageLoader: any IImageLoader

    func makeCastMemberRegistration() -> UICollectionView.CellRegistration<
        CastMemberCell,
        MovieDetailModel.DisplayedCastMember
    > {
        UICollectionView.CellRegistration { [imageLoader] cell, _, member in
            cell.configure(with: member, imageLoader: imageLoader)
        }
    }

    func makePosterRegistration() -> UICollectionView.CellRegistration<PosterCell, MovieDetailModel.DisplayedMovie> {
        UICollectionView.CellRegistration { [imageLoader] cell, _, movie in
            cell.configure(
                title: movie.title,
                artwork: movie.artwork,
                showsPlayBadge: false,
                rating: movie.rating,
                imageLoader: imageLoader
            )
        }
    }

    func makeTrailerRegistration() -> UICollectionView.CellRegistration<MediaRowCell, MovieDetailModel.DisplayedTrailer> {
        UICollectionView.CellRegistration { [imageLoader] cell, _, trailer in
            cell.configure(
                title: trailer.title,
                metadata: trailer.metadata,
                rating: nil,
                artwork: trailer.artwork,
                imageLoader: imageLoader
            )
            cell.showsPlayBadge = true
            cell.accessibilityValue = trailer.accessibilityValue
        }
    }

    func makeStatusRegistration() -> UICollectionView.CellRegistration<UICollectionViewCell, MovieDetailLayout.Status> {
        UICollectionView.CellRegistration { cell, _, status in
            switch status {
            case .loading:
                cell.contentConfiguration = UIContentUnavailableConfiguration.loading()
            case .empty(let message):
                var configuration = UIContentUnavailableConfiguration.empty()
                configuration.text = message
                configuration.textProperties.font = .MVFont(.body)
                configuration.textProperties.color = .MVColor(.textSecondary)
                cell.contentConfiguration = configuration
            }
        }
    }
}
