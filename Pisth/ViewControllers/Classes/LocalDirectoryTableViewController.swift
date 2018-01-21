// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit
import Zip
import GoogleMobileAds
import AVFoundation
import AVKit

/// Table view controller used to manage local files.
class LocalDirectoryTableViewController: UITableViewController, GADBannerViewDelegate {
    
    /// Directory where retrieve files.
    var directory: URL
    
    /// Fetched files.
    var files = [URL]()
    
    /// Error viewing directory.
    var error: Error?
    
    /// File to open did view appear.
    var openFile: URL?
    
    /// Delegate used.
    var delegate: LocalDirectoryTableViewControllerDelegate?
    
    /// Ad banner view displayed as header of Table view.
    var bannerView: GADBannerView!
    
    /// Share file with an `UIActivityViewController`.
    ///
    /// - Parameters:
    ///     - sender: Button that sends the action, where point the `UIActivityViewController` and in wich the `tag` will be used as index of file in `files` array.
    @objc func shareFile(_ sender: UIButton) {
        let shareVC = UIActivityViewController(activityItems: [files[sender.tag]], applicationActivities: nil)
        shareVC.popoverPresentationController?.sourceView = sender
        present(shareVC, animated: true, completion: nil)
    }
    
    /// Init with given directory.
    /// - Parameters:
    ///     - directory: Directory to open.
    ///
    /// - Returns: A Table view controller listing files in given directory.
    init(directory: URL) {
        
        self.directory = directory
        
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: directory.path)
            for file in files {
                self.files.append(directory.appendingPathComponent(file))
            }
        } catch let error {
            self.error = error
        }
        
        super.init(style: .plain)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    /// MARK: - View controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = directory.lastPathComponent
        
        if #available(iOS 11.0, *) {
            navigationItem.largeTitleDisplayMode = .never
        }
        
        tableView.register(UINib(nibName: "FileTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: "file")
        tableView.backgroundColor = .black
        clearsSelectionOnViewWillAppear = false
        tableView.tableFooterView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        
        // Banner ad
        bannerView = GADBannerView(adSize: kGADAdSizeBanner)
        bannerView.rootViewController = self
        bannerView.adUnitID = "ca-app-pub-9214899206650515/4247056376"
        bannerView.delegate = self
        bannerView.load(GADRequest())
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let error = error {
            let errorAlert = UIAlertController(title: "Error opening directory!", message: error.localizedDescription, preferredStyle: .alert)
            errorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (_) in
                self.navigationController?.popViewController(animated: true)
            }))
            self.present(errorAlert, animated: true, completion: nil)
        }
        
        if let openFile = openFile {
            guard let index = files.index(of: openFile) else { return }
            let indexPath = IndexPath(row: index, section: 0)
            
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
            tableView(tableView, didSelectRowAt: indexPath)
            
            self.openFile = nil
        }
        
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 87
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return files.count
    }
    
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "file") as! FileTableViewCell
        cell.contentView.superview?.backgroundColor = .black
        
        // Configure the cell...
        
        cell.filename.text = files[indexPath.row].lastPathComponent
        
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: files[indexPath.row].path, isDirectory: &isDir) {
            if isDir.boolValue { // Is directory
                cell.iconView.image = #imageLiteral(resourceName: "folder")
            } else { // Is file
                cell.iconView.image = fileIcon(forExtension: files[indexPath.row].pathExtension)
            }
        }
        
        let shareButton = UIButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        shareButton.setImage(#imageLiteral(resourceName: "share"), for: .normal)
        shareButton.tag = indexPath.row
        shareButton.addTarget(self, action: #selector(shareFile(_:)), for: .touchUpInside)
        shareButton.backgroundColor = .black
        cell.accessoryView = shareButton
                
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            do {
                try FileManager.default.removeItem(at: files[indexPath.row])
                
                files.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            } catch let error {
                let errorAlert = UIAlertController(title: "Error removing file!", message: error.localizedDescription, preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(errorAlert, animated: true, completion: nil)
                tableView.reloadData()
            }
        }
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        guard let cell = tableView.cellForRow(at: indexPath) as? FileTableViewCell else { return }
        
        tableView.deselectRow(at: indexPath, animated: true)
        if cell.iconView.image == #imageLiteral(resourceName: "folder") { // Open folder
            let dirVC = LocalDirectoryTableViewController(directory: self.files[indexPath.row])
            dirVC.delegate = delegate
            self.navigationController?.pushViewController(dirVC, animated: true)
        } else {
            if let delegate = delegate { // Handle the file with delegate
                delegate.localDirectoryTableViewController(self, didOpenFile: self.files[indexPath.row])
            } else { // Default handler
                LocalDirectoryTableViewController.openFile(files[indexPath.row], from: cell.frame, in: view, navigationController: navigationController, showActivityViewControllerInside: self)
            }
        }
    }
    
    // MARK: - Banner view delegate
    
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        // Show ad only when it received
        tableView.tableHeaderView = bannerView
    }
    
    // MARK: - Static
    
    /// Edit, view or share given file.
    ///
    /// - Parameters:
    ///     - file: File to be opened.
    ///     - frame: Frame where point an `UIActivityController` if the file will be saved.
    ///     - view: View from wich share the file.
    ///     - navigationController: Navigation controller in wich push editor or viewer.
    ///     - viewController: viewController in wich show loading alert.
    static func openFile(_ file: URL, from frame: CGRect, `in` view: UIView, navigationController: UINavigationController?, showActivityViewControllerInside viewController: UIViewController?) {
        
        func openFile() {
            if let _ = try? String.init(contentsOfFile: file.path) { // Is text
                var editTextVC: EditTextViewController! {
                    let editTextViewController = Bundle.main.loadNibNamed("EditTextViewController", owner: nil, options: nil)!.first as! EditTextViewController
                    
                    editTextViewController.file = file
                    
                    return editTextViewController
                }
                
                if file.pathExtension.lowercased() == "html" || file.pathExtension.lowercased() == "htm" { // Ask for view HTML or edit
                    let alert = UIAlertController(title: "Open file", message: "View HTML page or edit?", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "View HTML", style: .default, handler: { (_) in // View HTML
                        guard let webVC = Bundle.main.loadNibNamed("WebViewController", owner: nil, options: nil)?.first as? WebViewController else { return }
                        webVC.file = file
                        
                        navigationController?.pushViewController(webVC, animated: true)
                    }))
                    
                    alert.addAction(UIAlertAction(title: "Edit HTML", style: .default, handler: { (_) in // View HTML
                        navigationController?.pushViewController(editTextVC, animated: true)
                    }))
                    
                    if viewController == nil {
                        navigationController?.present(alert, animated: true, completion: nil)
                    } else {
                        viewController?.dismiss(animated: true, completion: {
                            navigationController?.present(alert, animated: true, completion: nil)
                        })
                    }
                } else {
                    if viewController == nil {
                        navigationController?.pushViewController(editTextVC!, animated: true)
                    } else {
                        viewController?.dismiss(animated: true, completion: {
                            navigationController?.pushViewController(editTextVC, animated: true)
                        })
                    }
                }
            } else if let unziped = try? Zip.quickUnzipFile(file) {
                let newFolderVC = LocalDirectoryTableViewController(directory: unziped)
                if viewController == nil {
                    navigationController?.pushViewController(newFolderVC, animated: true)
                } else {
                    viewController?.dismiss(animated: true, completion: {
                        navigationController?.pushViewController(newFolderVC, animated: true)
                    })
                }
            } else if let image = UIImage(contentsOfFile: file.path) { // Is image
                let imageVC = Bundle.main.loadNibNamed("ImageViewController", owner: nil, options: nil)!.first! as! ImageViewController
                imageVC.image = image
                
                if viewController == nil {
                    navigationController?.pushViewController(imageVC, animated: true)
                } else {
                    viewController?.dismiss(animated: true, completion: {
                        navigationController?.pushViewController(imageVC, animated: true)
                    })
                }
            } else if AVAsset(url: file).isPlayable { // Is video or audio
                let player = AVPlayer(url: file)
                let playerVC = AVPlayerViewController()
                playerVC.player = player
                
                if viewController == nil {
                    navigationController?.pushViewController(playerVC, animated: true)
                } else {
                    viewController?.dismiss(animated: true, completion: {
                        navigationController?.pushViewController(playerVC, animated: true)
                    })
                }
            } else if isFilePDF(file) { // Is PDF
                let webVC = Bundle.main.loadNibNamed("WebViewController", owner: nil, options: nil)!.first! as! WebViewController
                webVC.file = file
                
                if viewController == nil {
                    navigationController?.pushViewController(webVC, animated: true)
                } else {
                    viewController?.dismiss(animated: true, completion: {
                        navigationController?.pushViewController(webVC, animated: true)
                    })
                }
            } else { // Share
                let shareVC = UIActivityViewController(activityItems: [file], applicationActivities: nil)
                shareVC.popoverPresentationController?.sourceView = view
                viewController?.present(shareVC, animated: true, completion: nil)
            }
        }
        
        let activityVC = ActivityViewController(message: "Loading...")
        if let viewController = viewController {
            viewController.present(activityVC, animated: true, completion: {
                openFile()
            })
        } else {
            openFile()
        }
    }
}


