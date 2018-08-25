// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import UIKit

/// Table view controller displaying content of `commands` array to run them.
class CommandsTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate {
    
    /// Commands to display.
    /// Put `String`s for commands or `Array`s of `String`s.
    ///
    /// # Example of valid value
    ///
    ///     "A command", ["A command", "Title to display"]
    var commands = [Any]()
    
    // MARK: - View controller
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.largeTitleDisplayMode = .never
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "command")
    }
    
    
    // MARK: Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return commands.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "command")!
        
        if let command = commands[indexPath.row] as? String {
            cell.textLabel?.text = command
        }
        
        if let command = commands[indexPath.row] as? [String] {
            cell.textLabel?.text = command[1]
        }
                
        return cell
    }
    
    // MARK: Table view delgate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        dismiss(animated: true) {
            if let command = self.commands[indexPath.row] as? String {
                try? ConnectionManager.shared.session?.channel.write(command)
            } else if let command = self.commands[indexPath.row] as? [String] {
                try? ConnectionManager.shared.session?.channel.write(command[0])
            }
        }
    }
    
    // MARK: Popover presentation controller delegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
