//
//  ShellStartup.swift
//  Pisth
//
//  Created by Adrian on 30.12.17.
//

import Foundation

class ShellStartup {
    
    // Commands to run when open SSH shell
    static let commands = [
                           // Print ClEaRtHeScReEnNoW instead of clear shell
                           "alias clear='echo Cl\\EaRtHeScReEnNoW'; history -d $(history 1)",
                           
                           
                           // Sync history
                           
                           // Avoid duplicates
                           "export HISTCONTROL=ignoredups:erasedups; history -d $(history 1)",
                           
                           // When the shell exits, append to the history file instead of overwriting it
                           "shopt -s histappend",
                           
                           // After each command, append to the history file and reread it
                           "export PROMPT_COMMAND=\"${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r\"; history -d $(history 1)",
                           
                           // Create .pisth_history symlink of history file
                           "ln -s $HISTFILE .pisth_history > /dev/null; history -d $(history 1)",
                           
                           ""
    ]
}
