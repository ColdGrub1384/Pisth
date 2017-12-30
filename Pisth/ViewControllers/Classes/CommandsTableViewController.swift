//
//  HistoryTableViewController.swift
//  Pisth
//
//  Created by Adrian on 30.12.17.
//

import UIKit

// This TableViewController displays content of commands array to run them

class CommandsTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
    
    var commands = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        
        tableView.backgroundColor = .black
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "command")
    }
    
    
    // MARK: Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commands.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "command")!
        cell.backgroundColor = .black
        
        cell.textLabel?.text = commands[indexPath.row]
        cell.textLabel?.textColor = .white
        
        return cell
    }
    
    // MARK: Table view delgate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        dismiss(animated: true) {
            try? ConnectionManager.shared.session?.channel.write(self.commands[indexPath.row]+"\n")
        }
    }
    
    // MARK: UIPopoverPresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
