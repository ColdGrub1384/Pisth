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

    @IBAction func close(_ sender: Any) {
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Git Actions
    
    @IBAction func fetch(_ sender: Any) {
    }
    
    @IBAction func pull(_ sender: Any) {
    }
    
    @IBAction func commit(_ sender: Any) {
    }
    
    @IBAction func push(_ sender: Any) {
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
        guard let terminalVC = Bundle.main.loadNibNamed("TerminalViewController", owner: nil, options: nil)?.first as? TerminalViewController else {
            tableView.deselectRow(at: indexPath, animated: true)
            return
            
        }
        terminalVC.title = "Commits for \(branches[indexPath.row])"
        terminalVC.readOnly = true
        terminalVC.command = "commits '\(repoPath!)' \(branches[indexPath.row])"
        navigationController?.pushViewController(terminalVC, animated: true, completion: {
            terminalVC.navigationItem.setRightBarButtonItems(nil, animated: true)
            tableView.deselectRow(at: indexPath, animated: true)
        })
    }
}
