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
    
    // MARK: - Getting icon for file
    
    // https://indiestack.com/2018/05/icon-for-file-with-uikit/
    
    /// Size for generated icon.
    public enum FileIconSize {
        case smallest
        case largest
    }
    
    /// Get icon for local file.
    ///
    /// - Parameters:
    ///     - fileURL: Local file URL.
    ///     - preferredSize: Preferred generated icon size.
    public class func icon(forFileURL fileURL: URL, preferredSize: FileIconSize = .smallest) -> UIImage {
        
        var url = fileURL
        
        if !FileManager.default.fileExists(atPath: url.path) {
            url = URL(fileURLWithPath: NSTemporaryDirectory().nsString.appendingPathComponent(fileURL.lastPathComponent))
            FileManager.default.createFile(atPath: url.path, contents: nil, attributes: nil)
        }
        
        let myInteractionController = UIDocumentInteractionController(url: url)
        let allIcons = myInteractionController.icons
        
        // allIcons is guaranteed to have at least one image
        switch preferredSize {
        case .smallest: return allIcons.first ?? #imageLiteral(resourceName: "File icons/file")
        case .largest: return allIcons.last ?? #imageLiteral(resourceName: "File icons/file")
        }
        
        if url != fileURL {
            try? FileManager.default.removeItem(at: url)
        }
    }
    
    /// Get icon for file name.
    ///
    /// - Parameters:
    ///     - fileName: Local file URL.
    ///     - preferredSize: Preferred generated icon size.
    public class func icon(forFileNamed fileName: String, preferredSize: FileIconSize = .smallest) -> UIImage {
        return icon(forFileURL: URL(fileURLWithPath: fileName), preferredSize: preferredSize)
    }
    
    /// Get icon for path extension.
    ///
    /// - Parameters:
    ///     - pathExtension: Local file URL.
    ///     - preferredSize: Preferred generated icon size.
    public class func icon(forPathExtension pathExtension: String, preferredSize: FileIconSize = .smallest) -> UIImage {
        let baseName = "Generic"
        let fileName = (baseName as NSString).appendingPathExtension(pathExtension) ?? baseName
        return icon(forFileNamed: fileName, preferredSize: preferredSize)
    }
}
