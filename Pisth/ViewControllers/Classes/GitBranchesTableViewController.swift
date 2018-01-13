// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

class GitBranchesTableViewController: UITableViewController {

    var repoPath: String!
    var branches = [String]()
    var current: String?
    
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

    @IBAction func close(_ sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    func launch(command: String, withTitle title: String) {
        let terminalVC = TerminalViewController()
        
        terminalVC.title = title
        terminalVC.command = "clear; "+command+"; echo -e \"\\033[CLOSE\""
        terminalVC.dontScroll = true
        navigationController?.pushViewController(terminalVC, animated: true, completion: {
            terminalVC.navigationItem.setRightBarButtonItems(nil, animated: true)
        })
    }
    
    // MARK: - Git Actions
    
    @IBAction func fetch(_ sender: Any) {
        launch(command: "git -C '\(repoPath!)' fetch", withTitle: "Fetch")
    }
    
    @IBAction func pull(_ sender: Any) {
        launch(command: "git -C '\(repoPath!)' pull", withTitle: "Pull")
    }
    
    @IBAction func commit(_ sender: Any) {
        launch(command: "read -ep \"Commit message: \" msg; git -C '\(repoPath!)' rm -r --cached .; git -C '\(repoPath!)' add .; git -C '\(repoPath!)' commit -m $msg", withTitle: "Commit")
    }
    
    @IBAction func push(_ sender: Any) {
        launch(command: "git -C '\(repoPath!)' push", withTitle: "Push")
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
        launch(command: "git -C '\(repoPath!)' --no-pager log --graph \(branches[indexPath.row])", withTitle: "Commits for \(branches[indexPath.row])")
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
