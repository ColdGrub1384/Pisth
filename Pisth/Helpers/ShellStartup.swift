// This source file is part of the https://github.com/ColdGrub1384/Pisth open source project
//
// Copyright (c) 2017 - 2018 Adrian Labbé
// Licensed under Apache License v2.0
//
// See https://raw.githubusercontent.com/ColdGrub1384/Pisth/master/LICENSE for license information

import Foundation

class ShellStartup {
    
    // Commands to run when open SSH shell
    static let commands = [
                           // Sync history
                           
                           // Avoid duplicates
                           "export HISTCONTROL=ignoredups:erasedups; history -d $(history 1)",
                           
                           // When the shell exits, append to the history file instead of overwriting it
                           "shopt -s histappend; history -d $(history 1)",
                           
                           // After each command, append to the history file and reread it
                           "export PROMPT_COMMAND=\"${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r\"; history -d $(history 1)",
                           
                           // Create .pisth_history symlink of history file
                           "ln -s $HISTFILE .pisth_history > /dev/null 2>&1; history -d $(history 1)",
                           
                           ""
    ]
}
