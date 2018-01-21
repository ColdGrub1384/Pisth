// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

/// Table view controller to display Git branches at `repoPath`.
class GitBranchesTableViewController: UITableViewController {

    /// Remote path of Git repo.
    var repoPath: String!
    
    /// Fetched branches.
    var branches = [String]()
    
    /// Current branch.
    var current: String?
    
    /// Handler called did select branch.
    var selectionHandler: ((GitBranchesTableViewController, IndexPath) -> Void)?
    
    /// Launch command in shell and open terminal.
    ///
    /// - Parameters:
    ///     - command: Command to run.
    ///     - title: Title of opened terminal.
    func launch(command: String, withTitle title: String) {
        let terminalVC = TerminalViewController()
        
        terminalVC.title = title
        terminalVC.command = "clear; "+command+"; echo -e \"\\033[CLOSE\""
        terminalVC.dontScroll = true
        navigationController?.pushViewController(terminalVC, animated: true, completion: {
            terminalVC.navigationItem.setRightBarButtonItems(nil, animated: true)
        })
    }
    
    /// Dismiss `self` or `navigationController`.`
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @objc func done(_ sender: Any) {
        if let navVC = navigationController {
            navVC.dismiss(animated: true, completion: nil)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - View controller
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let result = try? ConnectionManager.shared.filesSession!.channel.execute("git -C '\(repoPath!)' branch").replacingOccurrences(of: " ", with: "") {
            for branch in result.components(separatedBy: "\n") {
                if branch.hasPrefix("*") {
                    current = branch.replacingOccurrences(of: "*", with: "")
                }
                
                if branch != "" {
                    self.branches.append(branch.replacingOccurrences(of: "*", with: ""))
                }
            }
        }
        
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.navigationBar.tintAdjustmentMode = .normal
        navigationController?.navigationBar.tintAdjustmentMode = .automatic
    }
    
    
    // MARK: - Git Actions
    
    /// Git fetch
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func fetch(_ sender: Any) {
        launch(command: "git -C '\(repoPath!)' fetch", withTitle: "Fetch")
    }
    
    /// Git pull
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func pull(_ sender: Any) {
        guard let remotesVC = UIStoryboard(name: "Git", bundle: Bundle.main).instantiateViewController(withIdentifier: "remoteBranches") as? GitRemotesTableViewController else { return }
        remotesVC.repoPath = repoPath
        
        let navVC = UINavigationController(rootViewController: remotesVC)
        navVC.navigationBar.barStyle = .black
        navVC.navigationBar.isTranslucent = true
        
        present(navVC, animated: true) {
            remotesVC.navigationItem.setLeftBarButton(UIBarButtonItem.init(barButtonSystemItem: .done, target: remotesVC, action: #selector(remotesVC.done(_:))), animated: true)
        }
        
        remotesVC.selectionHandler = ({ remotesVC, indexPath in
            remotesVC.dismiss(animated: true, completion: {
                self.launch(command: "git -C '\(self.repoPath!)' pull \(remotesVC.branches[indexPath.row].replacingFirstOccurrence(of: "/", with: " "))", withTitle: "Pull")
            })
        })
    }
    
    /// Git commit
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func commit(_ sender: Any) {
        launch(command: "read -ep \"Commit message: \" msg; git -C '\(repoPath!)' add .; git -C '\(repoPath!)' commit -m \"$msg\"", withTitle: "Commit")
    }
    
    /// Git push.
    ///
    /// - Parameters:
    ///     - sender: Sender object.
    @IBAction func push(_ sender: Any) {
        guard let remotesVC = UIStoryboard(name: "Git", bundle: Bundle.main).instantiateViewController(withIdentifier: "remoteBranches") as? GitRemotesTableViewController else { return }
        remotesVC.repoPath = repoPath
        
        let navVC = UINavigationController(rootViewController: remotesVC)
        navVC.navigationBar.barStyle = .black
        navVC.navigationBar.isTranslucent = true
        
        present(navVC, animated: true) {
            remotesVC.navigationItem.setLeftBarButton(UIBarButtonItem.init(barButtonSystemItem: .done, target: remotesVC, action: #selector(remotesVC.done(_:))), animated: true)
        }
        
        remotesVC.selectionHandler = ({ remotesVC, indexPath in
            remotesVC.dismiss(animated: true, completion: {
                self.launch(command: "git -C '\(self.repoPath!)' push \(remotesVC.branches[indexPath.row].replacingFirstOccurrence(of: "/", with: " "))", withTitle: "Push")
            })
        })
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return branches.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "branch", for: indexPath)

        guard let title = cell.viewWithTag(1) as? UILabel else { return cell }
        guard let isCurrent = cell.viewWithTag(2) as? UILabel else { return cell }
        
        title.text = branches[indexPath.row]
        isCurrent.isHidden = (current != branches[indexPath.row])
        
        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 87
    }
    
    
    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let handler = selectionHandler {
            handler(self, indexPath)
            return
        }
        
        launch(command: "git -C '\(repoPath!)' --no-pager log --graph \(branches[indexPath.row])", withTitle: "Commits for \(branches[indexPath.row])")
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
