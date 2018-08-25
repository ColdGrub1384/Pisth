#if os(iOS)
import UIKit

/// Alert with an indicator view at center.
public class ActivityViewController: UIAlertController {
    
    /// Alert style.
    public override var preferredStyle: UIAlertController.Style {
        return .alert
    }
    
    /// Initialize with given message.
    ///
    /// - Parameters:
    ///     - message: Message to be displayed in alert.
    ///
    /// - Returns: An alert with an indicator view at center and given message.
    public init(message: String) {
        super.init(nibName: nil, bundle: nil)
        title = message
        self.message = "\n\n\n"
    }
    
    /// init(coder:) is not implemented.
    public required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        let activityIndicator = UIActivityIndicatorView(frame: view.bounds)
        activityIndicator.style = .gray
        activityIndicator.isUserInteractionEnabled = false
        activityIndicator.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
    }
}

#endif
