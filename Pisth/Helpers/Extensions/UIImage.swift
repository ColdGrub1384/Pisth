import UIKit

extension UIImage {
    
    /// Create image from color.
    ///
    /// - Parameters:
    ///     - color: Color of image.
    ///     - size: Size of image.
    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        var alpha: CGFloat = 0
        color.getWhite(nil, alpha: &alpha)
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}
